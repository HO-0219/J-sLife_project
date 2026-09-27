import 'dart:async';

import '../domain/models.dart';
import '../domain/recurrence.dart';
import 'life_repository.dart';

class MemoryLifeRepository implements LifeRepository {
  MemoryLifeRepository({
    Iterable<LifeItem> initialItems = const [],
    Iterable<LifeHistory> initialHistories = const [],
  }) : _items = List.of(initialItems),
       _histories = List.of(initialHistories);

  final List<LifeItem> _items;
  final List<LifeHistory> _histories;
  final _itemsController = StreamController<List<LifeItem>>.broadcast(
    sync: true,
  );
  final _historiesController = StreamController<List<LifeHistory>>.broadcast(
    sync: true,
  );

  @override
  List<LifeItem> get currentItems => List.unmodifiable(_items);

  @override
  List<LifeHistory> get currentHistories => List.unmodifiable(_histories);

  List<LifeItem> get items => currentItems;
  List<LifeHistory> get histories => currentHistories;

  @override
  Stream<List<LifeItem>> watchItems() => _itemsController.stream;

  @override
  Stream<List<LifeHistory>> watchHistories() => _historiesController.stream;

  @override
  Future<void> saveItem(LifeItem item) async {
    final index = _items.indexWhere((candidate) => candidate.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    _emitItems();
  }

  @override
  Future<void> completeItem(String itemId, DateTime completedAt) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw StateError('완료할 생활 항목을 찾을 수 없습니다: $itemId');
    }

    final item = _items[index];
    _histories.insert(
      0,
      LifeHistory(
        id: '$itemId-${completedAt.microsecondsSinceEpoch}',
        lifeItemId: itemId,
        titleSnapshot: item.title,
        categorySnapshot: item.category,
        completedAt: completedAt,
        amountSnapshot: item.amount,
        moneyFlowSnapshot: item.moneyFlow,
      ),
    );

    final nextDue = calculateNextDue(completedAt, item.repeatRule);
    if (nextDue == null) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(dueAt: nextDue);
    }

    _emitHistories();
    _emitItems();
  }

  @override
  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    _emitItems();
  }

  void _emitItems() => _itemsController.add(items);

  void _emitHistories() => _historiesController.add(histories);

  @override
  Future<void> dispose() async {
    await _itemsController.close();
    await _historiesController.close();
  }
}
