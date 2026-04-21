import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

// 🗄️ --- SQLite Database Helper ---
class OfflineDBHelper {
  static final OfflineDBHelper instance = OfflineDBHelper._init();
  static Database? _database;
  OfflineDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, filePath);
    return await openDatabase(fullPath, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_orders (
        id TEXT PRIMARY KEY, payload TEXT NOT NULL, created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertOrder(String id, Map<String, dynamic> payload) async {
    final db = await instance.database;
    await db.insert('offline_orders', {
      'id': id, 'payload': json.encode(payload), 'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await instance.database;
    return await db.query('offline_orders', orderBy: 'created_at ASC');
  }

  Future<void> deleteOrder(String id) async {
    final db = await instance.database;
    await db.delete('offline_orders', where: 'id = ?', whereArgs: [id]);
  }
}