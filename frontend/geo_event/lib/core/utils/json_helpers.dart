import '../../core/utils/date_time_extensions.dart';

class JsonHelpers {
  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString().trim());
  }

  static double asDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().trim()) ?? fallback;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }

    return fallback;
  }

  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is DateTime) {
        return value.isUtc ? value : value.toUtc();
      }

      return parseApiDateTime(value);
    } catch (_) {
      return null;
    }
  }

  static DateTime parseDateTimeRequired(
    dynamic value,
    DateTime fallback,
  ) {
    return parseDateTime(value) ?? fallback;
  }

  static String? normalize(dynamic value) {
    final text = value?.toString().trim();

    return text == null || text.isEmpty ? null : text;
  }

  static List<String> asStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
}