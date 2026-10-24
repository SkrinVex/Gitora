import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gitora/domain/models/repository_item.dart';

class DatabaseService {
  static Database? _database;

  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'gitora_local.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE repositories (
            path TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            lastOpened INTEGER NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<RepositoryItem>> getRepositories() async {
    final db = await database;
    final maps = await db.query(
      'repositories',
      orderBy: 'isFavorite DESC, lastOpened DESC',
    );
    return maps.map((m) => RepositoryItem.fromMap(m)).toList();
  }

  Future<void> saveRepository(RepositoryItem item) async {
    final normalizedPath = RepositoryItem.normalizePath(item.path);
    final db = await database;

    // Check existing to preserve isFavorite when opening repository
    final existing = await db.query(
      'repositories',
      columns: ['isFavorite'],
      where: 'path = ?',
      whereArgs: [normalizedPath],
    );

    final isFav = existing.isNotEmpty
        ? ((existing.first['isFavorite'] as int? ?? 0) == 1 || item.isFavorite)
        : item.isFavorite;

    await db.insert(
      'repositories',
      item.copyWith(path: normalizedPath, isFavorite: isFav).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeRepository(String path) async {
    final normalizedPath = RepositoryItem.normalizePath(path);
    final db = await database;
    await db.delete(
      'repositories',
      where: 'path = ?',
      whereArgs: [normalizedPath],
    );
  }

  Future<void> toggleFavorite(String path) async {
    final normalizedPath = RepositoryItem.normalizePath(path);
    final db = await database;
    final results = await db.query(
      'repositories',
      columns: ['isFavorite'],
      where: 'path = ?',
      whereArgs: [normalizedPath],
    );

    if (results.isNotEmpty) {
      final current = (results.first['isFavorite'] as int? ?? 0) == 1;
      await db.update(
        'repositories',
        {'isFavorite': current ? 0 : 1},
        where: 'path = ?',
        whereArgs: [normalizedPath],
      );
    }
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert('metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final results = await db.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }
}
