import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'features/customization/domain/dashboard_config.dart';
import 'features/items/application/life_controller.dart';
import 'features/items/application/notification_service.dart';
import 'features/items/data/life_repository.dart';
import 'features/items/data/memory_life_repository.dart';
import 'features/items/domain/models.dart';
import 'features/monetization/domain/monetization.dart';
import 'features/statistics/domain/statistics.dart';

class JLifeApp extends StatelessWidget {
  const JLifeApp({
    super.key,
    this.repository,
    this.notifications,
    this.initialDashboardConfig,
    this.onDashboardConfigChanged,
    this.startupWarning,
  });
  final LifeRepository? repository;
  final LifeNotificationService? notifications;
  final DashboardConfig? initialDashboardConfig;
  final ValueChanged<DashboardConfig>? onDashboardConfigChanged;
  final String? startupWarning;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'J의 삶',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF315C4C),
        surface: const Color(0xFFF8FAF7),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7F3),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: _AppShell(
      repository: repository,
      notifications: notifications,
      initialDashboardConfig: initialDashboardConfig,
      onDashboardConfigChanged: onDashboardConfigChanged,
      startupWarning: startupWarning,
    ),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell({
    this.repository,
    this.notifications,
    this.initialDashboardConfig,
    this.onDashboardConfigChanged,
    this.startupWarning,
  });
  final LifeRepository? repository;
  final LifeNotificationService? notifications;
  final DashboardConfig? initialDashboardConfig;
  final ValueChanged<DashboardConfig>? onDashboardConfigChanged;
  final String? startupWarning;
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _index = 0;
  Tier _tier = Tier.free;
  late DashboardConfig _config;
  late final LifeController _lifeController;

  @override
  void initState() {
    super.initState();
    _config =
        widget.initialDashboardConfig ??
        DashboardConfig.fromPreset(DashboardPreset.basic);
    _lifeController = LifeController(
      widget.repository ??
          MemoryLifeRepository(
            initialItems: [
              LifeItem(
                id: 'salary',
                title: '월급',
                category: '돈',
                dueAt: DateTime.now().add(const Duration(days: 3)),
                repeatRule: const RepeatRule(type: RepeatType.monthly),
                amount: 3200000,
                moneyFlow: MoneyFlow.income,
              ),
              LifeItem(
                id: 'subscription',
                title: '영상 구독 갱신',
                category: '구독',
                dueAt: DateTime.now().add(const Duration(days: 5)),
                repeatRule: const RepeatRule(type: RepeatType.monthly),
                amount: 17000,
                moneyFlow: MoneyFlow.expense,
              ),
              LifeItem(
                id: 'filter',
                title: '에어컨 필터 청소',
                category: '집',
                dueAt: DateTime.now(),
                repeatRule: const RepeatRule(
                  type: RepeatType.monthly,
                  interval: 3,
                ),
              ),
            ],
          ),
      notificationService: widget.notifications,
    );
  }

  void _complete(LifeItem item) =>
      _lifeController.completeItem(item.id, DateTime.now());

  Future<void> _openEditor([LifeItem? existing]) async {
    final item = await showModalBottomSheet<LifeItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ItemEditorSheet(existing: existing),
    );
    if (item != null) await _lifeController.saveItem(item);
  }

  Future<void> _openDetail(LifeItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.category} · ${_date(item.dueAt)} · ${_repeatName(item.repeatRule.type)}',
            ),
            if (item.memo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.memo),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _complete(item);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('완료'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _openEditor(item);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('수정'),
            ),
            TextButton.icon(
              onPressed: () async {
                final approved = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('항목을 삭제할까요?'),
                    content: const Text('완료 기록은 유지되고 예정 항목만 삭제됩니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (approved == true) {
                  await _lifeController.deleteItem(item.id);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('삭제'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final allowed = await widget.notifications?.requestPermission() ?? false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allowed ? '알림을 사용할 수 있어요.' : '알림 권한이 꺼져 있어요. 기기 설정에서 허용해 주세요.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lifeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LifeState>(
      valueListenable: _lifeController,
      builder: (context, life, _) {
        final screens = [
          _HomeScreen(
            items: life.items,
            histories: life.histories,
            config: _config,
            tier: _tier,
            onComplete: _complete,
          ),
          _ItemsScreen(
            items: life.items,
            onComplete: _complete,
            onOpen: _openDetail,
          ),
          _StatisticsScreen(items: life.items, histories: life.histories),
          _ManageScreen(
            tier: _tier,
            config: _config,
            histories: life.histories,
            onTierChanged: (v) => setState(() => _tier = v),
            onConfigChanged: (v) {
              setState(() => _config = v);
              widget.onDashboardConfigChanged?.call(v);
            },
          ),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'J의 삶',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: '알림 권한 설정',
                onPressed: _requestNotificationPermission,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              if (widget.startupWarning != null)
                MaterialBanner(
                  content: Text(widget.startupWarning!),
                  actions: const [SizedBox.shrink()],
                ),
              Expanded(
                child: IndexedStack(index: _index, children: screens),
              ),
            ],
          ),
          floatingActionButton: _index < 2
              ? FloatingActionButton.extended(
                  onPressed: _openEditor,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('추가'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_rounded),
                label: '항목',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_rounded),
                label: '관리',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.items,
    required this.histories,
    required this.config,
    required this.tier,
    required this.onComplete,
  });
  final List<LifeItem> items;
  final List<LifeHistory> histories;
  final DashboardConfig config;
  final Tier tier;
  final ValueChanged<LifeItem> onComplete;
  @override
  Widget build(BuildContext context) {
    final summary = buildMonthlySummary(items, histories, DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Text('안녕하세요', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          '오늘의 생활을 가볍게 정리해요.',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        ...config.visibleCards.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: switch (type) {
              DashboardCardType.today => _TodayCard(
                items: items,
                onComplete: onComplete,
              ),
              DashboardCardType.upcoming => _UpcomingCard(items: items),
              DashboardCardType.moneySummary => _MoneyCard(summary: summary),
              DashboardCardType.categoryChart => _CategoryCard(
                summary: summary,
              ),
              DashboardCardType.history => _HistoryCard(histories: histories),
            },
          ),
        ),
        if (tier == Tier.free) const _AdSlot(),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.trailing,
    required this.child,
  });
  final String title;
  final String trailing;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(trailing, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.items, required this.onComplete});
  final List<LifeItem> items;
  final ValueChanged<LifeItem> onComplete;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = items
        .where(
          (i) =>
              !i.dueAt.isAfter(DateTime(now.year, now.month, now.day, 23, 59)),
        )
        .toList();
    return _SectionCard(
      title: '오늘',
      trailing: '${today.length}개',
      child: today.isEmpty
          ? const Text('오늘 처리할 항목이 없어요.')
          : Column(
              children: today
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(item.category.characters.first),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.category),
                      trailing: FilledButton.tonal(
                        onPressed: () => onComplete(item),
                        child: const Text('완료'),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.items});
  final List<LifeItem> items;
  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return _SectionCard(
      title: '예정',
      trailing: '가까운 순',
      child: Column(
        children: sorted.take(3).map((item) {
          final days = item.dueAt.difference(DateTime.now()).inDays;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.title),
            subtitle: Text(item.category),
            trailing: Text(days <= 0 ? 'D-DAY' : 'D-$days'),
          );
        }).toList(),
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.summary});
  final MonthlySummary summary;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '이번 달 돈 흐름',
    trailing: '예정 기준',
    child: Row(
      children: [
        _MoneyValue(
          label: '받을 돈',
          value: summary.plannedIncome,
          positive: true,
        ),
        _MoneyValue(label: '나갈 돈', value: summary.plannedExpense),
        _MoneyValue(
          label: '예상 차액',
          value: summary.plannedBalance,
          positive: summary.plannedBalance >= 0,
        ),
      ],
    ),
  );
}

