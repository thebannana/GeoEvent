import 'package:intl/intl.dart';

class PriceFormatter {
  const PriceFormatter._();

  static String format(
    num? value, {
    String symbol = 'KM',
    int decimalDigits = 2,
  }) {
    if (value == null) {
      return '$symbol 0.${'0' * decimalDigits}';
    }

    final formatter = NumberFormat.currency(
      locale: 'bs_BA',
      symbol: symbol,
      decimalDigits: decimalDigits,
    );

    return formatter.format(value);
  }

  static String formatCompact(
    num? value, {
    String symbol = 'KM',
  }) {
    if (value == null) {
      return '$symbol 0';
    }

    final abs = value.abs();

    if (abs >= 1000000) {
      return '$symbol ${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (abs >= 1000) {
      return '$symbol ${(value / 1000).toStringAsFixed(1)}K';
    }

    return format(value, symbol: symbol, decimalDigits: 0);
  }

  static String formatRange(
    num? min,
    num? max, {
    String symbol = 'KM',
    int decimalDigits = 0,
  }) {
    if (min == null && max == null) {
      return 'Free';
    }

    if (min != null && max != null) {
      if (min == 0 && max == 0) {
        return 'Free';
      }

      if (min == max) {
        return format(min, symbol: symbol, decimalDigits: decimalDigits);
      }

      return '${format(min, symbol: symbol, decimalDigits: decimalDigits)} - ${format(max, symbol: symbol, decimalDigits: decimalDigits)}';
    }

    if (min != null) {
      if (min == 0) {
        return 'From Free';
      }

      return 'From ${format(min, symbol: symbol, decimalDigits: decimalDigits)}';
    }

    if (max == null || max == 0) {
      return 'Free';
    }

    return 'Up to ${format(max, symbol: symbol, decimalDigits: decimalDigits)}';
  }

  static double? tryParse(String? input) {
    if (input == null) return null;

    final normalized = input
        .replaceAll('KM', '')
        .replaceAll('€', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }
}