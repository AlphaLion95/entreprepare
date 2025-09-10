export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response('POST only', { status: 405 });
    }
    let body;
    try { body = await request.json(); } catch { return new Response(JSON.stringify({ error: 'invalid_json'}), { status: 400 }); }

    const type = body.type || 'ideas';
    try {
      switch (type) {
        case 'ideas':
          return await handleIdeas(env, body);
        case 'solutions':
          return await handleSolutions(env, body);
        case 'milestone':
          return await handleMilestone(env, body);
        default:
          return json({ error: 'unknown_type'} , 400);
      }
    } catch (e) {
      return json({ error: 'ai_error', detail: e.message }, 500);
    }
  }
};

function json(obj, status=200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }
  });
}

async function runModel(env, prompt) {
  // Workers AI binding: env.AI (enable in dashboard)
  const model = '@cf/meta/llama-3-8b-instruct';
  const messages = [
    { role: 'system', content: 'You output ONLY valid JSON. No prose, no markdown.' },
    { role: 'user', content: prompt }
  ];
  const response = await env.AI.run(model, { messages });
  let raw = (response.response || '').trim();
  // Attempt to extract JSON if model adds text
  const firstBrace = raw.indexOf('{');
  if (firstBrace > 0) raw = raw.slice(firstBrace);
  // Basic sanitation
  try { return JSON.parse(raw); } catch { return { _raw: raw }; }
}

async function handleIdeas(env, body) {
  const query = (body.query || '').toString().trim();
  const limit = Math.min(parseInt(body.limit || 8, 10), 12);
  if (!query) return json({ error: 'missing_query' }, 400);
  const prompt = `Generate up to ${limit} concise actionable startup or small business ideas about: "${query}". Return JSON {"ideas":["idea1","idea2"]} with 5-12 word ideas.`;
  const data = await runModel(env, prompt);
  let ideas = Array.isArray(data.ideas) ? data.ideas.map(String) : [];
  if (!ideas.length && data._raw) {
    ideas = data._raw.split(/\n|;|\. /).map(s=>s.replace(/^[-*\d\.\s]+/,'').trim()).filter(Boolean).slice(0, limit);
  }
  return json({ ideas: ideas.slice(0, limit) });
}

async function handleSolutions(env, body) {
  const activity = (body.activity||'').toString().trim();
  const problem = (body.problem||'').toString().trim();
  const goal = (body.goal||'').toString().trim();
  const limit = Math.min(parseInt(body.limit || 3,10),5);
  if (!activity || !problem) return json({ error: 'missing_fields' }, 400);
  const prompt = `Activity: ${activity}\nProblem: ${problem}\nGoal: ${goal}\nGenerate ${limit} strategic solution objects JSON {"solutions":[{"title":"","rationale":"","steps":["","""]}]} each title <=6 words, 1-sentence rationale, 4-6 concrete steps.`;
  const data = await runModel(env, prompt);
  let solutions = Array.isArray(data.solutions) ? data.solutions : [];
  if (!solutions.length && data._raw) {
    solutions = fallbackParseSolutions(data._raw).slice(0, limit);
  }
  // Normalize
  solutions = solutions.map(s => ({
    title: String(s.title||'').trim(),
    rationale: String(s.rationale||'').trim(),
    steps: Array.isArray(s.steps)? s.steps.map(x=>String(x).trim()).filter(Boolean).slice(0,8):[]
  })).filter(s=>s.title && s.steps.length);
  return json({ solutions: solutions.slice(0, limit) });
}

function fallbackParseSolutions(raw) {
  const blocks = raw.split(/\n\n+/).slice(0,5);
  return blocks.map(b=>{
    const lines = b.split(/\n/).filter(Boolean);
    const title = lines.shift()||'';
    const steps = lines.filter(l=>l.trim().length>4).slice(0,6);
    return { title: title.replace(/^[-*\d\.\s]+/,'').trim(), rationale: '', steps };
  }).filter(x=>x.title && x.steps.length>2);
}

async function handleMilestone(env, body) {
  const title = (body.title||'').toString().trim();
  if (!title) return json({ error: 'missing_title' }, 400);
  const prompt = `Milestone: ${title}\nReturn JSON {"definition":"","steps":["step1","step2"]} definition <=22 words, 5 specific execution steps.`;
  const data = await runModel(env, prompt);
  let definition = data.definition ? String(data.definition).trim() : '';
  let steps = Array.isArray(data.steps) ? data.steps.map(s=>String(s).trim()).filter(Boolean) : [];
  if (!steps.length && data._raw) {
    steps = data._raw.split(/\n|;|\. /).map(s=>s.replace(/^[-*\d\.\s]+/,'').trim()).filter(Boolean).slice(0,5);
  }
  return json({ definition, steps: steps.slice(0,7) });
}
