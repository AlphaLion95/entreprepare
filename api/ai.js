export default async function handler(req, res) {
  const aiDebug = process.env.AI_DEBUG === '1';
  const allowDevHeader = process.env.ALLOW_DEV_HEADER === '1';
  const vercelEnv = process.env.VERCEL_ENV || 'unknown';
  const rateLimit = parseInt(process.env.RATE_LIMIT_PER_MIN || '0', 10);

  // Basic CORS support (can be tightened via ALLOWED_ORIGINS env)
  const allowedOrigins = (process.env.ALLOWED_ORIGINS || '*').split(',').map(s=>s.trim());
  const origin = req.headers.origin || '';
  const allowOriginHeader = allowedOrigins.includes('*') || allowedOrigins.includes(origin) ? origin || '*' : allowedOrigins[0] || '*';
  res.setHeader('Access-Control-Allow-Origin', allowOriginHeader);
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Groq-Key');
  res.setHeader('Cache-Control', 'no-store');
  if (req.method === 'OPTIONS') return res.status(204).end();

  if (req.method !== 'POST') {
    const configuredModel = process.env.GROQ_MODEL || null;
    const modelCandidates = [
      configuredModel,
      'llama-3.1-70b-versatile',
      'llama-3.1-8b-instant',
      'mixtral-8x7b-32768'
    ].filter(Boolean);
    return res.status(200).json({
      message: 'Groq AI endpoint ready. POST JSON to use.',
      version: 4,
      codeVersion: 'fallback-v2',
      configured: !!process.env.GROQ_API_KEY,
      configuredModel,
      modelCandidates,
      planSupported: true
    });
  }

  // Simple in-memory per-IP rate limiting (best-effort, not distributed)
  if (rateLimit > 0) {
    const ip = (req.headers['x-forwarded-for'] || '').toString().split(',')[0].trim() || req.socket.remoteAddress || 'unknown';
    const now = Date.now();
    pruneRateBuckets(now);
    const count = incrementRate(ip, now);
    if (count > rateLimit) {
      return res.status(429).json({ error: 'rate_limited', limit: rateLimit, ip });
    }
  }

  // Optional shared secret (defense-in-depth). If APP_SHARED_SECRET is set, require matching header X-App-Secret.
  const requiredSecret = process.env.APP_SHARED_SECRET;
  if (requiredSecret) {
    const provided = req.headers['x-app-secret'];
    if (!provided || provided !== requiredSecret) {
      return res.status(401).json({ error: 'unauthorized', reason: 'invalid_app_secret' });
    }
  }

  // Resolve Groq API key
  let apiKey = process.env.GROQ_API_KEY;
  const headerKey = req.headers['x-groq-key'];
  if (!apiKey && allowDevHeader && vercelEnv !== 'production' && headerKey) apiKey = String(headerKey);
  if (!apiKey) {
    return res.status(500).json({
      error: 'missing_server_key',
      hint: 'Set GROQ_API_KEY in Vercel Project > Settings > Environment Variables (Production). Redeploy after adding.',
      haveKeys: Object.keys(process.env).filter(k => k.includes('GROQ')).sort(),
      vercelEnv
    });
  }

  const body = req.body || {};
  const { type, query, activity, problem, goal, title, limit, context, suggestion } = body;
  const requestReceivedAt = Date.now();
  if (aiDebug) {
    try {
      console.log('[ai-endpoint] incoming type:', type, 'keys:', Object.keys(body));
    } catch(_) {}
  }
  if (!type) {
    return res.status(400).json({ error: 'missing_type', hint: 'Provide type one of: ideas | solutions | milestone | plan | plan_financials' });
  }
  const detected = type;

  try {
  // Preferred / multi-fallback model logic
  const configuredModel = process.env.GROQ_MODEL;
  const fallbackModels = [
    configuredModel,
    'llama-3.1-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768'
  ].filter(Boolean);
  let model;
  let content;
  let lastErr;
  let schemaKind; // hoisted so it is available after loop
  const modelChainTried = [];
  let modelCallMs = 0;
  for (const candidate of fallbackModels) {
    model = candidate;
    try {
      const built = buildPrompt({ detected, query, activity, problem, goal, title, limit, context, suggestion }, res);
      const prompt = built.prompt;
      schemaKind = built.schemaKind;
      if (!prompt) return; // early error already responded (e.g. validation response already sent)
      const messages = [
        { role: 'system', content: 'You are a JSON API. Output ONLY strict JSON. No markdown, no commentary, no backticks.' },
        { role: 'user', content: prompt }
      ];
      const t0 = Date.now();
  const callResult = await callGroqWithRetry({ apiKey, model, messages, aiDebug });
  content = callResult.content;
  var lastUsage = callResult.usage || null;
      modelCallMs = Date.now() - t0;
      modelChainTried.push(candidate);
      // If we got here, break out (success)
      break;
    } catch (err) {
      const msg = String(err.message || '');
      lastErr = msg;
      if (aiDebug) console.warn('[model-error]', candidate, msg);
      if (/model_decommissioned|no longer supported|model_not_found/i.test(msg)) {
        // continue to next candidate silently
        modelChainTried.push(candidate);
        continue;
      }
      modelChainTried.push(candidate);
      // Non-decommission error: stop trying further models
      break;
    }
  }
  if (!content) {
    return res.status(502).json({ error: 'model_unavailable', tried: fallbackModels, lastErr: truncate(String(lastErr||''), 300) });
  }
  if (!schemaKind) {
    return res.status(500).json({ error: 'internal_no_schemaKind', hint: 'Failed to establish schemaKind after model loop.' });
  }
    let parsed = enhancedParse(content, aiDebug);
    let repaired = false; // indicates at least one repair attempt occurred
    let repair1Ms = 0;
    let repair2Ms = 0;
    if (aiDebug) {
      try {
        console.log('[ai-debug] pre-branch', JSON.stringify({ schemaKind, model, rawLen: (content||'').length, parsed: !!parsed }));
      } catch(_) {}
    }

    // Auto repair attempt if parse fails or shape invalid
    const attemptRepair = async (reason) => {
      if (repaired) return false; // only once for generic path
      repaired = true;
      const repairInstruction = buildRepairInstruction(schemaKind, reason, content);
      if (!repairInstruction) return false;
      if (aiDebug) console.warn('[repair-attempt]', reason);
      const repairMessages = [
        { role: 'system', content: 'You are a JSON API. Output ONLY strict JSON. No markdown, no commentary, no backticks.' },
        { role: 'user', content: repairInstruction }
      ];
      const tR0 = Date.now();
  const repairCall = await callGroqWithRetry({ apiKey, model, messages: repairMessages, aiDebug });
  content = repairCall.content;
  var lastRepairUsage = repairCall.usage || null;
      repair1Ms = Date.now() - tR0;
      parsed = enhancedParse(content, aiDebug);
      return !!parsed;
    };

    if (!parsed) {
      const ok = await attemptRepair('initial_parse_failed');
      if (!ok) {
        // For ideas we guarantee a fallback response instead of hard error
        if (schemaKind === 'ideas') {
          const safeLimit = sanitizeLimit(limit);
          const ideas = heuristicIdeasFallback(query, safeLimit, true);
          const modelAttempt = modelChainTried.indexOf(model) + 1 || 1;
            return res.json({
              version: 3,
              modelUsed: model,
              modelAttempt,
              repaired: false,
              fallbackUsed: true,
              ideas
            });
        }
        return res.status(502).json({ error: 'parse_failed', raw: truncate(content, 500) });
      }
    }

    // Shape enforcement with possible repair
    if (schemaKind === 'ideas') {
      const safeLimit = sanitizeLimit(limit);
      let ideas = normalizeIdeas(parsed, safeLimit);
      let fallbackUsed = false;
      if (!ideas.length) {
        const ok = await attemptRepair('empty_ideas_list');
        if (!ok) {
          ideas = heuristicIdeasFallback(query, safeLimit, true);
          fallbackUsed = true;
        } else {
          ideas = normalizeIdeas(parsed, safeLimit);
          // SECOND repair attempt (ideas only) if still empty
          if (!ideas.length) {
            // manual second repair ignoring single-attempt guard
            const repairInstruction2 = buildRepairInstruction(schemaKind, 'empty_ideas_list_second', content);
            if (repairInstruction2) {
              if (aiDebug) console.warn('[repair-attempt-2]', 'empty_ideas_list_second');
              const repairMessages2 = [
                { role: 'system', content: 'You are a JSON API. Output ONLY strict JSON. No markdown, no commentary, no backticks.' },
                { role: 'user', content: repairInstruction2 }
              ];
              const tR20 = Date.now();
              try {
                const repairedCall2 = await callGroqWithRetry({ apiKey, model, messages: repairMessages2, aiDebug });
                const repairedContent2 = repairedCall2.content;
                var lastRepair2Usage = repairedCall2.usage || null;
                repair2Ms = Date.now() - tR20;
                // Replace only if parseable
                const parsed2 = enhancedParse(repairedContent2, aiDebug);
                if (parsed2 && Array.isArray(parsed2.ideas) && parsed2.ideas.length) {
                  content = repairedContent2;
                  parsed = parsed2;
                  ideas = normalizeIdeas(parsed2, safeLimit);
                }
              } catch (_) {
                repair2Ms = Date.now() - tR20;
              }
            }
            if (!ideas.length) { ideas = heuristicIdeasFallback(query, safeLimit, true); fallbackUsed = true; }
          }
        }
      }
      // Final hard guard: never return empty array
      if (!ideas.length) {
        ideas = heuristicIdeasFallback(query, safeLimit, true);
        fallbackUsed = true;
      }
      if (aiDebug) { try { console.log('[ai-debug] ideas-result', { count: ideas.length, repaired, fallbackUsed, modelCallMs, repair1Ms, repair2Ms }); } catch(_) {} }
      const modelAttempt = modelChainTried.indexOf(model) + 1 || 1;
      // Create stable IDs (sha-like hash) for each idea
      const ideasDetailed = ideas.map(text => ({ id: hashId(text), text }));
      const codeVersion = process.env.VERCEL_GIT_COMMIT_SHA || process.env.CODE_VERSION || 'unknown';
      const requestMeta = { type: detected, limit: safeLimit, queryLen: (query||'').length, receivedAt: requestReceivedAt };
      const attempts = { modelCallMs, repair1Ms, repair2Ms, repaired, modelAttempt };
      const usage = lastUsage || lastRepairUsage || lastRepair2Usage || null;
      const resp = { version: 3, codeVersion, modelUsed: model, modelAttempt, repaired, fallbackUsed, ideas, ideasDetailed, requestMeta };
      if (aiDebug) {
        resp.debug = {
          modelChainTried,
            modelCallMs,
            repair1Ms,
            repair2Ms,
            responseChars: (content||'').length,
            usage,
            attempts
        };
      }
      return res.json(resp);
    }
    if (schemaKind === 'solutions') {
      let sols = normalizeSolutions(parsed);
      if (!sols.length) {
        const ok = await attemptRepair('empty_solutions_list');
        if (!ok) return res.status(502).json({ error: 'empty_solutions', raw: truncate(JSON.stringify(parsed), 600) });
        sols = normalizeSolutions(parsed);
        if (!sols.length) return res.status(502).json({ error: 'empty_solutions_after_repair' });
      }
      if (aiDebug) { try { console.log('[ai-debug] solutions-result', { count: sols.length, repaired, modelCallMs, repair1Ms }); } catch(_) {} }
      const modelAttempt = modelChainTried.indexOf(model) + 1 || 1;
      const codeVersion = process.env.VERCEL_GIT_COMMIT_SHA || process.env.CODE_VERSION || 'unknown';
      const requestMeta = { type: detected, limit: parseInt(limit||3,10), activityLen: (activity||'').length, problemLen: (problem||'').length, receivedAt: requestReceivedAt };
      const attempts = { modelCallMs, repair1Ms, repaired, modelAttempt };
      const usage = lastUsage || lastRepairUsage || null;
      const resp = { version: 2, codeVersion, modelUsed: model, modelAttempt, repaired, solutions: sols, requestMeta };
      if (aiDebug) {
        resp.debug = { modelChainTried, modelCallMs, repair1Ms, responseChars: (content||'').length, usage, attempts };
      }
      return res.json(resp);
    }
    if (schemaKind === 'milestone') {
      let ms = normalizeMilestone(parsed);
      if (!ms.definition || !ms.steps.length) {
        const ok = await attemptRepair('invalid_milestone_shape');
        if (!ok) return res.status(502).json({ error: 'invalid_milestone', raw: truncate(JSON.stringify(parsed), 600) });
        ms = normalizeMilestone(parsed);
        if (!ms.definition || !ms.steps.length) return res.status(502).json({ error: 'invalid_milestone_after_repair' });
      }
      if (aiDebug) { try { console.log('[ai-debug] milestone-result', { steps: (ms.steps||[]).length, repaired, modelCallMs, repair1Ms }); } catch(_) {} }
      const modelAttempt = modelChainTried.indexOf(model) + 1 || 1;
      const codeVersion = process.env.VERCEL_GIT_COMMIT_SHA || process.env.CODE_VERSION || 'unknown';
      const requestMeta = { type: detected, titleLen: (title||'').length, receivedAt: requestReceivedAt };
      const attempts = { modelCallMs, repair1Ms, repaired, modelAttempt };
      const usage = lastUsage || lastRepairUsage || null;
      const resp = { version: 2, codeVersion, modelUsed: model, modelAttempt, repaired, ...ms, requestMeta };
      if (aiDebug) {
        resp.debug = { modelChainTried, modelCallMs, repair1Ms, responseChars: (content||'').length, usage, attempts };
      }
      return res.json(resp);
    }
    if (schemaKind === 'plan' || schemaKind === 'plan_financials') {
      let planObj = normalizePlan(parsed);
      if (!planObj || !planObj.title) {
        const ok = await attemptRepair('invalid_plan_shape');
        if (!ok) return res.status(502).json({ error: 'invalid_plan', raw: truncate(JSON.stringify(parsed), 700) });
        planObj = normalizePlan(parsed);
        if (!planObj || !planObj.title) return res.status(502).json({ error: 'invalid_plan_after_repair' });
      }
      const derived = addPlanDerived(planObj); // includes warnings & projections
      const modelAttempt = modelChainTried.indexOf(model) + 1 || 1;
      const codeVersion = process.env.VERCEL_GIT_COMMIT_SHA || process.env.CODE_VERSION || 'unknown';
      const requestMeta = { type: detected, contextLen: (context||'').length, suggestionLen: (suggestion||'').length, receivedAt: requestReceivedAt };
      const attempts = { modelCallMs, repair1Ms, repaired, modelAttempt };
      const usage = lastUsage || lastRepairUsage || null;
      const baseResp = { version: 4, codeVersion, modelUsed: model, modelAttempt, repaired, planVersion: derived.planVersion || 1, plan: derived, requestMeta };
      if (aiDebug) {
        baseResp.debug = { modelChainTried, modelCallMs, repair1Ms, responseChars: (content||'').length, usage, attempts };
      }
      if (schemaKind === 'plan_financials') {
        // Only return financial slices + warnings to merge client-side
        if (aiDebug) { try { console.log('[ai-debug] plan-financials-result', { warnings: (derived.validationWarnings||[]).length }); } catch(_) {} }
        return res.json({
          ...baseResp,
          plan: {
            pricing: derived.pricing,
            sales: derived.sales,
            expenses: derived.expenses,
            inventory: derived.inventory,
            metrics: derived.metrics,
            projectedRevenueMonths: derived.projectedRevenueMonths,
            grossProfitMonths: derived.grossProfitMonths,
            netProfitMonths: derived.netProfitMonths,
            cumulativeNetProfitMonths: derived.cumulativeNetProfitMonths,
            computedBreakevenMonth: derived.computedBreakevenMonth,
            validationWarnings: derived.validationWarnings || []
          }
        });
      }
      if (aiDebug) { try { console.log('[ai-debug] plan-result', { title: derived.title, warnings: (derived.validationWarnings||[]).length }); } catch(_) {} }
      return res.json(baseResp);
    }
    return res.status(500).json({ error: 'unexpected_branch' });
  } catch (e) {
    return res.status(500).json({ error: 'proxy_error', detail: e.message });
  }
}

