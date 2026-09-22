import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/qr_code_model.dart';
import '../models/collection_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Allow passing custom Database instance for unit testing (e.g. sqflite_ffi)
  void setTestDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('linkzap.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE qr_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        collection_id INTEGER,
        foreground_color INTEGER NOT NULL,
        background_color INTEGER NOT NULL,
        dot_style TEXT NOT NULL,
        eye_style TEXT NOT NULL,
        error_correction TEXT NOT NULL,
        logo_path TEXT,
        logo_is_rounded INTEGER NOT NULL DEFAULT 1,
        margin REAL NOT NULL DEFAULT 12.0,
        FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE SET NULL
      )
    ''');

    // Seed default collections
    final now = DateTime.now().toIso8601String();
    final defaultCollections = ['College', 'Work', 'Personal', 'Business', 'Events'];
    for (final name in defaultCollections) {
      await db.insert('collections', {
        'name': name,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // --- QR CODES CRUD ---

  Future<int> insertQrCode(QrCodeModel qrCode) async {
    final db = await instance.database;
    return await db.insert('qr_codes', qrCode.toMap());
  }

  Future<QrCodeModel?> getQrCodeById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'qr_codes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return QrCodeModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<QrCodeModel>> getAllQrCodes({
    bool? favoritesOnly,
    int? collectionId,
    String? searchQuery,
  }) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    List<String> conditions = [];

    if (favoritesOnly == true) {
      conditions.add('is_favorite = 1');
    }

    if (collectionId != null) {
      conditions.add('collection_id = ?');
      whereArgs.add(collectionId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR content LIKE ? OR type LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    final result = await db.query(
      'qr_codes',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return result.map((json) => QrCodeModel.fromMap(json)).toList();
  }

  Future<int> updateQrCode(QrCodeModel qrCode) async {
    final db = await instance.database;
    return await db.update(
      'qr_codes',
      qrCode.toMap(),
      where: 'id = ?',
      whereArgs: [qrCode.id],
    );
  }

  Future<int> deleteQrCode(int id) async {
    final db = await instance.database;
    return await db.delete(
      'qr_codes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllHistory() async {
    final db = await instance.database;
    return await db.delete('qr_codes');
  }

  // --- COLLECTIONS CRUD ---

  Future<int> insertCollection(String name) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('collections', {
      'name': name,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<CollectionModel>> getAllCollections() async {
    final db = await instance.database;
    final result = await db.query('collections', orderBy: 'name ASC');
    return result.map((json) => CollectionModel.fromMap(json)).toList();
  }

  Future<int> updateCollection(int id, String newName) async {
    final db = await instance.database;
    return await db.update(
      'collections',
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCollection(int id) async {
    final db = await instance.database;
    return await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
