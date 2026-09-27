enum DashboardPreset { basic, money, car, home }

enum DashboardCardType { today, upcoming, moneySummary, categoryChart, history }

class DashboardConfig {
  const DashboardConfig({required this.cards, required this.hiddenCards});

  final List<DashboardCardType> cards;
  final Set<DashboardCardType> hiddenCards;

  List<DashboardCardType> get visibleCards =>
      cards.where((card) => !hiddenCards.contains(card)).toList();

  factory DashboardConfig.fromPreset(DashboardPreset preset) {
    final cards = switch (preset) {
      DashboardPreset.money => [
        DashboardCardType.moneySummary,
        DashboardCardType.upcoming,
        DashboardCardType.categoryChart,
        DashboardCardType.today,
        DashboardCardType.history,
      ],
      DashboardPreset.car => [
        DashboardCardType.upcoming,
        DashboardCardType.today,
        DashboardCardType.history,
        DashboardCardType.moneySummary,
        DashboardCardType.categoryChart,
      ],
      DashboardPreset.home => [
        DashboardCardType.today,
        DashboardCardType.upcoming,
        DashboardCardType.history,
        DashboardCardType.moneySummary,
        DashboardCardType.categoryChart,
      ],
      DashboardPreset.basic => [
        DashboardCardType.today,
        DashboardCardType.upcoming,
        DashboardCardType.moneySummary,
        DashboardCardType.categoryChart,
        DashboardCardType.history,
      ],
    };
    return DashboardConfig(cards: cards, hiddenCards: const {});
  }

  DashboardConfig toggle(DashboardCardType card) {
    final hidden = {...hiddenCards};
    hidden.contains(card) ? hidden.remove(card) : hidden.add(card);
    return DashboardConfig(cards: cards, hiddenCards: hidden);
  }

  DashboardConfig move(int oldIndex, int newIndex) {
    final reordered = [...cards];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    return DashboardConfig(cards: reordered, hiddenCards: hiddenCards);
  }

  Map<String, Object> toJson() => {
    'cards': cards.map((card) => card.name).toList(),
    'hiddenCards': hiddenCards.map((card) => card.name).toList(),
  };

  factory DashboardConfig.fromJson(Map<String, Object?> json) =>
      DashboardConfig(
        cards: (json['cards']! as List)
            .cast<String>()
            .map(DashboardCardType.values.byName)
            .toList(),
        hiddenCards: (json['hiddenCards'] as List? ?? const [])
            .cast<String>()
            .map(DashboardCardType.values.byName)
            .toSet(),
      );
}