function buildPrompt({ detected, query, activity, problem, goal, title, limit, context, suggestion }, res) {
  let prompt = '';
  let schemaKind = detected;
  if (detected === 'ideas') {
    if (!query) { res.status(400).json({ error: 'missing_query' }); return {}; }
    const n = Math.min(parseInt(limit || 8, 10), 12);
    // Lightweight normalization to reduce model confusion on pluralization / grammar
    let nq = String(query).trim();
    nq = nq.replace(/\bfoods\b/gi, 'food');
    // If singular 'product' appears and 'products' does not, pluralize for diversity
    if (/\bproduct\b/i.test(nq) && !/\bproducts\b/i.test(nq)) {
      nq = nq.replace(/\bproduct\b/gi, 'products');
    }
    // Strengthen instruction: EXACTLY N distinct ideas, forbid numbering/commentary
    prompt = `Generate EXACTLY ${n} distinct concise (5-12 words) actionable startup or small business ideas about: ${nq}. Output STRICT JSON ONLY: {"ideas":["idea 1","idea 2", "idea 3"]}. No numbering, no commentary, no markdown. Ideas must be unique and specific.`;
  } else if (detected === 'solutions') {
    if (!activity || !problem) { res.status(400).json({ error: 'missing_fields' }); return {}; }
    const n = Math.min(parseInt(limit || 3, 10), 5);
    prompt = `Activity: ${activity}\nProblem: ${problem}\nGoal: ${goal || ''}\nGenerate ${n} solution objects. Strict JSON ONLY: {"solutions":[{"title":"","rationale":"","steps":["step1","step2"]}]}. Title <=6 words; rationale EXACTLY 1 sentence; each solution has 4-6 concrete imperative steps.`;
  } else if (detected === 'milestone') {
    if (!title) { res.status(400).json({ error: 'missing_title' }); return {}; }
    prompt = `Milestone: ${title}\nReturn strict JSON: {"definition":"","steps":["step1","step2"]}. Definition <=22 words; include exactly 5 specific steps.`;
  } else if (detected === 'plan') {
    if (!context && !suggestion) { res.status(400).json({ error: 'missing_context' }); return {}; }
    // We accept either a raw context paragraph(s) or a selected suggestion (strategy) to build a financial + execution plan.
    const base = (context || '') + '\nSuggestion:' + (suggestion || '');
    /* Plan JSON schema goal:
      {
        "title":"",
        "summary":"one sentence overview",
        "pricing": {"pricePerUnit":0, "capitalRequired":0},
        "sales": {"estMonthlyUnits":0, "assumptions":[""], "growthPctMonth":0},
        "inventory": [{"name":"","qty":0,"unitCost":0}],
        "expenses": [{"name":"","monthlyCost":0}],
        "milestones": [""],
        "innovations": [""],
        "metrics": {"grossMarginPct":0, "operatingMarginPct":0, "breakevenMonths":0}
      }
    */
    prompt = `Context and strategy:\n${base}\nGenerate a pragmatic early-stage 6-month business plan. Output STRICT JSON ONLY with keys: title, summary, pricing{pricePerUnit,capitalRequired}, sales{estMonthlyUnits,assumptions,growthPctMonth}, inventory[{name,qty,unitCost}], expenses[{name,monthlyCost}], milestones[], innovations[], metrics{grossMarginPct,operatingMarginPct,breakevenMonths}. Constraints: 4-6 inventory items, 5-7 expenses, 5-8 milestones (short imperative), 3-6 innovations (distinctive ideas). pricePerUnit >0. Unit costs realistic. Percent values numeric (no % sign). Assume small lean startup. Avoid nulls.`;
  } else if (detected === 'plan_financials') {
    if (!context) { res.status(400).json({ error: 'missing_context' }); return {}; }
    // context should include existing plan JSON or summary so model can preserve narrative aspects
    const base = context || '';
    /* We ask model to refresh ONLY financial drivers but still output full schema so normalization works. */
    prompt = `Existing plan context (do NOT radically change narrative):\n${base}\nRefresh ONLY financial assumptions (pricing, sales.estMonthlyUnits, sales.growthPctMonth, inventory costs, expenses, metrics percentages & breakeven). Keep title, summary, milestones, innovations largely stable unless numbers force small adjustment. Output STRICT JSON ONLY with full plan schema: {"title":"","summary":"","pricing":{"pricePerUnit":0,"capitalRequired":0},"sales":{"estMonthlyUnits":0,"assumptions":[""],"growthPctMonth":0},"inventory":[{"name":"","qty":0,"unitCost":0}],"expenses":[{"name":"","monthlyCost":0}],"milestones":[""],"innovations":[""],"metrics":{"grossMarginPct":0,"operatingMarginPct":0,"breakevenMonths":0}}. Rules: pricePerUnit>0; all costs >=0; growthPctMonth typical 0-500 (absolute hard max 10000). No extra keys. No commentary.`;
  } else {
    // Enhanced diagnostics for easier client debugging
    res.status(400).json({
      error: 'unsupported_type',
      received_type: detected,
      allowed_types: ['ideas','solutions','milestone','plan','plan_financials'],
      hint: 'Deploy latest backend ensuring plan & plan_financials branches exist.'
    });
    return {};
  }
  return { prompt, schemaKind };
}

