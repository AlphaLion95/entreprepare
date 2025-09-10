// AI feature configuration
// Toggle and endpoint placeholders for integrating a free / optional AI source.
// By default uses local heuristic generation (no network) when endpoint disabled.
const bool kAiIdeasEnabled = true; // flip to false to hide AI tab

// If you later provide a backend proxy (e.g., Cloud Function) expose it here.
// Leave empty to use local heuristic suggestions only.
const String kAiIdeasEndpoint = '';

// Remote problem solution endpoint (Cloud Function or backend) returning JSON { ideas: [], solutions: [], error? }
const String kAiSolutionsEndpoint = '';

// Remote milestone assist endpoint returning { definition: string, steps: [] }
const String kAiMilestoneEndpoint = '';

// Global toggle: if true and endpoint strings not empty, remote call attempted
const bool kAiRemoteEnabled = false;

// Optional API key constant placeholder (avoid committing real keys)
const String kAiApiKey = '';
