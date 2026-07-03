import 'package:flutter/material.dart';

class ColorParser {
  const ColorParser._();

  static Color parseHex(
    String? hex, {
    Color fallback = const Color(0xFF6B8FBF),
  }) {
    if (hex == null) return fallback;

    var cleaned = hex.trim();
    if (cleaned.isEmpty) return fallback;

    if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.toLowerCase().startsWith('0x')) {
      cleaned = cleaned.substring(2);
    }

    if (cleaned.length == 3) {
      cleaned = cleaned.split('').map((c) => '$c$c').join();
    } else if (cleaned.length == 4) {
      cleaned = cleaned.split('').map((c) => '$c$c').join();
    }

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return fallback;
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

Color parseHex(
  String? hex, {
  Color fallback = const Color(0xFF6B8FBF),
}) {
  return ColorParser.parseHex(hex, fallback: fallback);
}