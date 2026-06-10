import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  DateTime get local => toLocal();

  DateTime get dateOnly {
    final value = local;
    return DateTime(value.year, value.month, value.day);
  }

  bool get isToday {
    final now = DateTime.now();
    final value = local;
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final value = local;
    return value.year == tomorrow.year &&
        value.month == tomorrow.month &&
        value.day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final value = local;
    return value.year == yesterday.year &&
        value.month == yesterday.month &&
        value.day == yesterday.day;
  }

  bool get isPast => local.isBefore(DateTime.now());
  bool get isFuture => local.isAfter(DateTime.now());

  bool isSameDate(DateTime other) {
    final a = local;
    final b = other.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isSameMinute(DateTime other) {
    final a = local;
    final b = other.toLocal();
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  String formatDate({String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern).format(local);
  }

  String formatTime({String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(local);
  }

  String formatDateTime({String pattern = 'dd MMM yyyy, HH:mm'}) {
    return DateFormat(pattern).format(local);
  }

  String formatEventDate() {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (isYesterday) return 'Yesterday';
    return DateFormat('EEE, dd MMM').format(local);
  }

  String formatEventDateTime() {
    if (isToday) {
      return 'Today • ${DateFormat('HH:mm').format(local)}';
    }

    if (isTomorrow) {
      return 'Tomorrow • ${DateFormat('HH:mm').format(local)}';
    }

    return DateFormat('EEE, dd MMM • HH:mm').format(local);
  }

  String timeAgo({bool short = false}) {
    final difference = DateTime.now().difference(local);

    if (difference.inSeconds < 60) {
      return short ? 'now' : 'just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return short ? '${minutes}m' : '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return short ? '${hours}h' : '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return short ? '${days}d' : '$days day${days == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return short ? '${weeks}w' : '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return short ? '${months}mo' : '$months month${months == 1 ? '' : 's'} ago';
    }

    final years = (difference.inDays / 365).floor();
    return short ? '${years}y' : '$years year${years == 1 ? '' : 's'} ago';
  }

  String until({bool short = false}) {
    final difference = local.difference(DateTime.now());

    if (difference.inSeconds <= 0) return 'now';
    if (difference.inMinutes < 1) {
      final seconds = difference.inSeconds;
      return short ? '${seconds}s' : 'in $seconds second${seconds == 1 ? '' : 's'}';
    }
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return short ? '${minutes}m' : 'in $minutes minute${minutes == 1 ? '' : 's'}';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return short ? '${hours}h' : 'in $hours hour${hours == 1 ? '' : 's'}';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return short ? '${days}d' : 'in $days day${days == 1 ? '' : 's'}';
    }

    return formatEventDateTime();
  }

  Duration differenceFrom(DateTime other) {
    return local.difference(other.toLocal());
  }
}