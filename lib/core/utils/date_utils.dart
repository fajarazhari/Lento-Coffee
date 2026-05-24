import 'package:intl/intl.dart';

abstract class AppDateUtils {
  static final _displayFormat  = DateFormat('MMM dd, yyyy', 'en_US');
  static final _timeFormat     = DateFormat('hh:mm a', 'en_US');
  static final _time24Format   = DateFormat('HH:mm', 'en_US');
  static final _fullFormat     = DateFormat('MMM dd, yyyy • hh:mm a', 'en_US');
  static final _isoFormat      = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  static final _shortDate      = DateFormat('dd MMM', 'en_US');
  static final _dayOfWeek      = DateFormat('EEEE', 'en_US');

  static String toDisplay(DateTime dt) => _displayFormat.format(dt).toUpperCase();
  static String toTime(DateTime dt)    => _timeFormat.format(dt).toUpperCase();
  static String toTime24(DateTime dt)  => _time24Format.format(dt);
  static String toFull(DateTime dt)    => _fullFormat.format(dt).toUpperCase();
  static String toShort(DateTime dt)   => _shortDate.format(dt).toUpperCase();
  static String toDayOfWeek(DateTime dt) => _dayOfWeek.format(dt);

  /// Relative label: "Today", "Yesterday", or date string
  static String toRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return toDisplay(dt);
  }

  /// Human-readable elapsed time: "3 min ago", "2h ago"
  static String toElapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return toDisplay(dt);
  }

  /// Remaining time countdown from now to [target]
  static String toCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final mins = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
}
