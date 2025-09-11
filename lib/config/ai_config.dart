// AI configuration for remote OpenAI-backed generation.
// Set the deployed Cloud Function HTTPS URLs below and flip kAiRemoteEnabled.
// Do NOT put your OpenAI key here (it stays server-side in Cloud Functions env).
const bool kAiIdeasEnabled = true; // UI toggle

// Deployed HTTPS function endpoints (e.g. https://us-central1-YOUR_PROJECT.cloudfunctions.net/aiIdeas )
const String kAiIdeasEndpoint = '';
const String kAiSolutionsEndpoint = '';
const String kAiMilestoneEndpoint = '';

// Global remote toggle; when true and endpoints non-empty, app will call server.
const bool kAiRemoteEnabled = false;

// Optional API key header if you add custom auth between app and your backend (NOT OpenAI key!)
const String kAiApiKey = '';
