export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(200).json({ message: 'Groq AI endpoint ready. POST JSON to use.' });
  }
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'missing_server_key' });

  const { type, query, activity, problem, goal, title, limit } = req.body || {};
  let detected = type;
  // Infer type if not provided
  if (!detected) {
    if (query) detected = 'ideas';
    else if (activity || problem) detected = 'solutions';
    else if (title) detected = 'milestone';
    else detected = 'ideas';
  }

  try {
    let prompt = '';
    if (detected === 'ideas') {
      if (!query) return res.status(400).json({ error: 'missing_query' });
      const n = Math.min(parseInt(limit || 8, 10), 12);
      prompt = `Generate up to ${n} concise (5-12 words) actionable startup or small business ideas about: ${query}. Return JSON {"ideas":["idea 1","idea 2"]}`;
    } else if (detected === 'solutions') {
      if (!activity || !problem) return res.status(400).json({ error: 'missing_fields' });
      const n = Math.min(parseInt(limit || 3, 10), 5);
      prompt = `Activity: ${activity}\nProblem: ${problem}\nGoal: ${goal || ''}\nGenerate ${n} solution objects. JSON schema: {"solutions":[{"title":"","rationale":"","steps":["","""]}]}. Title <=6 words, rationale 1 sentence, 4-6 concrete action steps.`;
    } else if (detected === 'milestone') {
      if (!title) return res.status(400).json({ error: 'missing_title' });
      prompt = `Milestone: ${title}\nReturn JSON {"definition":"","steps":["step1","step2"]}. Definition <=22 words; 5 specific actionable steps.`;
    } else {
      return res.status(400).json({ error: 'unsupported_type' });
    }

    const model = process.env.GROQ_MODEL || 'llama3-8b-8192';
    const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model,
        temperature: 0.65,
        messages: [
          { role: 'system', content: 'You are a JSON API. Output ONLY valid JSON. No markdown, no commentary.' },
          { role: 'user', content: prompt }
        ]
      })
    });

    if (!resp.ok) {
      const t = await resp.text();
      return res.status(502).json({ error: 'groq_http', detail: t });
    }

    const data = await resp.json();
    const content = data.choices?.[0]?.message?.content || '{}';
    const parsed = safeParse(content);
    if (!parsed) return res.status(502).json({ error: 'parse_failed', raw: content });

    if (detected === 'ideas') {
      return res.json({ ideas: normalizeIdeas(parsed, limit) });
    }
    if (detected === 'solutions') {
      return res.json({ solutions: normalizeSolutions(parsed) });
    }
    if (detected === 'milestone') {
      return res.json(normalizeMilestone(parsed));
    }
    return res.status(500).json({ error: 'unexpected_branch' });
  } catch (e) {
    return res.status(500).json({ error: 'proxy_error', detail: e.message });
  }
}

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
  const limit = Math.min(parseInt(limitRaw || 8, 10), 12);
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
