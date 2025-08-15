import 'dart:convert';

import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/sqlite_util.dart';
import 'package:sqflite/sqflite.dart';

class KeyValueDao {
  static Database get db => SqliteUtil.database;
  static const tableName = 'key_value';

  static const columnKey = 'key';
  static const columnValue = 'value';

  static Future<void> createTable() async {
    Log.info('sql: create table $tableName');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnKey      TEXT PRIMARY KEY,
        $columnValue    TEXT
      );
    ''');
  }

  static Future<void> setString(String key, String? value) {
    return db.insert(tableName, {
      columnKey: key,
      columnValue: value,
    });
  }

  static Future<String?>? getString(String key) async {
    final rows = await db.query(
      tableName,
      columns: [columnValue],
      where: '$columnKey = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first[columnValue] as String?;
  }

  static Future<void> setBool(String key, bool value) {
    return setString(key, value.toString());
  }

  static Future<bool?> getBool(String key) async {
    return bool.tryParse(await getString(key) ?? '');
  }

  static Future<int> setStringList(String key, List<String>? value) async {
    if (await SqliteUtil.count(
          tableName: tableName,
          columnName: columnKey,
          where: '$columnKey = ?',
          whereArgs: [key],
        ) ==
        0) {
      return db.insert(tableName, {
        columnKey: key,
        columnValue: jsonEncode(value),
      });
    } else {
      return db.update(
        tableName,
        {
          columnKey: key,
          columnValue: jsonEncode(value),
        },
        where: '$columnKey = ?',
        whereArgs: [key],
      );
    }
  }

  static Future<List<String>>? getStringList(String key) async {
    final rows = await db.query(
      tableName,
      columns: [columnValue],
      where: '$columnKey = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return [];
    final String? value = rows.first[columnValue] as String? ?? '';
    if (value == null || value.isEmpty) return [];
    try {
      return (jsonDecode(value) as List<dynamic>).cast<String>();
    } catch (exception) {
      Log.error(exception);
      return [];
    }
  }
}
