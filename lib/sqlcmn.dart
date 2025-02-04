import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteCommon {
  // シングルトンパターン（インスタンスを1つに制限）
  static final SQLiteCommon _instance = SQLiteCommon._internal();
  factory SQLiteCommon() => _instance;
  SQLiteCommon._internal();

  // データベースインスタンス
  static Database? _database;

  // データベースを取得（初期化されていなければ作成）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // データベースの初期化
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath(); // デフォルトのデータベースパスを取得
    final path = join(dbPath, 'fplan.db'); // データベースファイル名
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 初回作成時のテーブル構造
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  // データの挿入
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  // データの取得
  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query('tasks');
  }

  // データの更新
  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  // データの削除
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
