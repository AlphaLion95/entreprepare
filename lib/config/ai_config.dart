// AI configuration for remote OpenAI-backed generation.
// Set the deployed Cloud Function HTTPS URLs below and flip kAiRemoteEnabled.
// Do NOT put your OpenAI key here (it stays server-side in Cloud Functions env).
const bool kAiIdeasEnabled = true; // UI toggle

// Deployed HTTPS AI proxy endpoint(s). You can point all three to the same unified proxy.
// Example: const _baseAi = 'https://entreprepare.vercel.app/api/ai';
const String kAiIdeasEndpoint = 'https://entreprepare.vercel.app/api/ai';
const String kAiSolutionsEndpoint = 'https://entreprepare.vercel.app/api/ai';
const String kAiMilestoneEndpoint = 'https://entreprepare.vercel.app/api/ai';

// Global remote toggle; when true and endpoints non-empty, app will call server.
const bool kAiRemoteEnabled = true;

// Optional API key header if you add custom auth between app and your backend (NOT OpenAI key!)
const String kAiApiKey = '';

// Enable verbose logging for AI responses/errors (development only)
const bool kAiDebugLogging = true;
