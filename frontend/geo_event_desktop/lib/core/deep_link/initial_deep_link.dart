import 'dart:io';

Uri? extractInitialDeepLink(List<String> args) {
  Uri? tryParseGeoEventUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.toLowerCase().startsWith('geoevent://')) return null;
    return Uri.tryParse(trimmed);
  }

  for (final arg in args) {
    final uri = tryParseGeoEventUri(arg);
    if (uri != null) return uri;
  }

  for (final arg in Platform.executableArguments) {
    final uri = tryParseGeoEventUri(arg);
    if (uri != null) return uri;
  }

  return null;
}