class _MoneyValue extends StatelessWidget {
  const _MoneyValue({
    required this.label,
    required this.value,
    this.positive = false,
  });
  final String label;
  final int value;
  final bool positive;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 5),
        Text(
          _won(value),
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: positive ? const Color(0xFF16785C) : null,
          ),
        ),
      ],
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.summary});
  final MonthlySummary summary;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '카테고리별 지출',
    trailing: '완료 기준',
    child: summary.expenseByCategory.isEmpty
        ? const Text('완료한 지출이 쌓이면 그래프가 나타나요.')
        : SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _BarPainter(summary.expenseByCategory),
              child: const SizedBox.expand(),
            ),
          ),
  );
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.values);
  final Map<String, int> values;
  @override
  void paint(Canvas canvas, Size size) {
    final maximum = values.values.fold<int>(1, math.max);
    final paint = Paint()..color = const Color(0xFF5D907B);
    final width = size.width / (values.length * 2);
    var x = width / 2;
    for (final value in values.values) {
      final height = size.height * value / maximum;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, width, height),
          const Radius.circular(8),
        ),
        paint,
      );
      x += width * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.histories});
  final List<LifeHistory> histories;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: '최근 완료',
    trailing: '${histories.length}개',
    child: histories.isEmpty
        ? const Text('완료 버튼을 누르면 기록이 여기에 쌓여요.')
        : Column(
            children: histories
                .take(3)
                .map(
                  (h) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_rounded),
                    title: Text(h.titleSnapshot),
                    subtitle: Text(_date(h.completedAt)),
                  ),
                )
                .toList(),
          ),
  );
}

