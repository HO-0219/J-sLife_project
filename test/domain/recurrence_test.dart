import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/items/domain/models.dart';
import 'package:j_life/features/items/domain/recurrence.dart';

void main() {
  test('monthly recurrence clamps to the last day of a shorter month', () {
    final next = calculateNextDue(
      DateTime(2026, 1, 31),
      const RepeatRule(type: RepeatType.monthly, interval: 1),
    );
    expect(next, DateTime(2026, 2, 28));
  });

  test('yearly recurrence clamps leap day to February 28', () {
    final next = calculateNextDue(
      DateTime(2024, 2, 29),
      const RepeatRule(type: RepeatType.yearly, interval: 1),
    );
    expect(next, DateTime(2025, 2, 28));
  });

  test('non repeating item has no next due date', () {
    expect(
      calculateNextDue(
        DateTime(2026, 9, 26),
        const RepeatRule(type: RepeatType.none),
      ),
      isNull,
    );
  });
}