async function callGroqWithRetry({ apiKey, model, messages, aiDebug, maxAttempts = 3 }) {
  let attempt = 0;
  let lastErrText = '';
  while (attempt < maxAttempts) {
    attempt++;
    const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model, temperature: 0.65, messages })
    });
    if (resp.ok) {
      const data = await resp.json();
      const content = data.choices?.[0]?.message?.content || '{}';
      const usage = data.usage || null; // expect {prompt_tokens, completion_tokens, total_tokens}
      if (aiDebug) console.log('[groq-content]', truncate(content, 200));
      return { content, usage, raw: data };
    }
    const status = resp.status;
    const text = await resp.text();
    lastErrText = `status=${status} body=${truncate(text,300)}`;
    if (aiDebug) console.warn('[groq-retry]', attempt, lastErrText);
    if (![429, 500, 502, 503, 504].includes(status)) break; // non-retryable
    await delay(Math.min(200 * Math.pow(2, attempt-1), 1200));
  }
  throw new Error('groq_failed: ' + lastErrText);
}

function enhancedParse(raw, aiDebug) {
  if (!raw) return null;
  let text = raw.trim();
  // Strip code fences if any
  text = text.replace(/```(json)?/gi, '').replace(/```/g, '').trim();
  let parsed = safeParse(text);
  if (parsed) return parsed;
  // Attempt salvage: find first { ... last }
  const first = text.indexOf('{');
  const last = text.lastIndexOf('}');
  if (first >= 0 && last > first) {
    parsed = safeParse(text.slice(first, last + 1));
    if (parsed) return parsed;
  }
  if (aiDebug) console.warn('[parse-fail]', truncate(text, 300));
  return null;
}

