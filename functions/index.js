const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Minimal OpenAI call helper (Chat Completions with JSON-style output enforcement)
const OPENAI_KEY = process.env.OPENAI_KEY || process.env.openai_key || null;
async function callOpenAIJson(prompt, schemaHint) {
  if (!OPENAI_KEY) throw new Error('OpenAI key missing');
  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
  const system = `You are a strict JSON API. Output ONLY valid JSON. ${schemaHint}`;
  const body = {
    model,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: prompt }
    ],
    temperature: 0.65,
    response_format: { type: 'json_object' }
  };
  const resp = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error('OpenAI HTTP ' + resp.status + ' ' + text);
  }
  const data = await resp.json();
  const content = data.choices?.[0]?.message?.content || '{}';
  return JSON.parse(content);
}

exports.activateLicense = functions.https.onCall(async (data, context) => {
  const key = data && data.key ? String(data.key).trim().toUpperCase() : null;
  if (!key) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing license key.');
  }

  // Recommended: require the caller to be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'You must sign in to activate a license.');
  }
  const uid = context.auth.uid;
  const deviceInfo = data.deviceInfo || null;

  const licenseRef = db.collection('licenses').doc(key);

  try {
    const result = await db.runTransaction(async (tx) => {
      const doc = await tx.get(licenseRef);
      if (!doc.exists) {
        throw new functions.https.HttpsError('not-found', 'Invalid license key.');
      }
      const lic = doc.data();

      // expiry check (if present)
      if (lic.expiresAt && lic.expiresAt.toDate && lic.expiresAt.toDate() < new Date()) {
        throw new functions.https.HttpsError('failed-precondition', 'License expired.');
      }

      // One-time license logic
      if (lic.oneTime === true) {
        if (lic.active === false || lic.activatedBy) {
          throw new functions.https.HttpsError('already-exists', 'License already used.');
        }
        tx.update(licenseRef, {
          active: false,
          activatedBy: uid,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastDevice: deviceInfo
        });
        // audit log
        const logRef = db.collection('license_activations').doc();
        tx.set(logRef, {
          licenseId: key,
          userId: uid,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          device: deviceInfo,
          oneTime: true
        });
        return { plan: lic.plan, features: lic.features || {}, oneTime: true };
      } else {
        // reusable license: update counters + last activation
        const activationCount = (lic.activationCount || 0) + 1;
        tx.update(licenseRef, {
          activationCount: activationCount,
          lastActivatedBy: uid,
          lastActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastDevice: deviceInfo
        });
        const logRef = db.collection('license_activations').doc();
        tx.set(logRef, {
          licenseId: key,
          userId: uid,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          device: deviceInfo,
          oneTime: false
        });
        return { plan: lic.plan, features: lic.features || {}, oneTime: false, activationCount: activationCount };
      }
    });

    return { success: true, ...result };
  } catch (err) {
    if (err instanceof functions.https.HttpsError) throw err;
    console.error('activation error', err);
    throw new functions.https.HttpsError('internal', 'Server error: ' + (err.message || 'unknown'));
  }
});

// === AI Ideas Generation (HTTP) ===
// Request: { query, limit }
// Response: { ideas: [string] }
exports.aiIdeas = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  const { query = '', limit = 8 } = req.body || {};
  if (!query) return res.status(400).json({ error: 'Missing query' });
  try {
    const prompt = `Generate up to ${limit} concise, distinct startup or small business ideas related to: "${query}". Return JSON: {"ideas": [string...]}. Ideas should be 5-12 words, actionable, and avoid numbering.`;
    const data = await callOpenAIJson(prompt, 'Schema: {"ideas":["idea 1","idea 2"]}');
    let ideas = Array.isArray(data.ideas) ? data.ideas.map(String) : [];
    if (!ideas.length) throw new Error('Empty ideas');
    ideas = ideas.slice(0, limit);
    return res.json({ ideas });
  } catch (err) {
    console.error('aiIdeas error', err);
    return res.status(500).json({ error: 'AI failure' });
  }
});

// === AI Solution Generation (HTTP) ===
// Request: { activity, problem, goal, limit }
// Response: { solutions: [ { title, rationale, steps[] } ] }
exports.aiSolutions = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  const { activity = '', problem = '', goal = '', limit = 3 } = req.body || {};
  if (!activity || !problem) return res.status(400).json({ error: 'Missing fields' });
  try {
    const prompt = `Activity: ${activity}\nProblem: ${problem}\nGoal: ${goal}\nGenerate ${limit} strategic solution approaches. Each must have: title (max 6 words), rationale (1 sentence), and 4-6 concrete execution steps. JSON schema: {"solutions":[{"title":"","rationale":"","steps":["",""]}]}`;
    const data = await callOpenAIJson(prompt, 'Schema: {"solutions":[{"title":"t","rationale":"r","steps":["s"]}]}');
    let solutions = Array.isArray(data.solutions) ? data.solutions : [];
    solutions = solutions.filter(s => s && s.title && s.steps && Array.isArray(s.steps));
    solutions = solutions.slice(0, limit).map(s => ({
      title: String(s.title).trim(),
      rationale: String(s.rationale || '').trim(),
      steps: s.steps.map(x => String(x).trim()).filter(Boolean).slice(0, 8)
    }));
    if (!solutions.length) throw new Error('Empty solutions');
    return res.json({ solutions });
  } catch (err) {
    console.error('aiSolutions error', err);
    return res.status(500).json({ error: 'AI failure' });
  }
});

