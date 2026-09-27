import 'models.dart';

DateTime? calculateNextDue(DateTime completedAt, RepeatRule rule) {
  if (rule.type == RepeatType.none) return null;
  final interval = rule.interval < 1 ? 1 : rule.interval;
  switch (rule.type) {
    case RepeatType.daily:
      return completedAt.add(Duration(days: interval));
    case RepeatType.weekly:
      return completedAt.add(Duration(days: interval * 7));
    case RepeatType.monthly:
      return _addMonths(completedAt, interval);
    case RepeatType.yearly:
      return _safeDate(
        completedAt.year + interval,
        completedAt.month,
        completedAt.day,
      );
    case RepeatType.none:
      return null;
  }
}

DateTime _addMonths(DateTime date, int count) {
  final totalMonths = date.year * 12 + date.month - 1 + count;
  return _safeDate(totalMonths ~/ 12, totalMonths % 12 + 1, date.day);
}

DateTime _safeDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}
