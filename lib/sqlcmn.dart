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
      version: 2, // バージョンを更新（必要に応じて変更）
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 初回作成時のテーブル構造
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE form_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_name TEXT NOT NULL,
        field_name TEXT NOT NULL,
        field_value TEXT
      )
    ''');
  }

  // 既存のDBを新しい構造にアップグレード
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS tasks'); // 旧テーブル削除
      await _onCreate(db, newVersion);
    }
  }

  // データの挿入または更新（UPSERT）
  Future<int> upsertFormEntry(
      String pageName, String fieldName, String value) async {
    final db = await database;

    // 既存データをチェック
    final List<Map<String, dynamic>> existing = await db.query(
      'form_entries',
      where: 'page_name = ? AND field_name = ?',
      whereArgs: [pageName, fieldName],
    );

    if (existing.isEmpty) {
      // データがない場合は INSERT
      return await db.insert('form_entries', {
        'page_name': pageName,
        'field_name': fieldName,
        'field_value': value,
      });
    } else {
      // データがある場合は UPDATE
      return await db.update(
        'form_entries',
        {'field_value': value},
        where: 'page_name = ? AND field_name = ?',
        whereArgs: [pageName, fieldName],
      );
    }
  }

  // 特定のページのデータ取得
  Future<List<Map<String, dynamic>>> getFormEntries(String pageName) async {
    final db = await database;
    return await db.query(
      'form_entries',
      where: 'page_name = ?',
      whereArgs: [pageName],
    );
  }

  // ページ単位で保存データを削除するメソッド
  Future<int> deleteFormEntries(String pageName) async {
    final db = await database;
    return await db.delete(
      'form_entries',
      where: 'page_name = ?',
      whereArgs: [pageName],
    );
  }
}