function buildRepairInstruction(schemaKind, reason, previousRaw) {
  const baseNote = `Previous output was invalid (${reason}). Return ONLY valid JSON for the required schema.`;
  if (schemaKind === 'ideas') {
    return `${baseNote} Schema: {"ideas":["idea 1","idea 2"]}. 6-12 concise actionable business ideas. No numbering, no extra keys.`;
  }
  if (schemaKind === 'solutions') {
    return `${baseNote} Schema: {"solutions":[{"title":"","rationale":"","steps":["step1","step2"]}]}. Provide 3 solutions unless limit specified earlier. Title <=6 words; rationale EXACTLY 1 sentence; each has 4-6 imperative steps.`;
  }
  if (schemaKind === 'milestone') {
    return `${baseNote} Schema: {"definition":"","steps":["step1","step2"]}. Provide definition <=22 words and exactly 5 concrete actionable steps.`;
  }
  if (schemaKind === 'plan' || schemaKind === 'plan_financials') {
    return `${baseNote} Schema: {"title":"","summary":"","pricing":{"pricePerUnit":0,"capitalRequired":0},"sales":{"estMonthlyUnits":0,"assumptions":[""],"growthPctMonth":0},"inventory":[{"name":"","qty":0,"unitCost":0}],"expenses":[{"name":"","monthlyCost":0}],"milestones":[""],"innovations":[""],"metrics":{"grossMarginPct":0,"operatingMarginPct":0,"breakevenMonths":0}}. Follow all numeric constraints. No extra keys.`;
  }
  return '';
}

