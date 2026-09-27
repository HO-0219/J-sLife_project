import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/items/data/persistent_life_repository.dart';
import 'package:j_life/features/items/domain/models.dart';

class _MemoryStringStore implements StringStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('items and immutable completion snapshots survive reload', () async {
    final store = _MemoryStringStore();
    final repository = await PersistentLifeRepository.create(store);
    await repository.saveItem(
      LifeItem(
        id: 'insurance',
        title: '보험 갱신',
        category: '돈',
        dueAt: DateTime(2026, 9, 27),
        amount: 50000,
        moneyFlow: MoneyFlow.expense,
        repeatRule: const RepeatRule(type: RepeatType.yearly),
      ),
    );
    await repository.completeItem('insurance', DateTime(2026, 9, 28));

    final restored = await PersistentLifeRepository.create(store);

    expect(restored.currentItems.single.dueAt, DateTime(2027, 9, 28));
    expect(restored.currentHistories.single.amountSnapshot, 50000);
    expect(restored.currentHistories.single.titleSnapshot, '보험 갱신');
  });
}
