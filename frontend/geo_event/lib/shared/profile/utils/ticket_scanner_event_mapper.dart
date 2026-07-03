import 'package:flutter/material.dart';

import '../../events/models/my_event_response_dto.dart';
import '../models/ticket_scanner_event_vm.dart';

class TicketScannerEventMapper {
  const TicketScannerEventMapper._();

  static TicketScannerEventVm map(MyEventResponseDto event) {
    return TicketScannerEventVm(
      title: event.title,
      subtitle: _buildSubtitle(event),
      imageUrl: _resolveImageUrl(event),
      price: event.price,
      accentColor: _resolveAccentColor(event),
    );
  }

  static String _buildSubtitle(MyEventResponseDto event) {
    final parts = <String>[
      if ((event.segmentName ?? '').trim().isNotEmpty) event.segmentName!.trim(),
      if ((event.genreName ?? '').trim().isNotEmpty) event.genreName!.trim(),
    ];

    return parts.join(' · ');
  }

  static String? _resolveImageUrl(MyEventResponseDto event) {
    final cover = event.coverImageUrl?.trim();
    if (cover != null && cover.isNotEmpty) {
      return cover;
    }

    if (event.imageUrls.isEmpty) {
      return null;
    }

    final first = event.imageUrls.first.trim();
    return first.isEmpty ? null : first;
  }

  static Color _resolveAccentColor(MyEventResponseDto event) {
    final source = [
      event.segmentName,
      event.genreName,
      event.subGenreName,
    ]
        .whereType<String>()
        .map((e) => e.toLowerCase())
        .join(' ');

    if (source.contains('concert') || source.contains('music')) {
      return const Color(0xFF5E7BFF);
    }
    if (source.contains('sport')) {
      return const Color(0xFFFF5A76);
    }
    if (source.contains('education') || source.contains('seminar')) {
      return const Color(0xFF68C95A);
    }

    return const Color(0xFF6B8FBF);
  }
}