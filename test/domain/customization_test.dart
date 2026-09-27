import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/customization/domain/dashboard_config.dart';

void main() {
  test('money preset prioritizes cash flow cards', () {
    final config = DashboardConfig.fromPreset(DashboardPreset.money);
    expect(config.visibleCards.first, DashboardCardType.moneySummary);
    expect(config.visibleCards, contains(DashboardCardType.upcoming));
  });

  test('card visibility and order are customizable', () {
    final config = DashboardConfig.fromPreset(DashboardPreset.basic)
        .toggle(DashboardCardType.history)
        .move(2, 0);
    expect(config.visibleCards.first, DashboardCardType.moneySummary);
    expect(config.visibleCards, isNot(contains(DashboardCardType.history)));
  });
}