function delay(ms) { return new Promise(r => setTimeout(r, ms)); }
function truncate(str, n) { if (!str) return ''; return str.length > n ? str.slice(0, n) + '…' : str; }

function safeParse(text) {
  try { return JSON.parse(text); } catch (_) {
    const idx = text.indexOf('{');
    if (idx >= 0) {
      try { return JSON.parse(text.slice(idx)); } catch (_) { return null; }
    }
    return null;
  }
}

function normalizeIdeas(obj, limitRaw) {
  const limit = sanitizeLimit(limitRaw);
  let ideas = Array.isArray(obj.ideas) ? obj.ideas : [];
  if (!ideas.length) return [];
  return ideas.map(i => String(i).trim()).filter(Boolean).slice(0, limit);
}

function normalizeSolutions(obj) {
  const sols = Array.isArray(obj.solutions) ? obj.solutions : [];
  return sols.map(s => ({
    title: String(s.title || '').trim(),
    rationale: String(s.rationale || '').trim(),
    steps: Array.isArray(s.steps) ? s.steps.map(x => String(x).trim()).filter(Boolean).slice(0, 8) : []
  })).filter(s => s.title && s.steps.length);
}

function normalizeMilestone(obj) {
  return {
    definition: String(obj.definition || '').trim(),
    steps: Array.isArray(obj.steps) ? obj.steps.map(x=>String(x).trim()).filter(Boolean).slice(0,7) : []
  };
}

