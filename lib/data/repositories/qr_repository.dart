import '../database/database_helper.dart';
import '../models/qr_code_model.dart';
import '../models/collection_model.dart';

class QrRepository {
  final DatabaseHelper _dbHelper;

  QrRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> saveQrCode(QrCodeModel qrCode) async {
    if (qrCode.id != null) {
      await _dbHelper.updateQrCode(qrCode);
      return qrCode.id!;
    } else {
      return await _dbHelper.insertQrCode(qrCode);
    }
  }

  Future<List<QrCodeModel>> getQrHistory({
    bool? favoritesOnly,
    int? collectionId,
    String? searchQuery,
  }) async {
    return await _dbHelper.getAllQrCodes(
      favoritesOnly: favoritesOnly,
      collectionId: collectionId,
      searchQuery: searchQuery,
    );
  }

  Future<QrCodeModel?> getQrById(int id) async {
    return await _dbHelper.getQrCodeById(id);
  }

  Future<void> toggleFavorite(QrCodeModel qrCode) async {
    final updated = qrCode.copyWith(
      isFavorite: !qrCode.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _dbHelper.updateQrCode(updated);
  }

  Future<void> moveQrToCollection(QrCodeModel qrCode, int? collectionId) async {
    final updated = qrCode.copyWith(
      collectionId: collectionId,
      updatedAt: DateTime.now(),
    );
    await _dbHelper.updateQrCode(updated);
  }

  Future<void> deleteQrCode(int id) async {
    await _dbHelper.deleteQrCode(id);
  }

  Future<void> clearHistory() async {
    await _dbHelper.clearAllHistory();
  }

  Future<List<CollectionModel>> getCollections() async {
    return await _dbHelper.getAllCollections();
  }

  Future<int> createCollection(String name) async {
    return await _dbHelper.insertCollection(name);
  }

  Future<void> updateCollection(int id, String name) async {
    await _dbHelper.updateCollection(id, name);
  }

  Future<void> deleteCollection(int id) async {
    await _dbHelper.deleteCollection(id);
  }
}
