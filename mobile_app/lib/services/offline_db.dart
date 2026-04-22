import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

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
    return await openDatabase(fullPath, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE offline_orders ADD COLUMN status TEXT DEFAULT 'todo'");
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_orders (
        id TEXT PRIMARY KEY, payload TEXT NOT NULL, created_at TEXT NOT NULL, status TEXT DEFAULT 'todo'
      )
    ''');
    await db.execute('''
      CREATE TABLE last_order (
        id INTEGER PRIMARY KEY AUTOINCREMENT, payload TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveLastOrder(Map<String, dynamic> payload) async {
    final db = await instance.database;
    await db.delete('last_order'); // Keep only one
    await db.insert('last_order', {'payload': json.encode(payload)});
  }

  Future<Map<String, dynamic>?> getLastOrder() async {
    final db = await instance.database;
    final res = await db.query('last_order', limit: 1);
    if (res.isNotEmpty) {
      return json.decode(res.first['payload'] as String);
    }
    return null;
  }

  Future<void> insertOrder(String id, Map<String, dynamic> payload) async {
    final db = await instance.database;
    await db.insert('offline_orders', {
      'id': id, 
      'payload': json.encode(payload), 
      'created_at': DateTime.now().toIso8601String(),
      'status': 'todo'
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final db = await instance.database;
    await db.update('offline_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archiveOrder(String id) async {
    final db = await instance.database;
    await db.update('offline_orders', {'status': 'archived'}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    final db = await instance.database;
    return await db.query('offline_orders', 
      where: "status IN ('todo', 'brewing', 'done')", 
      orderBy: 'created_at ASC');
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