// === AI Milestone Assistance (HTTP) ===
// Request: { title }
// Response: { definition, steps: [] }
exports.aiMilestone = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  const { title = '' } = req.body || {};
  if (!title) return res.status(400).json({ error: 'Missing title' });
  try {
    const prompt = `Milestone: ${title}\nProvide a concise definition (max 24 words) and 5 clear steps. JSON schema: {"definition":"","steps":["",""]}`;
    const data = await callOpenAIJson(prompt, 'Schema: {"definition":"d","steps":["s1","s2"]}');
    const definition = String(data.definition || '').trim();
    let steps = Array.isArray(data.steps) ? data.steps.map(s => String(s).trim()).filter(Boolean) : [];
    steps = steps.slice(0, 7);
    if (!definition || !steps.length) throw new Error('Empty milestone');
    return res.json({ definition, steps });
  } catch (err) {
    console.error('aiMilestone error', err);
    return res.status(500).json({ error: 'AI failure' });
  }
});

// === Preview extractor for web (HTTP) ===
// GET /preview?target=<url>
// Response: { preview: string|null }
exports.preview = functions.https.onRequest(async (req, res) => {
  // CORS preflight
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).send('');
  if (req.method !== 'GET') return res.status(405).json({ error: 'GET only' });
  const target = (req.query.target || '').toString();
  try {
    let url;
    try { url = new URL(target); } catch (_) { return res.status(400).json({ error: 'Invalid target' }); }
    const headers = {
      'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Range': 'bytes=0-200000',
    };
    let html = null;
  let resp = await fetch(url, { headers });
    if (resp.ok) {
      html = await resp.text();
    }
    if (!html) {
      // Retry without range
      const headers2 = {
        'User-Agent': headers['User-Agent'],
        'Accept': headers['Accept'],
      };
  resp = await fetch(url, { headers: headers2 });
      if (resp.ok) html = await resp.text();
    }
    if (!html) return res.json({ preview: null });
    const sample = makeSample(html);
    const preview = extractPreview(sample);
    return res.json({ preview: preview });
  } catch (err) {
    console.error('preview error', err);
    return res.json({ preview: null });
  }
});

function makeSample(html) {
  const lower = html.toLowerCase();
  const headEnd = lower.indexOf('</head>');
  const bodyExtra = 50000; // 50KB after head
  const capNoHead = 150000; // 150KB if no head
  if (headEnd >= 0) {
    const end = Math.min(html.length, headEnd + 7 + bodyExtra);
    return html.substring(0, end);
  }
  const endIdx = Math.min(html.length, capNoHead);
  return html.substring(0, endIdx);
}

function extractPreview(sample) {
  const meta = extractMeta(sample, 'property', 'og:description')
    || extractMeta(sample, 'name', 'twitter:description')
    || extractMeta(sample, 'property', 'twitter:description')
    || extractMeta(sample, 'name', 'description');
  let text = meta;
  if (!text) {
    // JSON-LD description
    const ld = sample.match(/<script[^>]*type\s*=\s*"application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/i);
    if (ld && ld[1]) {
      const m = ld[1].match(/"description"\s*:\s*"([\s\S]*?)"/);
      if (m) text = m[1];
    }
  }
  if (!text) {
    // First good paragraph
    const paras = [...sample.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/ig)].map(m => m[1]);
    const clean = (s) => normalizeSpaces(decodeEntities(stripHtml(s))).trim();
    const isEnum = (s) => /^(step|part)\s*\d+[:).\-]\s*/i.test(s.trimLeft()) || /^\d+\s*[).\-:]\s*/.test(s.trimLeft());
    for (const p of paras) {
      const plain = clean(p);
      if (!plain || plain.length < 40) continue;
      if (isEnum(plain)) continue;
      if (/^(by |posted )/i.test(plain)) continue;
      if (/cookie|subscribe/i.test(plain)) continue;
      text = plain; break;
    }
    if (!text) {
      for (const p of paras) { const plain = clean(p); if (plain) { text = plain; break; } }
    }
  }
  if (!text) return null;
  text = normalizeSpaces(decodeEntities(stripHtml(text))).trim();
  if (!text) return null;
  const m = text.match(/[.!?]\s/);
  if (m && m.index >= 60) {
    text = text.substring(0, m.index + 1);
  } else if (text.length > 220) {
    text = text.substring(0, 220).trim() + '…';
  }
  text = text.replace(/^\s*\d+\s*[).\-:]\s*/, '');
  text = text.replace(/^(step|part)\s*\d+[:).\-]\s*/i, '');
  return text;
}

function extractMeta(html, attr, value) {
  const re1 = new RegExp('<meta[^>]*' + attr + '=["\']' + value + '["\'][^>]*content=["\'](.*?)["\']', 'is');
  const re2 = new RegExp('<meta[^>]*content=["\'](.*?)["\'][^>]*' + attr + '=["\']' + value + '["\']', 'is');
  const m = html.match(re1) || html.match(re2);
  return m ? m[1] : null;
}

function stripHtml(s) { return s.replace(/<[^>]+>/g, ' '); }
function normalizeSpaces(s) { return s.replace(/\s+/g, ' '); }
function decodeEntities(s) {
  return s
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}
