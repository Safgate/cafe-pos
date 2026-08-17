import 'package:equatable/equatable.dart';

/// A half-open span of local time: [from] inclusive, [to] exclusive.
///
/// Everything here works in **local time**, deliberately. An 11pm sale belongs
/// to that day's takings, not to the next day in UTC.
///
/// Day arithmetic goes through the `DateTime(y, m, d + n)` constructor rather
/// than `add(Duration(days: n))`. Adding a duration adds exactly 24 hours,
/// which lands on 23:00 or 01:00 across a daylight-saving change; the
/// constructor normalises to real local midnight either way.
class DateRange extends Equatable {
  final DateTime from;
  final DateTime to;
  final String label;

  const DateRange({
    required this.from,
    required this.to,
    required this.label,
  });

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime nextDay(DateTime date) =>
      DateTime(date.year, date.month, date.day + 1);

  factory DateRange.today([DateTime? now]) {
    final start = startOfDay(now ?? DateTime.now());
    return DateRange(from: start, to: nextDay(start), label: 'Today');
  }

  /// A single named day, used by the dashboard's bar-chart drill-down.
  factory DateRange.day(DateTime date) {
    final start = startOfDay(date);
    return DateRange(
      from: start,
      to: nextDay(start),
      label: '${start.day}/${start.month}/${start.year}',
    );
  }

  /// Monday to Sunday, containing [now].
  factory DateRange.thisWeek([DateTime? now]) {
    final today = startOfDay(now ?? DateTime.now());
    final monday =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return DateRange(
      from: monday,
      to: DateTime(monday.year, monday.month, monday.day + 7),
      label: 'This Week',
    );
  }

  /// The calendar month containing [now].
  factory DateRange.thisMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateRange(
      from: DateTime(n.year, n.month, 1),
      // Month 13 normalises to January of the next year.
      to: DateTime(n.year, n.month + 1, 1),
      label: 'This Month',
    );
  }

  factory DateRange.custom(DateTime from, DateTime to, {String? label}) {
    final start = startOfDay(from);
    final end = nextDay(startOfDay(to));
    return DateRange(
      from: start,
      to: end,
      label: label ?? 'Custom',
    );
  }

  bool contains(DateTime moment) =>
      !moment.isBefore(from) && moment.isBefore(to);

  /// Number of whole days the range covers.
  int get dayCount {
    var count = 0;
    var cursor = from;
    while (cursor.isBefore(to)) {
      count++;
      cursor = nextDay(cursor);
    }
    return count;
  }

  /// Local midnight for each day in the range — the buckets of the bar chart.
  List<DateTime> get days {
    final result = <DateTime>[];
    var cursor = from;
    while (cursor.isBefore(to)) {
      result.add(cursor);
      cursor = nextDay(cursor);
    }
    return result;
  }

  @override
  List<Object?> get props => [from, to, label];
}
