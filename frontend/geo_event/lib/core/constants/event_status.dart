import 'package:flutter/material.dart';

class EventStatus {
  static const pending = 'Pending';
  static const confirmed = 'Confirmed';
  static const cancelled = 'Cancelled';
  static const completed = 'Completed';

  static String displayLabel(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();

    switch (status) {
      case 'pending':
        return pending;
      case 'confirmed':
        return confirmed;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      case 'completed':
        return completed;
      default:
        return pending;
    }
  }

  static Color displayColor(String displayStatus) {
    switch (displayStatus.trim()) {
      case pending:
        return Colors.orange;
      case confirmed:
        return const Color(0xFF43A047);
      case cancelled:
        return Colors.red;
      case completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  static bool canViewReservations(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();

    return normalized == 'pending' ||
        normalized == 'confirmed' ||
        normalized == 'completed';
  }

  static bool isPending(String rawStatus) {
    return rawStatus.trim().toLowerCase() == 'pending';
  }

  static bool isConfirmed(String rawStatus) {
    return rawStatus.trim().toLowerCase() == 'confirmed';
  }

  static bool isCancelled(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    return normalized == 'cancelled' || normalized == 'canceled';
  }

  static bool isCompleted(String rawStatus) {
    return rawStatus.trim().toLowerCase() == 'completed';
  }
}