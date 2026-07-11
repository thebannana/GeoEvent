import 'package:intl/intl.dart';

enum PriceDisplayStyle {
  plain,
  symbolLeading,
  symbolTrailing,
  code,
}

class PriceFormatter {
  const PriceFormatter._();

  static const String bam = 'BAM';
  static const String usd = 'USD';
  static const String eur = 'EUR';

  static String format(
    num? value, {
    String currency = bam,
    int decimalDigits = 2,
    String fallback = '-',
    PriceDisplayStyle style = PriceDisplayStyle.code,
  }) {
    if (value == null) return fallback;

    final locale = _localeFor(currency);

    switch (style) {
      case PriceDisplayStyle.plain:
        return NumberFormat.decimalPattern(locale).format(
          _normalizeValue(value, decimalDigits),
        );

      case PriceDisplayStyle.symbolLeading:
        return NumberFormat.currency(
          locale: locale,
          name: currency,
          symbol: _symbolFor(currency),
          decimalDigits: decimalDigits,
        ).format(value);

      case PriceDisplayStyle.symbolTrailing:
        return NumberFormat.currency(
          locale: locale,
          name: currency,
          symbol: _symbolFor(currency),
          decimalDigits: decimalDigits,
          customPattern: '#,##0.00 ¤',
        ).format(value).replaceFirstMapped(
              RegExp(r'([0-9])([.,]00 )'),
              (match) => decimalDigits == 0
                  ? '${match.group(1)} '
                  : match.group(0)!,
            );

      case PriceDisplayStyle.code:
        return NumberFormat.currency(
          locale: locale,
          name: currency,
          symbol: currency,
          decimalDigits: decimalDigits,
        ).format(value);
    }
  }

  static String formatCompact(
    num? value, {
    String currency = bam,
    String fallback = '-',
    PriceDisplayStyle style = PriceDisplayStyle.code,
  }) {
    if (value == null) return fallback;

    final abs = value.abs();

    if (style == PriceDisplayStyle.plain) {
      if (abs >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      }
      if (abs >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      }

      return format(
        value,
        currency: currency,
        decimalDigits: 0,
        fallback: fallback,
        style: PriceDisplayStyle.plain,
      );
    }

    if (abs >= 1000000) {
      return _applyAffix(
        number: (value / 1000000).toStringAsFixed(1),
        affixBase: 'M',
        currency: currency,
        style: style,
      );
    }

    if (abs >= 1000) {
      return _applyAffix(
        number: (value / 1000).toStringAsFixed(1),
        affixBase: 'K',
        currency: currency,
        style: style,
      );
    }

    return format(
      value,
      currency: currency,
      decimalDigits: 0,
      fallback: fallback,
      style: style,
    );
  }

  static String formatRange(
    num? min,
    num? max, {
    String currency = bam,
    int decimalDigits = 0,
    PriceDisplayStyle style = PriceDisplayStyle.code,
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
          style: style,
        );
      }

      return '${format(min, currency: currency, decimalDigits: decimalDigits, fallback: 'Free', style: style)} - ${format(max, currency: currency, decimalDigits: decimalDigits, fallback: 'Free', style: style)}';
    }

    if (min != null) {
      if (min == 0) return 'From Free';
      return 'From ${format(min, currency: currency, decimalDigits: decimalDigits, fallback: 'Free', style: style)}';
    }

    if (max == null || max == 0) return 'Free';
    return 'Up to ${format(max, currency: currency, decimalDigits: decimalDigits, fallback: 'Free', style: style)}';
  }

  static double? tryParse(String? input) {
    if (input == null) return null;

    final normalized = input
        .replaceAll(bam, '')
        .replaceAll(usd, '')
        .replaceAll(eur, '')
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

  static String formatPriceWithBam(
    num? price, {
    String freeLabel = 'Free',
    int decimalDigits = 2,
  }) {
    if (price == null) return '-';
    if (price <= 0) return freeLabel;

    final normalized = _normalizeValue(price, decimalDigits);
    final hasFraction = normalized % 1 != 0;

    return format(
      normalized,
      currency: bam,
      decimalDigits: hasFraction ? decimalDigits : 0,
      fallback: freeLabel,
      style: PriceDisplayStyle.code,
    );
  }

  static String _localeFor(String currency) {
    switch (currency) {
      case usd:
        return 'en_US';
      case eur:
        return 'de_DE';
      case bam:
      default:
        return 'bs_BA';
    }
  }

  static String _symbolFor(String currency) {
    switch (currency) {
      case usd:
        return '\$';
      case eur:
        return '€';
      case bam:
        return 'KM';
      default:
        return currency;
    }
  }

  static num _normalizeValue(num value, int decimalDigits) {
    return num.parse(value.toStringAsFixed(decimalDigits));
  }

  static String _applyAffix({
    required String number,
    required String affixBase,
    required String currency,
    required PriceDisplayStyle style,
  }) {
    switch (style) {
      case PriceDisplayStyle.plain:
        return '$number$affixBase';
      case PriceDisplayStyle.symbolLeading:
        return '${_symbolFor(currency)}$number$affixBase';
      case PriceDisplayStyle.symbolTrailing:
        return '$number$affixBase ${_symbolFor(currency)}';
      case PriceDisplayStyle.code:
        return '$currency $number$affixBase';
    }
  }
}