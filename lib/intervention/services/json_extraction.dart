import 'dart:convert';

/// Extracts the first valid JSON object from a raw AI text response.
/// Models sometimes wrap JSON in markdown code fences or add stray text
/// around it despite instructions not to -- this strips that defensively
/// rather than trusting the response is always a bare JSON object.
/// Returns null (never throws) if nothing parseable is found, so callers
/// can fall back to a safe decision instead of crashing.
Map<String, dynamic>? extractJsonObject(String raw) {
  var text = raw.trim();

  // Strip ```json ... ``` or ``` ... ``` fences if present.
  final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
  if (fenceMatch != null) {
    text = fenceMatch.group(1)!.trim();
  }

  // If there's leading/trailing prose around the object, take the
  // outermost {...} span.
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end == -1 || end < start) return null;
  final candidate = text.substring(start, end + 1);

  try {
    final decoded = jsonDecode(candidate);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}
