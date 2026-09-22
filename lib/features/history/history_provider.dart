import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/qr_code_model.dart';
import '../../data/repositories/qr_repository.dart';

final qrRepositoryProvider = Provider<QrRepository>((ref) {
  return QrRepository();
});

class HistoryState {
  final List<QrCodeModel> items;
  final bool isLoading;
  final String searchQuery;
  final bool favoritesOnly;
  final int? selectedCollectionId;

  HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.favoritesOnly = false,
    this.selectedCollectionId,
  });

  HistoryState copyWith({
    List<QrCodeModel>? items,
    bool? isLoading,
    String? searchQuery,
    bool? favoritesOnly,
    int? selectedCollectionId,
    bool clearCollectionFilter = false,
  }) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      selectedCollectionId: clearCollectionFilter ? null : (selectedCollectionId ?? this.selectedCollectionId),
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final QrRepository _repository;

  HistoryNotifier(this._repository) : super(HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    final results = await _repository.getQrHistory(
      favoritesOnly: state.favoritesOnly ? true : null,
      collectionId: state.selectedCollectionId,
      searchQuery: state.searchQuery,
    );
    state = state.copyWith(items: results, isLoading: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadHistory();
  }

  void setFavoritesOnly(bool favOnly) {
    state = state.copyWith(favoritesOnly: favOnly);
    loadHistory();
  }

  void setCollectionFilter(int? collectionId) {
    if (collectionId == null) {
      state = state.copyWith(clearCollectionFilter: true);
    } else {
      state = state.copyWith(selectedCollectionId: collectionId);
    }
    loadHistory();
  }

  Future<int> addQrCode(QrCodeModel qr) async {
    final id = await _repository.saveQrCode(qr);
    await loadHistory();
    return id;
  }

  Future<void> toggleFavorite(QrCodeModel qr) async {
    await _repository.toggleFavorite(qr);
    await loadHistory();
  }

  Future<void> moveCollection(QrCodeModel qr, int? collectionId) async {
    await _repository.moveQrToCollection(qr, collectionId);
    await loadHistory();
  }

  Future<void> deleteQr(int id) async {
    await _repository.deleteQrCode(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _repository.clearHistory();
    await loadHistory();
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final repository = ref.watch(qrRepositoryProvider);
  return HistoryNotifier(repository);
});
