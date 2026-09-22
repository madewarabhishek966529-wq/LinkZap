import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/qr_repository.dart';
import '../history/history_provider.dart';

class CollectionsNotifier extends StateNotifier<List<CollectionModel>> {
  final QrRepository _repository;

  CollectionsNotifier(this._repository) : super([]) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    final list = await _repository.getCollections();
    state = list;
  }

  Future<void> createCollection(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _repository.createCollection(trimmed);
    await loadCollections();
  }

  Future<void> updateCollection(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await _repository.updateCollection(id, trimmed);
    await loadCollections();
  }

  Future<void> deleteCollection(int id) async {
    await _repository.deleteCollection(id);
    await loadCollections();
  }
}

final collectionsProvider = StateNotifierProvider<CollectionsNotifier, List<CollectionModel>>((ref) {
  final repository = ref.watch(qrRepositoryProvider);
  return CollectionsNotifier(repository);
});
