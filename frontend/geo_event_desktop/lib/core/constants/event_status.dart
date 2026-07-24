import 'package:flutter/material.dart';

class EventStatus {
  const EventStatus._();

  static const pending = 'Pending';
  static const confirmed = 'Confirmed';
  static const cancelled = 'Cancelled';
  static const completed = 'Completed';
  static const unknown = 'Unknown';

  static String normalize(String? rawStatus) {
    final status = rawStatus?.trim().toLowerCase() ?? '';

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
        return unknown;
    }
  }

  static String displayLabel(String? rawStatus) => normalize(rawStatus);

  static Color displayColor(String? rawStatus) {
    switch (normalize(rawStatus)) {
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

  static bool canViewReservations(String? rawStatus) {
    final normalized = normalize(rawStatus);
    return normalized == pending ||
        normalized == confirmed ||
        normalized == completed;
  }

  static bool isPending(String? rawStatus) => normalize(rawStatus) == pending;

  static bool isConfirmed(String? rawStatus) =>
      normalize(rawStatus) == confirmed;

  static bool isCancelled(String? rawStatus) =>
      normalize(rawStatus) == cancelled;

  static bool isCompleted(String? rawStatus) =>
      normalize(rawStatus) == completed;
}