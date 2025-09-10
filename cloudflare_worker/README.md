# Cloudflare Workers AI Integration

Use a single Worker endpoint for ideas, solutions, and milestones.

## 1. Enable Workers AI

1. In Cloudflare dashboard enable Workers & AI.
2. Bind AI in your Worker (UI toggle "Add AI binding" -> variable name `AI`).

## 2. Create Worker

In dashboard, create new Worker and paste contents of `ai_worker.js`.

## 3. Deploy

Save & Deploy. Note the public URL (e.g. `https://yourname.worker.dev`).

## 4. Test (local curl examples)

```bash
curl -X POST https://<worker-url>/ -H "Content-Type: application/json" -d '{"type":"ideas","query":"fitness app"}'
curl -X POST https://<worker-url>/ -H "Content-Type: application/json" -d '{"type":"solutions","activity":"SaaS time tracking","problem":"low conversions","goal":"increase paid users"}'
curl -X POST https://<worker-url>/ -H "Content-Type: application/json" -d '{"type":"milestone","title":"Product launch"}'
```

## 5. Configure App

In `lib/config/ai_config.dart` set all three endpoints to the same Worker URL (or adjust services to single endpoint pattern):

```dart
const String kAiIdeasEndpoint = 'https://<worker-url>/';
const String kAiSolutionsEndpoint = 'https://<worker-url>/';
const String kAiMilestoneEndpoint = 'https://<worker-url>/';
const bool kAiRemoteEnabled = true;
```

The current Dart services expect endpoint-specific schemas, which this Worker returns based on `type` field you send. To keep existing services unchanged you can instead create three small wrapper Workers each calling `handleIdeas/handleSolutions/handleMilestone`. Or patch Dart services to send the `type` field (optional enhancement).

## 6. Optional: Separate Routes

You can route by path:

```javascript
if (url.pathname === '/ideas') {
	// handle ideas
}
```

Then set each endpoint explicitly to `/ideas`, `/solutions`, `/milestone`.

## 7. Costs & Limits

Workers AI free tier has daily limits; watch dashboard metrics.

## 8. Security

No secret keys exposed; all inference server-side.

## 9. Fallback Handling

Worker attempts to salvage JSON if model returns extra text. Client should still validate empty arrays.

## 10. Next Steps

- Add caching (KV) if you want to reduce repeated cost.
- Add rate limiting with Durable Objects or Turnstile.