function normalizePlan(obj) {
  if (!obj || typeof obj !== 'object') return null;
  const num = v => {
    const n = Number(v); return isFinite(n) ? n : 0;
  };
  const arrStrings = (a, max) => Array.isArray(a) ? a.map(x=>String(x||'').trim()).filter(Boolean).slice(0,max) : [];
  const items = (a, max) => Array.isArray(a) ? a.map(x=>({
    name: String(x.name||'').trim(),
    qty: parseInt(x.qty||0,10),
    unitCost: num(x.unitCost)
  })).filter(i=>i.name && i.qty>0).slice(0,max) : [];
  const expenses = (a, max) => Array.isArray(a) ? a.map(x=>({
    name: String(x.name||'').trim(),
    monthlyCost: num(x.monthlyCost)
  })).filter(e=>e.name && e.monthlyCost>=0).slice(0,max) : [];
  const pricing = obj.pricing || {};
  const sales = obj.sales || {};
  const metrics = obj.metrics || {};
  return {
    title: String(obj.title||'').trim().slice(0,120),
    summary: String(obj.summary||'').trim().slice(0,240),
    pricing: {
      pricePerUnit: num(pricing.pricePerUnit),
      capitalRequired: num(pricing.capitalRequired)
    },
    sales: {
      estMonthlyUnits: parseInt(sales.estMonthlyUnits||0,10),
      assumptions: arrStrings(sales.assumptions,6),
      growthPctMonth: num(sales.growthPctMonth)
    },
    inventory: items(obj.inventory,6),
    expenses: expenses(obj.expenses,8),
    milestones: arrStrings(obj.milestones,8),
    innovations: arrStrings(obj.innovations,6),
    metrics: {
      grossMarginPct: num(metrics.grossMarginPct),
      operatingMarginPct: num(metrics.operatingMarginPct),
      breakevenMonths: num(metrics.breakevenMonths)
    }
  };
}

