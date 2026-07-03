import 'package:flutter/material.dart';

class TicketScannerEventVm {
  const TicketScannerEventVm({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final num? price;
  final Color accentColor;
}