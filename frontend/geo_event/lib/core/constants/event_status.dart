import 'package:flutter/material.dart';

class EventStatus {
  static const pending = 'Pending';
  static const confirmed = 'Confirmed';
  static const cancelled = 'Cancelled';
  static const completed = 'Completed';
  static const postponed = 'Postponed';

  static String displayLabel(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();
    switch (status) {
      case 'pending':
        return pending;
      case 'published':
      case 'active':
      case 'confirmed':
        return confirmed;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      case 'completed':
      case 'finished':
        return completed;
      case 'postponed':
        return postponed;
      default:
        return pending;
    }
  }

  static Color displayColor(String displayStatus) {
    switch (displayStatus) {
      case pending:
        return Colors.orange;
      case confirmed:
        return const Color(0xFF43A047); // Green
      case cancelled:
        return Colors.red;
      case completed:
        return Colors.blue;
      case postponed:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static bool canViewReservations(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    return normalized == 'published' ||
        normalized == 'active' ||
        normalized == 'confirmed' ||
        normalized == 'completed' ||
        normalized == 'pending';
  }
}