class _ItemsScreen extends StatefulWidget {
  const _ItemsScreen({
    required this.items,
    required this.onComplete,
    required this.onOpen,
  });
  final List<LifeItem> items;
  final ValueChanged<LifeItem> onComplete;
  final ValueChanged<LifeItem> onOpen;
  @override
  State<_ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<_ItemsScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '등록한 항목이 없어요.\n아래 추가 버튼으로 첫 일정을 만들어 보세요.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final query = _query.trim().toLowerCase();
    final filtered = widget.items
        .where(
          (item) =>
              query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.memo.toLowerCase().contains(query),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: '이름, 카테고리, 메모 검색',
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('검색 결과가 없어요.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = filtered[index];
                    return Card(
                      child: ListTile(
                        onTap: () => widget.onOpen(item),
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          child: Text(item.category.characters.first),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${item.category} · ${_date(item.dueAt)}',
                        ),
                        trailing: IconButton.filledTonal(
                          tooltip: '완료',
                          onPressed: () => widget.onComplete(item),
                          icon: const Icon(Icons.check_rounded),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatisticsScreen extends StatelessWidget {
  const _StatisticsScreen({required this.items, required this.histories});
  final List<LifeItem> items;
  final List<LifeHistory> histories;
  @override
  Widget build(BuildContext context) {
    final summary = buildMonthlySummary(items, histories, DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Text(
          '이번 달',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('등록한 예정과 실제 완료 기록을 구분해서 보여드려요.'),
        const SizedBox(height: 20),
        _MoneyCard(summary: summary),
        const SizedBox(height: 14),
        _CategoryCard(summary: summary),
        const SizedBox(height: 14),
        _SectionCard(
          title: '확정 금액',
          trailing: '완료 기준',
          child: Row(
            children: [
              _MoneyValue(
                label: '받은 돈',
                value: summary.confirmedIncome,
                positive: true,
              ),
              _MoneyValue(label: '나간 돈', value: summary.confirmedExpense),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageScreen extends StatelessWidget {
  const _ManageScreen({
    required this.tier,
    required this.config,
    required this.histories,
    required this.onTierChanged,
    required this.onConfigChanged,
  });
  final Tier tier;
  final DashboardConfig config;
  final List<LifeHistory> histories;
  final ValueChanged<Tier> onTierChanged;
  final ValueChanged<DashboardConfig> onConfigChanged;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
    children: [
      Text(
        '내 방식대로',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text('홈에 필요한 정보만 남기고 순서를 바꿀 수 있어요.'),
      const SizedBox(height: 20),
      Card(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: config.cards.length,
          onReorderItem: (oldIndex, newIndex) =>
              onConfigChanged(config.move(oldIndex, newIndex)),
          itemBuilder: (_, index) {
            final card = config.cards[index];
            return SwitchListTile(
              key: ValueKey(card),
              value: !config.hiddenCards.contains(card),
              onChanged: (_) => onConfigChanged(config.toggle(card)),
              title: Text(_cardName(card)),
              secondary: const Icon(Icons.drag_handle_rounded),
            );
          },
        ),
      ),
      const SizedBox(height: 14),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              key: const Key('proPreviewSwitch'),
              value: tier == Tier.pro,
              onChanged: (v) => onTierChanged(v ? Tier.pro : Tier.free),
              title: const Text('PRO 화면 미리보기'),
              subtitle: const Text('광고 SDK와 결제 SDK는 아직 연결하지 않아요.'),
              secondary: const Icon(Icons.workspace_premium_outlined),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('전체 완료 기록'),
              subtitle: Text('${histories.length}개'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => _HistoryScreen(histories: histories),
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.category_outlined),
              title: Text('카테고리'),
              subtitle: Text('돈 · 구독 · 차량 · 집 · 식료품 · 개인 · 기타'),
            ),
            const ListTile(
              leading: Icon(Icons.backup_outlined),
              title: Text('백업 및 복원'),
              subtitle: Text('PRO 출시 단계에서 JSON/CSV로 제공 예정'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({this.existing});
  final LifeItem? existing;
  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _memo;
  late final TextEditingController _interval;
  String _category = '기타';
  MoneyFlow _flow = MoneyFlow.none;
  RepeatType _repeat = RepeatType.none;
  DateTime _due = DateTime.now();
  int _reminderDays = 1;
  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _amount = TextEditingController(text: item?.amount?.toString() ?? '');
    _memo = TextEditingController(text: item?.memo ?? '');
    _interval = TextEditingController(
      text: (item?.repeatRule.interval ?? 1).toString(),
    );
    _category = item?.category ?? '기타';
    _flow = item?.moneyFlow ?? MoneyFlow.none;
    _repeat = item?.repeatRule.type ?? RepeatType.none;
    _due = item?.dueAt ?? DateTime.now();
    _reminderDays = item?.reminderDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _memo.dispose();
    _interval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.existing == null ? '새 생활 항목' : '생활 항목 수정',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (widget.existing == null)
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('필터 청소'),
                  onPressed: () => setState(() {
                    _title.text = '필터 청소';
                    _category = '집';
                    _repeat = RepeatType.monthly;
                  }),
                ),
                ActionChip(
                  label: const Text('엔진오일'),
                  onPressed: () => setState(() {
                    _title.text = '엔진오일 교체';
                    _category = '차량';
                    _repeat = RepeatType.monthly;
                  }),
                ),
                ActionChip(
                  label: const Text('반품 마감'),
                  onPressed: () => setState(() {
                    _title.text = '반품 마감';
                    _category = '구매';
                    _repeat = RepeatType.none;
                  }),
                ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: '이름 *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: '카테고리'),
            items: [
              '돈',
              '구독',
              '차량',
              '집',
              '구매',
              '식료품',
              '개인',
              '기타',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('기준 날짜'),
            subtitle: Text(_date(_due)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final value = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: _due,
              );
              if (value != null) setState(() => _due = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RepeatType>(
            initialValue: _repeat,
            decoration: const InputDecoration(labelText: '반복'),
            items: RepeatType.values
                .map(
                  (v) =>
                      DropdownMenuItem(value: v, child: Text(_repeatName(v))),
                )
                .toList(),
            onChanged: (v) => setState(() => _repeat = v!),
          ),
          const SizedBox(height: 12),
          if (_repeat != RepeatType.none) ...[
            TextField(
              controller: _interval,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _repeat == RepeatType.daily
                    ? '몇 일마다'
                    : _repeat == RepeatType.weekly
                    ? '몇 주마다'
                    : _repeat == RepeatType.monthly
                    ? '몇 개월마다'
                    : '몇 년마다',
              ),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int>(
            initialValue: _reminderDays,
            decoration: const InputDecoration(labelText: '알림'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('당일 오전 9시')),
              DropdownMenuItem(value: 1, child: Text('1일 전 오전 9시')),
              DropdownMenuItem(value: 3, child: Text('3일 전 오전 9시')),
              DropdownMenuItem(value: 7, child: Text('7일 전 오전 9시')),
            ],
            onChanged: (v) => setState(() => _reminderDays = v!),
          ),
          const SizedBox(height: 12),
          SegmentedButton<MoneyFlow>(
            segments: const [
              ButtonSegment(value: MoneyFlow.none, label: Text('금액 없음')),
              ButtonSegment(value: MoneyFlow.income, label: Text('수입')),
              ButtonSegment(value: MoneyFlow.expense, label: Text('지출')),
            ],
            selected: {_flow},
            onSelectionChanged: (v) => setState(() => _flow = v.first),
          ),
          if (_flow != MoneyFlow.none) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '금액',
                suffixText: '원',
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _memo,
            maxLines: 2,
            decoration: const InputDecoration(labelText: '메모'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final title = _title.text.trim();
              if (title.isEmpty) return;
              final interval = int.tryParse(_interval.text) ?? 1;
              Navigator.pop(
                context,
                LifeItem(
                  id:
                      widget.existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  title: title,
                  category: _category,
                  dueAt: _due,
                  repeatRule: RepeatRule(
                    type: _repeat,
                    interval: interval < 1 ? 1 : interval,
                  ),
                  reminderDaysBefore: _reminderDays,
                  memo: _memo.text.trim(),
                  amount: _flow == MoneyFlow.none
                      ? null
                      : int.tryParse(_amount.text.replaceAll(',', '')),
                  moneyFlow: _flow,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen({required this.histories});
  final List<LifeHistory> histories;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('완료 기록')),
    body: histories.isEmpty
        ? const Center(child: Text('아직 완료 기록이 없어요.'))
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: histories.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, index) {
              final history = histories[index];
              return ListTile(
                leading: const Icon(Icons.check_circle_rounded),
                title: Text(history.titleSnapshot),
                subtitle: Text(
                  '${history.categorySnapshot} · ${_date(history.completedAt)}',
                ),
                trailing: history.amountSnapshot == null
                    ? null
                    : Text(_won(history.amountSnapshot!)),
              );
            },
          ),
  );
}

class _AdSlot extends StatelessWidget {
  const _AdSlot();
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Text('광고가 표시될 자리', style: Theme.of(context).textTheme.labelSmall),
  );
}

String _date(DateTime v) =>
    '${v.year}.${v.month.toString().padLeft(2, '0')}.${v.day.toString().padLeft(2, '0')}';
String _won(int value) {
  final formatted = value.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${value < 0 ? '-' : ''}$formatted원';
}

String _cardName(DashboardCardType type) => switch (type) {
  DashboardCardType.today => '오늘 할 일',
  DashboardCardType.upcoming => '예정 항목',
  DashboardCardType.moneySummary => '이번 달 돈 흐름',
  DashboardCardType.categoryChart => '카테고리별 지출',
  DashboardCardType.history => '최근 완료',
};
String _repeatName(RepeatType type) => switch (type) {
  RepeatType.none => '반복 없음',
  RepeatType.daily => '매일',
  RepeatType.weekly => '매주',
  RepeatType.monthly => '매월',
  RepeatType.yearly => '매년',
};
