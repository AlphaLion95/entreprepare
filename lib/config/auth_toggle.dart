// ---------------------------------------------------------------------------
// AUTH / OFFLINE MODE TOGGLE
// Set kAuthDisabled:
//   true  -> Offline/local mode. Skips login UI, no Firestore writes.
//            Data persists only on device using SharedPreferences via LocalStore.
//            Services (plans, quiz, settings) branch automatically.
//   false -> Normal cloud mode. Login screen active, Firebase Auth + Firestore
//            persistence restored.
// How to switch back to online:
//   1. Change to: const bool kAuthDisabled = false;
//   2. Re-run the app; login screen will appear and cloud sync resumes.
// Existing offline data remains only locally; you can choose to manually
// migrate it if needed.
// ---------------------------------------------------------------------------
const bool kAuthDisabled = true; // Flip to false to re-enable login/cloud