// Add derived projection + version flag. Mirrors client logic but centralized.
function addPlanDerived(plan) {
  try {
    const warnings = [];
    const price = Number(plan?.pricing?.pricePerUnit || 0);
    if (price <= 0) warnings.push('price_per_unit_non_positive');
    const estUnits = Number(plan?.sales?.estMonthlyUnits || 0);
    const growthPct = Number(plan?.sales?.growthPctMonth || 0);
    if (growthPct > 10000) warnings.push('growth_pct_implausible');
    const growth = Math.max(0, Math.min(growthPct, 300));
    const inventory = Array.isArray(plan.inventory) ? plan.inventory : [];
    const expenses = Array.isArray(plan.expenses) ? plan.expenses : [];
    const avgUnitCost = inventory.length
      ? inventory.reduce((s,i)=> {
          const uc = Number(i.unitCost)||0; if (uc < 0) warnings.push('negative_inventory_unit_cost'); return s + uc; },0) / inventory.length
      : 0;
    let monthlyFixed = 0;
    for (const e of expenses) {
      const mc = Number(e.monthlyCost)||0; if (mc < 0) warnings.push('negative_expense_monthly_cost'); monthlyFixed += mc; }
    if (plan?.pricing?.capitalRequired != null && Number(plan.pricing.capitalRequired) < 0) warnings.push('capital_required_negative');
    const revenueMonths = [];
    const grossProfitMonths = [];
    const netProfitMonths = [];
    const cumulativeNetProfitMonths = [];
    let units = estUnits;
    let cumulative = 0;
    let breakevenIdx = -1;
    for (let i = 0; i < 6; i++) {
      const revenue = +(units * price).toFixed(2);
      const cogs = +(units * avgUnitCost).toFixed(2);
      const gross = +(revenue - cogs).toFixed(2);
      const net = +(gross - monthlyFixed).toFixed(2);
      cumulative = +(cumulative + net).toFixed(2);
      revenueMonths.push(revenue);
      grossProfitMonths.push(gross);
      netProfitMonths.push(net);
      cumulativeNetProfitMonths.push(cumulative);
      if (breakevenIdx === -1 && cumulative >= 0) breakevenIdx = i; // zero-based
      units = units * (1 + growth / 100);
    }
    const computedBreakevenMonth = breakevenIdx >= 0 ? (breakevenIdx + 1) : null;
    return {
      ...plan,
      planVersion: 4,
      projectedRevenueMonths: revenueMonths,
      grossProfitMonths,
      netProfitMonths,
      cumulativeNetProfitMonths,
      computedBreakevenMonth,
      validationWarnings: warnings
    };
  } catch (_) {
    return { ...plan, planVersion: 4, projectedRevenueMonths: [], grossProfitMonths: [], netProfitMonths: [], cumulativeNetProfitMonths: [], computedBreakevenMonth: null, validationWarnings: ['derivation_error'] };
  }
}

