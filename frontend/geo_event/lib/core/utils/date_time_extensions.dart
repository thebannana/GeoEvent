import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isPast => isBefore(DateTime.now());

  bool get isFuture => isAfter(DateTime.now());

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isSameMinute(DateTime other) {
    return year == other.year &&
        month == other.month &&
        day == other.day &&
        hour == other.hour &&
        minute == other.minute;
  }

  String formatDate({
    String pattern = 'dd MMM yyyy',
  }) {
    return DateFormat(pattern).format(toLocal());
  }

  String formatTime({
    String pattern = 'HH:mm',
  }) {
    return DateFormat(pattern).format(toLocal());
  }

  String formatDateTime({
    String pattern = 'dd MMM yyyy, HH:mm',
  }) {
    return DateFormat(pattern).format(toLocal());
  }

  String formatEventDate() {
    if (isToday) {
      return 'Today';
    }

    if (isTomorrow) {
      return 'Tomorrow';
    }

    if (isYesterday) {
      return 'Yesterday';
    }

    return DateFormat('EEE, dd MMM').format(toLocal());
  }

  String formatEventDateTime() {
    final local = toLocal();

    if (isToday) {
      return 'Today • ${DateFormat('HH:mm').format(local)}';
    }

    if (isTomorrow) {
      return 'Tomorrow • ${DateFormat('HH:mm').format(local)}';
    }

    return DateFormat('EEE, dd MMM • HH:mm').format(local);
  }

  String timeAgo({
    bool short = false,
  }) {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 0) {
      return short ? 'now' : 'just now';
    }

    if (difference.inSeconds < 60) {
      return short ? 'now' : 'just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (short) return '${minutes}m';
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (short) return '${hours}h';
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;
      if (short) return '${days}d';
      return '$days day${days == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (short) return '${weeks}w';
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (short) return '${months}mo';
      return '$months month${months == 1 ? '' : 's'} ago';
    }

    final years = (difference.inDays / 365).floor();
    if (short) return '${years}y';
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  String until({
    bool short = false,
  }) {
    final now = DateTime.now();
    final difference = differenceFrom(now);

    if (difference.inSeconds <= 0) {
      return short ? 'now' : 'now';
    }

    if (difference.inMinutes < 1) {
      final seconds = difference.inSeconds;
      if (short) return '${seconds}s';
      return 'in $seconds second${seconds == 1 ? '' : 's'}';
    }

    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      if (short) return '${minutes}m';
      return 'in $minutes minute${minutes == 1 ? '' : 's'}';
    }

    if (difference.inDays < 1) {
      final hours = difference.inHours;
      if (short) return '${hours}h';
      return 'in $hours hour${hours == 1 ? '' : 's'}';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;
      if (short) return '${days}d';
      return 'in $days day${days == 1 ? '' : 's'}';
    }

    return formatEventDateTime();
  }

  Duration differenceFrom(DateTime other) {
    return toLocal().difference(other.toLocal());
  }
}