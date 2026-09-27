import '../../items/domain/models.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.plannedIncome,
    required this.plannedExpense,
    required this.confirmedIncome,
    required this.confirmedExpense,
    required this.expenseByCategory,
  });

  final int plannedIncome;
  final int plannedExpense;
  final int confirmedIncome;
  final int confirmedExpense;
  final Map<String, int> expenseByCategory;

  int get plannedBalance => plannedIncome - plannedExpense;
}

MonthlySummary buildMonthlySummary(
  List<LifeItem> items,
  List<LifeHistory> histories,
  DateTime month,
) {
  var plannedIncome = 0;
  var plannedExpense = 0;
  var confirmedIncome = 0;
  var confirmedExpense = 0;
  final byCategory = <String, int>{};

  bool inMonth(DateTime date) =>
      date.year == month.year && date.month == month.month;

  for (final item in items.where((item) => inMonth(item.dueAt))) {
    final amount = item.amount;
    if (amount == null) continue;
    if (item.moneyFlow == MoneyFlow.income) plannedIncome += amount;
    if (item.moneyFlow == MoneyFlow.expense) plannedExpense += amount;
  }

  for (final history in histories.where((h) => inMonth(h.completedAt))) {
    final amount = history.amountSnapshot;
    if (amount == null) continue;
    if (history.moneyFlowSnapshot == MoneyFlow.income) {
      confirmedIncome += amount;
    }
    if (history.moneyFlowSnapshot == MoneyFlow.expense) {
      confirmedExpense += amount;
      byCategory.update(
        history.categorySnapshot,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }
  }

  return MonthlySummary(
    plannedIncome: plannedIncome,
    plannedExpense: plannedExpense,
    confirmedIncome: confirmedIncome,
    confirmedExpense: confirmedExpense,
    expenseByCategory: byCategory,
  );
}
