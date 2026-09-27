import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/items/data/memory_life_repository.dart';
import 'package:j_life/features/items/domain/models.dart';

void main() {
  group('MemoryLifeRepository', () {
    test('saves, updates, and deletes items', () async {
      final repository = MemoryLifeRepository();
      final item = LifeItem(
        id: 'filter',
        title: '필터 청소',
        category: '집',
        dueAt: DateTime(2026, 9, 27),
      );

      await repository.saveItem(item);
      expect(repository.items, [item]);

      final updated = item.copyWith(dueAt: DateTime(2026, 10, 27));
      await repository.saveItem(updated);
      expect(repository.items, [updated]);

      await repository.deleteItem(item.id);
      expect(repository.items, isEmpty);
    });

    test('completion snapshots money and advances a repeating item', () async {
      final repository = MemoryLifeRepository();
      final item = LifeItem(
        id: 'insurance',
        title: '자동차 보험',
        category: '차량',
        dueAt: DateTime(2026, 9, 30),
        repeatRule: const RepeatRule(type: RepeatType.yearly),
        amount: 500000,
        moneyFlow: MoneyFlow.expense,
      );
      await repository.saveItem(item);

      await repository.completeItem(item.id, DateTime(2026, 10, 2));

      expect(repository.histories, hasLength(1));
      expect(repository.histories.single.amountSnapshot, 500000);
      expect(repository.histories.single.moneyFlowSnapshot, MoneyFlow.expense);
      expect(repository.items.single.dueAt, DateTime(2027, 10, 2));
    });

    test(
      'completion removes a non-repeating item but keeps its history',
      () async {
        final repository = MemoryLifeRepository();
        await repository.saveItem(
          LifeItem(
            id: 'return',
            title: '반품 마감',
            category: '구매',
            dueAt: DateTime(2026, 9, 27),
          ),
        );

        await repository.completeItem('return', DateTime(2026, 9, 27));

        expect(repository.items, isEmpty);
        expect(repository.histories.single.titleSnapshot, '반품 마감');
      },
    );
  });
}
