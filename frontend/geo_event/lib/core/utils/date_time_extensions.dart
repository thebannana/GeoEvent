import 'package:intl/intl.dart';

DateTime parseApiDateTime(dynamic value) {
  final raw = value?.toString().trim();

  if (raw == null || raw.isEmpty) {
    throw const FormatException('Invalid datetime value');
  }

  final hasExplicitZone =
      raw.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);

  final normalized = hasExplicitZone ? raw : '${raw}Z';

  final parsed = DateTime.parse(normalized);

  return parsed.isUtc ? parsed : parsed.toUtc();
}

extension DateTimeExtensions on DateTime {
  DateTime get local => toLocal();

  DateTime get utc => isUtc ? this : toUtc();

  DateTime get dateOnly {
    final value = local;
    return DateTime(value.year, value.month, value.day);
  }

  bool get isToday {
    final value = local;
    final now = DateTime.now();

    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  bool get isTomorrow {
    final value = local;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    return value.year == tomorrow.year &&
        value.month == tomorrow.month &&
        value.day == tomorrow.day;
  }

  bool get isYesterday {
    final value = local;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    return value.year == yesterday.year &&
        value.month == yesterday.month &&
        value.day == yesterday.day;
  }

bool get isPast {
  return toUtc().isBefore(
    DateTime.now().toUtc(),
  );
}

bool get isFuture {
  return toUtc().isAfter(
    DateTime.now().toUtc(),
  );
}

  bool isSameDate(DateTime other) {
    final a = local;
    final b = other.local;

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool isSameMinute(DateTime other) {
    final a = local;
    final b = other.local;

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
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
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (isYesterday) return 'Yesterday';

    return DateFormat('EEE, dd MMM').format(local);
  }

String formatEventDateTime() {
  final value = toUtc().toLocal();
  final now = DateTime.now();

  final sameDay = value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;

  final tomorrow = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));

  final yesterday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 1));

  final isTomorrowDate = value.year == tomorrow.year &&
      value.month == tomorrow.month &&
      value.day == tomorrow.day;

  final isYesterdayDate = value.year == yesterday.year &&
      value.month == yesterday.month &&
      value.day == yesterday.day;

  if (sameDay) {
    return 'Today • ${DateFormat('HH:mm').format(value)}';
  }

  if (isTomorrowDate) {
    return 'Tomorrow • ${DateFormat('HH:mm').format(value)}';
  }

  if (isYesterdayDate) {
    return 'Yesterday • ${DateFormat('HH:mm').format(value)}';
  }

  return DateFormat(
    'EEE, dd MMM • HH:mm',
  ).format(value);
}

  String timeAgo({bool short = false}) {
    final difference = DateTime.now().toUtc().difference(utc);

    if (difference.inSeconds < 0) {
      return until(short: short);
    }

    if (difference.inSeconds < 60) {
      return short ? 'now' : 'just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return short
          ? '${minutes}m'
          : '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return short
          ? '${hours}h'
          : '$hours hour${hours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;
      return short
          ? '${days}d'
          : '$days day${days == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return short
          ? '${weeks}w'
          : '$weeks week${weeks == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return short
          ? '${months}mo'
          : '$months month${months == 1 ? '' : 's'} ago';
    }

    final years = (difference.inDays / 365).floor();

    return short
        ? '${years}y'
        : '$years year${years == 1 ? '' : 's'} ago';
  }

  String until({bool short = false}) {
    final difference = utc.difference(DateTime.now().toUtc());

    if (difference.inSeconds <= 0) {
      return 'now';
    }

    if (difference.inMinutes < 1) {
      final seconds = difference.inSeconds;
      return short
          ? '${seconds}s'
          : 'in $seconds second${seconds == 1 ? '' : 's'}';
    }

    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return short
          ? '${minutes}m'
          : 'in $minutes minute${minutes == 1 ? '' : 's'}';
    }

    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return short
          ? '${hours}h'
          : 'in $hours hour${hours == 1 ? '' : 's'}';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;
      return short
          ? '${days}d'
          : 'in $days day${days == 1 ? '' : 's'}';
    }

    return formatEventDateTime();
  }

  Duration differenceFrom(DateTime other) {
    return utc.difference(other.utc);
  }
}