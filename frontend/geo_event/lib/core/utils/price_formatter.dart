import 'package:intl/intl.dart';

class PriceFormatter {
  const PriceFormatter._();

  static const String bam = 'BAM';
  static const String usd = 'USD';

  static String format(
    num? value, {
    String currency = bam,
    int decimalDigits = 2,
    String fallback = '-',
  }) {
    if (value == null) return fallback;

    final formatter = NumberFormat.currency(
      locale: currency == usd ? 'en_US' : 'bs_BA',
      name: currency,
      symbol: currency,
      decimalDigits: decimalDigits,
    );

    return formatter.format(value);
  }

  static String formatCompact(
    num? value, {
    String currency = bam,
    String fallback = '-',
  }) {
    if (value == null) return fallback;

    final abs = value.abs();

    if (abs >= 1000000) {
      return '$currency ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '$currency ${(value / 1000).toStringAsFixed(1)}K';
    }

    return format(
      value,
      currency: currency,
      decimalDigits: 0,
      fallback: fallback,
    );
  }

  static String formatRange(
    num? min,
    num? max, {
    String currency = bam,
    int decimalDigits = 0,
  }) {
    if (min == null && max == null) return 'Free';

    if (min != null && max != null) {
      if (min == 0 && max == 0) return 'Free';
      if (min == max) {
        return format(
          min,
          currency: currency,
          decimalDigits: decimalDigits,
          fallback: 'Free',
        );
      }

      return '${format(min, currency: currency, decimalDigits: decimalDigits, fallback: 'Free')} - ${format(max, currency: currency, decimalDigits: decimalDigits, fallback: 'Free')}';
    }

    if (min != null) {
      if (min == 0) return 'From Free';
      return 'From ${format(min, currency: currency, decimalDigits: decimalDigits, fallback: 'Free')}';
    }

    if (max == null || max == 0) return 'Free';
    return 'Up to ${format(max, currency: currency, decimalDigits: decimalDigits, fallback: 'Free')}';
  }

  static double? tryParse(String? input) {
    if (input == null) return null;

    final normalized = input
        .replaceAll(bam, '')
        .replaceAll(usd, '')
        .replaceAll('KM', '')
        .replaceAll('\$', '')
        .replaceAll('€', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}