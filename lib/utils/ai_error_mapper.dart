// Maps backend AI error codes / HTTP status based messages to user-friendly text.
class AiErrorMapper {
  static String map(Object error) {
    final raw = error.toString();
    // Try to extract code patterns like parse_failed, empty_solutions etc.
    final lower = raw.toLowerCase();
    if (lower.contains('missing_server_key')) {
      return 'AI server not configured yet. Please try again later.';
    }
    if (lower.contains('rate_limited') || lower.contains('429')) {
      return 'Too many AI requests. Pause a moment and retry.';
    }
    if (lower.contains('parse_failed')) {
      return 'AI response formatting issue. Retrying may fix it.';
    }
    if (lower.contains('empty_solutions')) {
      return 'No usable solutions returned. Try refining the problem description.';
    }
    if (lower.contains('invalid_milestone')) {
      return 'Could not structure milestone right now. Try again.';
    }
    if (lower.contains('groq_failed')) {
      return 'Upstream model temporarily unavailable. Retry shortly.';
    }
    if (lower.contains('remote ai disabled')) {
      return 'AI is disabled in settings.';
    }
    if (lower.contains('malformed ai response')) {
      return 'Unexpected AI output. Please retry.';
    }
    if (lower.contains('timeout')) {
      return 'AI request timed out. Check connection and retry.';
    }
    if (lower.contains('network') || lower.contains('failed host lookup')) {
      return 'Network issue reaching AI server.';
    }
    return 'AI request failed. Please try again.';
  }
}
