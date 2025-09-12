// AI configuration for remote OpenAI-backed generation.
// Set the deployed Cloud Function HTTPS URLs below and flip kAiRemoteEnabled.
// Do NOT put your OpenAI key here (it stays server-side in Cloud Functions env).
const bool kAiIdeasEnabled = true; // UI toggle

// Deployed HTTPS AI proxy endpoint(s). All three point to the same unified proxy.
// Set this to your actual Vercel deployment domain.
// Example after deploy: https://entreprepare-api.vercel.app/api/ai
const String _kAiBaseEndpoint = 'https://entreprepare.vercel.app/api/ai';
const String kAiIdeasEndpoint = _kAiBaseEndpoint;
const String kAiSolutionsEndpoint = _kAiBaseEndpoint;
const String kAiMilestoneEndpoint = _kAiBaseEndpoint;

// Global remote toggle; when true and endpoints non-empty, app will call server.
const bool kAiRemoteEnabled = true;

// Optional API key header if you add custom auth between app and your backend (NOT OpenAI key!)
const String kAiApiKey = '';

// Enable verbose logging for AI responses/errors (development only)
const bool kAiDebugLogging = true;
