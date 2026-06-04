class DateRange {
  final DateTime start;
  final DateTime end;
  final DateRangeType type;

  /// [start] is inclusive (midnight of the first day).
  /// [end] is exclusive (midnight of the day after the last day).
  /// SQL queries should use: `>= start AND < end`.
  const DateRange._({
    required this.start,
    required this.end,
    required this.type,
  });

  factory DateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    return DateRange._(start: start, end: end, type: DateRangeType.today);
  }

  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = DateTime(now.year, now.month, now.day - weekday + 1);
    final end = DateTime(now.year, now.month, now.day - weekday + 8);
    return DateRange._(start: start, end: end, type: DateRangeType.thisWeek);
  }

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return DateRange._(start: start, end: end, type: DateRangeType.thisMonth);
  }

  factory DateRange.thisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year + 1, 1, 1);
    return DateRange._(start: start, end: end, type: DateRangeType.thisYear);
  }

  factory DateRange.allTime() {
    return DateRange._(
      start: DateTime(2000),
      end: DateTime(2100, 1, 1),
      type: DateRangeType.allTime,
    );
  }

  factory DateRange.custom(DateTime start, DateTime end) {
    assert(
      start.isBefore(end) || start.isAtSameMomentAs(end),
      'start must be <= end',
    );
    return DateRange._(start: start, end: end, type: DateRangeType.custom);
  }

  String get label => switch (type) {
    DateRangeType.today => 'اليوم',
    DateRangeType.thisWeek => 'هذا الأسبوع',
    DateRangeType.thisMonth => 'هذا الشهر',
    DateRangeType.thisYear => 'هذا العام',
    DateRangeType.allTime => 'الكل',
    DateRangeType.custom => 'مخصص',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          start == other.start &&
          end == other.end &&
          type == other.type;

  @override
  int get hashCode => Object.hash(start, end, type);
}

enum DateRangeType {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
  custom,
}