// In-memory rate limiting (non-distributed). Window = 60s.
const __rateState = { buckets: new Map() }; // ip -> { windowStart, count }
function pruneRateBuckets(now) {
  for (const [ip, rec] of __rateState.buckets.entries()) {
    if (now - rec.windowStart > 60_000) __rateState.buckets.delete(ip);
  }
}
function incrementRate(ip, now) {
  let rec = __rateState.buckets.get(ip);
  if (!rec || now - rec.windowStart > 60_000) {
    rec = { windowStart: now, count: 0 };
    __rateState.buckets.set(ip, rec);
  }
  rec.count += 1;
  return rec.count;
}

// Heuristic fallback generator when model fails to return ideas
function heuristicIdeasFallback(query, limitRaw) {
  const base = (String(query||'').trim() || 'business').toLowerCase();
  const limit = sanitizeLimit(limitRaw);
  const hasCheap = /(cheap|low cost|budget)/.test(base);
  const hasFood = /food/.test(base);
  const hasProduct = /product/.test(base);
  const seeds = [
    'Subscription kit',
    'Mobile app service',
    'On-demand support',
    'Digital template shop',
    'Local delivery network',
    'Community micro-learning',
    'Pop-up experience booth',
    'Data insight dashboard',
    'Eco-friendly packaging',
    'AI assisted workflow'
  ];
  const uniq = new Set();
  for (const s of seeds) {
    if (uniq.size >= limit) break;
    uniq.add(capitalize(composeIdea(base, s, { hasCheap, hasFood, hasProduct })));
  }
  let arr = Array.from(uniq);
  if (!arr.length) arr = ['Simple local service startup'];
  return arr.slice(0, limit || 8);
}

function composeIdea(base, seed, flags) {
  if (!base) return seed;
  const parts = [];
  if (flags?.hasCheap) parts.push('Low-cost');
  if (flags?.hasFood) parts.push('Food Stall');
  if (flags?.hasProduct) parts.push('Product');
  // Avoid repeating words already in seed
  const seedLower = seed.toLowerCase();
  const filtered = parts.filter(p => !seedLower.includes(p.toLowerCase()));
  filtered.push(seed);
  return filtered.join(' ');
}

function capitalize(str) { return str ? str.charAt(0).toUpperCase() + str.slice(1) : str; }

// Ensure limit is a positive integer within max, else default
function sanitizeLimit(raw, def = 8, max = 12) {
  let n = parseInt(raw, 10);
  if (!isFinite(n) || n <= 0) n = def;
  if (n > max) n = max;
  return n;
}

// Simple stable hash for idea text -> short id (not cryptographic)
function hashId(text) {
  const str = String(text||'');
  let h = 0;
  for (let i = 0; i < str.length; i++) {
    h = Math.imul(31, h) + str.charCodeAt(i) | 0;
  }
  // Convert to unsigned and base36 shorten
  return 'i_' + (h >>> 0).toString(36);
}
