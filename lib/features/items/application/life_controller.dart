import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/life_repository.dart';
import '../domain/models.dart';
import 'notification_service.dart';

class LifeState {
  const LifeState({this.items = const [], this.histories = const []});

  final List<LifeItem> items;
  final List<LifeHistory> histories;

  LifeState copyWith({List<LifeItem>? items, List<LifeHistory>? histories}) =>
      LifeState(
        items: items ?? this.items,
        histories: histories ?? this.histories,
      );
}

class LifeController extends ValueNotifier<LifeState> {
  LifeController(this._repository, {this.notificationService})
    : super(
        LifeState(
          items: _repository.currentItems,
          histories: _repository.currentHistories,
        ),
      ) {
    _itemsSubscription = _repository.watchItems().listen(
      (items) => value = value.copyWith(items: items),
    );
    _historiesSubscription = _repository.watchHistories().listen(
      (histories) => value = value.copyWith(histories: histories),
    );
  }

  final LifeRepository _repository;
  final LifeNotificationService? notificationService;
  late final StreamSubscription<List<LifeItem>> _itemsSubscription;
  late final StreamSubscription<List<LifeHistory>> _historiesSubscription;

  Future<void> saveItem(LifeItem item) async {
    await _repository.saveItem(item);
    await notificationService?.schedule(item);
  }

  Future<void> completeItem(String itemId, DateTime completedAt) async {
    await _repository.completeItem(itemId, completedAt);
    final next = _repository.currentItems
        .where((item) => item.id == itemId)
        .firstOrNull;
    if (next == null) {
      await notificationService?.cancel(itemId);
    } else {
      await notificationService?.schedule(next);
    }
  }

  Future<void> deleteItem(String itemId) async {
    await _repository.deleteItem(itemId);
    await notificationService?.cancel(itemId);
  }

  @override
  void dispose() {
    unawaited(_itemsSubscription.cancel());
    unawaited(_historiesSubscription.cancel());
    unawaited(_repository.dispose());
    super.dispose();
  }
}
