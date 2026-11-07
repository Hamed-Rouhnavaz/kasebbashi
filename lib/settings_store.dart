import 'package:sqflite/sqflite.dart';

import 'db.dart';

/// ذخیره و خواندن تنظیمات ساده (کلید و مقدار)
class SettingsStore {
  static Future<Database> _db() async {
    final db = await AppDatabase.instance.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings (name TEXT PRIMARY KEY, value TEXT)',
    );
    return db;
  }

  static Future<String?> get(String name) async {
    final db = await _db();
    final rows =
        await db.query('settings', where: 'name = ?', whereArgs: [name]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> set(String name, String value) async {
    final db = await _db();
    await db.insert(
      'settings',
      {'name': name, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
