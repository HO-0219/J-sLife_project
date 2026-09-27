enum MoneyFlow { none, income, expense }

enum RepeatType { none, daily, weekly, monthly, yearly }

class RepeatRule {
  const RepeatRule({required this.type, this.interval = 1});

  final RepeatType type;
  final int interval;

  Map<String, Object> toJson() => {'type': type.name, 'interval': interval};

  factory RepeatRule.fromJson(Map<String, Object?> json) => RepeatRule(
    type: RepeatType.values.byName(json['type']! as String),
    interval: json['interval'] as int? ?? 1,
  );
}

class LifeItem {
  LifeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dueAt,
    this.repeatRule = const RepeatRule(type: RepeatType.none),
    this.reminderDaysBefore = 1,
    this.memo = '',
    this.amount,
    this.moneyFlow = MoneyFlow.none,
  });

  final String id;
  final String title;
  final String category;
  final DateTime dueAt;
  final RepeatRule repeatRule;
  final int reminderDaysBefore;
  final String memo;
  final int? amount;
  final MoneyFlow moneyFlow;

  LifeItem copyWith({
    String? title,
    String? category,
    DateTime? dueAt,
    RepeatRule? repeatRule,
    int? reminderDaysBefore,
    String? memo,
    int? amount,
    MoneyFlow? moneyFlow,
    bool clearAmount = false,
  }) => LifeItem(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    dueAt: dueAt ?? this.dueAt,
    repeatRule: repeatRule ?? this.repeatRule,
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    memo: memo ?? this.memo,
    amount: clearAmount ? null : amount ?? this.amount,
    moneyFlow: moneyFlow ?? this.moneyFlow,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'dueAt': dueAt.toIso8601String(),
    'repeatRule': repeatRule.toJson(),
    'reminderDaysBefore': reminderDaysBefore,
    'memo': memo,
    'amount': amount,
    'moneyFlow': moneyFlow.name,
  };

  factory LifeItem.fromJson(Map<String, Object?> json) => LifeItem(
    id: json['id']! as String,
    title: json['title']! as String,
    category: json['category']! as String,
    dueAt: DateTime.parse(json['dueAt']! as String),
    repeatRule: RepeatRule.fromJson(
      (json['repeatRule']! as Map).cast<String, Object?>(),
    ),
    reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 1,
    memo: json['memo'] as String? ?? '',
    amount: json['amount'] as int?,
    moneyFlow: MoneyFlow.values.byName(
      json['moneyFlow'] as String? ?? MoneyFlow.none.name,
    ),
  );
}

class LifeHistory {
  LifeHistory({
    required this.id,
    required this.lifeItemId,
    required this.titleSnapshot,
    required this.categorySnapshot,
    required this.completedAt,
    this.amountSnapshot,
    this.moneyFlowSnapshot = MoneyFlow.none,
  });

  final String id;
  final String lifeItemId;
  final String titleSnapshot;
  final String categorySnapshot;
  final DateTime completedAt;
  final int? amountSnapshot;
  final MoneyFlow moneyFlowSnapshot;

  Map<String, Object?> toJson() => {
    'id': id,
    'lifeItemId': lifeItemId,
    'titleSnapshot': titleSnapshot,
    'categorySnapshot': categorySnapshot,
    'completedAt': completedAt.toIso8601String(),
    'amountSnapshot': amountSnapshot,
    'moneyFlowSnapshot': moneyFlowSnapshot.name,
  };

  factory LifeHistory.fromJson(Map<String, Object?> json) => LifeHistory(
    id: json['id']! as String,
    lifeItemId: json['lifeItemId']! as String,
    titleSnapshot: json['titleSnapshot']! as String,
    categorySnapshot: json['categorySnapshot']! as String,
    completedAt: DateTime.parse(json['completedAt']! as String),
    amountSnapshot: json['amountSnapshot'] as int?,
    moneyFlowSnapshot: MoneyFlow.values.byName(
      json['moneyFlowSnapshot'] as String? ?? MoneyFlow.none.name,
    ),
  );
}
