import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'memory_life_repository.dart';

abstract interface class StringStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesStringStore implements StringStore {
  SharedPreferencesStringStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

class PersistentLifeRepository extends MemoryLifeRepository {
  PersistentLifeRepository._(
    this._store, {
    required super.initialItems,
    required super.initialHistories,
  });

  static const storageKey = 'j_life_data_v1';
  final StringStore _store;

  static Future<PersistentLifeRepository> create(StringStore store) async {
    final encoded = await store.read(storageKey);
    if (encoded == null || encoded.isEmpty) {
      return PersistentLifeRepository._(
        store,
        initialItems: const [],
        initialHistories: const [],
      );
    }
    final json = jsonDecode(encoded) as Map<String, Object?>;
    return PersistentLifeRepository._(
      store,
      initialItems: (json['items']! as List).map(
        (value) => LifeItem.fromJson((value as Map).cast<String, Object?>()),
      ),
      initialHistories: (json['histories']! as List).map(
        (value) => LifeHistory.fromJson((value as Map).cast<String, Object?>()),
      ),
    );
  }

  @override
  Future<void> saveItem(LifeItem item) async {
    await super.saveItem(item);
    await _persist();
  }

  @override
  Future<void> completeItem(String itemId, DateTime completedAt) async {
    await super.completeItem(itemId, completedAt);
    await _persist();
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await super.deleteItem(itemId);
    await _persist();
  }

  Future<void> _persist() => _store.write(
    storageKey,
    jsonEncode({
      'items': currentItems.map((item) => item.toJson()).toList(),
      'histories': currentHistories.map((history) => history.toJson()).toList(),
    }),
  );
}
