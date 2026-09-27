import '../domain/models.dart';

abstract interface class LifeRepository {
  List<LifeItem> get currentItems;

  List<LifeHistory> get currentHistories;

  Stream<List<LifeItem>> watchItems();

  Stream<List<LifeHistory>> watchHistories();

  Future<void> saveItem(LifeItem item);

  Future<void> completeItem(String itemId, DateTime completedAt);

  Future<void> deleteItem(String itemId);

  Future<void> dispose();
}
