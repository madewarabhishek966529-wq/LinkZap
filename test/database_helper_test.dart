import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkzap/data/database/database_helper.dart';
import 'package:linkzap/data/models/qr_code_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper SQLite Unit Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
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
              margin REAL NOT NULL DEFAULT 12.0
            )
          ''');
        },
      );
      DatabaseHelper.instance.setTestDatabase(testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('insertQrCode and getAllQrCodes works', () async {
      final model = QrCodeModel(
        type: QrType.url,
        title: 'GitHub',
        content: 'https://github.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await DatabaseHelper.instance.insertQrCode(model);
      expect(id, greaterThan(0));

      final list = await DatabaseHelper.instance.getAllQrCodes();
      expect(list.length, 1);
      expect(list.first.title, 'GitHub');
    });

    test('favorite filter works', () async {
      final model1 = QrCodeModel(
        type: QrType.url,
        title: 'Item 1',
        content: 'https://test1.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: true,
      );

      final model2 = QrCodeModel(
        type: QrType.url,
        title: 'Item 2',
        content: 'https://test2.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      );

      await DatabaseHelper.instance.insertQrCode(model1);
      await DatabaseHelper.instance.insertQrCode(model2);

      final favs = await DatabaseHelper.instance.getAllQrCodes(favoritesOnly: true);
      expect(favs.length, 1);
      expect(favs.first.title, 'Item 1');
    });
  });
}
