import 'package:flutter/material.dart';

Color parseHexColor(
  String? hex, {
  Color fallback = const Color(0xFF6B8FBF),
}) {
  if (hex == null || hex.trim().isEmpty) return fallback;

  final cleaned = hex.trim().replaceFirst('#', '');
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;

  try {
    return Color(int.parse(normalized, radix: 16));
  } catch (_) {
    return fallback;
  }
}