import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/items/domain/models.dart';
import 'package:j_life/features/statistics/domain/statistics.dart';

void main() {
  test('summary separates planned and confirmed cash flow', () {
    final items = [
      LifeItem(
        id: 'salary',
        title: '월급',
        category: '돈',
        dueAt: DateTime(2026, 9, 25),
        amount: 3000000,
        moneyFlow: MoneyFlow.income,
      ),
      LifeItem(
        id: 'subscription',
        title: '구독',
        category: '구독',
        dueAt: DateTime(2026, 9, 10),
        amount: 12000,
        moneyFlow: MoneyFlow.expense,
      ),
      LifeItem(
        id: 'filter',
        title: '필터 청소',
        category: '집',
        dueAt: DateTime(2026, 9, 12),
      ),
    ];
    final histories = [
      LifeHistory(
        id: 'h1',
        lifeItemId: 'subscription',
        titleSnapshot: '구독',
        categorySnapshot: '구독',
        completedAt: DateTime(2026, 9, 10),
        amountSnapshot: 12000,
        moneyFlowSnapshot: MoneyFlow.expense,
      ),
    ];

    final result = buildMonthlySummary(items, histories, DateTime(2026, 9));

    expect(result.plannedIncome, 3000000);
    expect(result.plannedExpense, 12000);
    expect(result.confirmedExpense, 12000);
    expect(result.plannedBalance, 2988000);
  });

  test('history keeps its amount snapshot after item amount changes', () {
    final history = LifeHistory(
      id: 'h1',
      lifeItemId: 'item',
      titleSnapshot: '보험',
      categorySnapshot: '돈',
      completedAt: DateTime(2026, 9, 2),
      amountSnapshot: 50000,
      moneyFlowSnapshot: MoneyFlow.expense,
    );
    final changedItem = LifeItem(
      id: 'item',
      title: '보험',
      category: '돈',
      dueAt: DateTime(2026, 10, 2),
      amount: 70000,
      moneyFlow: MoneyFlow.expense,
    );

    final result = buildMonthlySummary(
      [changedItem],
      [history],
      DateTime(2026, 9),
    );
    expect(result.confirmedExpense, 50000);
  });
}
