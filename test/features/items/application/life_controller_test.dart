import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/items/application/life_controller.dart';
import 'package:j_life/features/items/application/notification_service.dart';
import 'package:j_life/features/items/data/memory_life_repository.dart';
import 'package:j_life/features/items/domain/models.dart';

void main() {
  test(
    'controller exposes repository changes and completion history',
    () async {
      final repository = MemoryLifeRepository();
      final controller = LifeController(repository);
      addTearDown(controller.dispose);

      await controller.saveItem(
        LifeItem(
          id: 'toothbrush',
          title: '칫솔 교체',
          category: '개인',
          dueAt: DateTime(2026, 9, 27),
          repeatRule: const RepeatRule(type: RepeatType.monthly, interval: 3),
        ),
      );
      expect(controller.value.items.single.title, '칫솔 교체');

      await controller.completeItem('toothbrush', DateTime(2026, 9, 28));
      expect(controller.value.histories, hasLength(1));
      expect(controller.value.items.single.dueAt, DateTime(2026, 12, 28));
    },
  );

  test('save schedules and delete cancels its notification', () async {
    final notifications = _FakeNotifications();
    final controller = LifeController(
      MemoryLifeRepository(),
      notificationService: notifications,
    );
    addTearDown(controller.dispose);
    final item = LifeItem(
      id: 'return',
      title: '반품 마감',
      category: '구매',
      dueAt: DateTime(2026, 10, 1),
    );

    await controller.saveItem(item);
    await controller.deleteItem(item.id);

    expect(notifications.scheduled, ['return']);
    expect(notifications.cancelled, ['return']);
  });
}

class _FakeNotifications implements LifeNotificationService {
  final scheduled = <String>[];
  final cancelled = <String>[];
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(LifeItem item) async => scheduled.add(item.id);
  @override
  Future<void> cancel(String itemId) async => cancelled.add(itemId);
}
