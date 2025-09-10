const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();

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

// === AI Solution Generation (HTTP) ===
// Expected request JSON: { activity, problem, goal, limit }
// Response: { solutions: [ { title, rationale, steps[] } ] }
exports.aiSolutions = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  const { activity = '', problem = '', goal = '', limit = 3 } = req.body || {};
  if (!activity || !problem) return res.status(400).json({ error: 'Missing fields' });

  // Example OpenAI call (commented). Provide your own key via env config.
  // const OPENAI_KEY = process.env.OPENAI_KEY;
  // if (!OPENAI_KEY) return res.status(500).json({ error: 'Missing OpenAI key' });
  // const prompt = `Business activity: ${activity}\nProblem: ${problem}\nGoal: ${goal}\nGenerate ${limit} actionable solution strategies as JSON array with title, rationale, steps.`;
  // const aiResp = await fetch('https://api.openai.com/v1/chat/completions', { ... });
  // Parse and map.

  // Placeholder deterministic sample (replace with real model output)
  const base = [
    {
      title: 'Targeted Niche Positioning',
      rationale: 'Focus the software on a narrow pain point to increase perceived value and conversion.',
      steps: [
        'Interview 5 prospective users in a micro-niche.',
        'Extract top workflow bottleneck repeated across interviews.',
        'Refine feature set to solve only that bottleneck.',
        'Revise landing page headline around outcome metric.',
        'Launch micro beta and collect activation metrics.',
      ],
    },
    {
      title: 'Multi-Channel Distribution Test',
      rationale: 'Identify profitable acquisition channels through small parallel experiments.',
      steps: [
        'Select 3 channels (communities, cold email, directory listing).',
        'Craft channel-specific short pitch / value hook.',
        'Run each for 7 days with consistent daily outreach quota.',
        'Record leads, trials, conversions, CAC proxy.',
        'Double down on best performing channel next cycle.',
      ],
    },
    {
      title: 'Monetization Validation Sprint',
      rationale: 'Test pricing willingness early to avoid building non-revenue features.',
      steps: [
        'Design 2 pricing hypotheses (e.g., usage vs tiered).',
        'Add simple upgrade/paywall touchpoint in app.',
        'Run user calls to probe perceived ROI & objections.',
        'Measure trial-to-upgrade intent signals.',
        'Select model with higher clarity & proceed to implement billing.',
      ],
    },
  ];
  res.json({ solutions: base.slice(0, Math.min(limit, base.length)) });
});

// === AI Milestone Assistance (HTTP) ===
// Request: { title }
// Response: { definition, steps: [] }
exports.aiMilestone = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  const { title = '' } = req.body || {};
  if (!title) return res.status(400).json({ error: 'Missing title' });
  // Placeholder sample. Replace with model call similar to above.
  const lower = title.toLowerCase();
  let definition = 'Strategic milestone to advance business progress.';
  let steps = [
    'Clarify success criteria.',
    'List required tasks/resources.',
    'Assign ownership & timeline.',
    'Execute tasks & monitor blockers.',
    'Review outcome vs criteria & document learnings.',
  ];
  if (lower.includes('launch')) {
    definition = 'Coordinate tasks for a successful product launch with minimal risk.';
    steps = [
      'Finalize release candidate build.',
      'Prepare launch communications & assets.',
      'Run pre-launch quality checklist.',
      'Deploy at low-traffic window & verify health.',
      'Announce & monitor initial user feedback.',
    ];
  }
  res.json({ definition, steps });
});
