import 'dart:convert';

import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/sqlite_util.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class KeyValueDao {
  static Database get db => SqliteUtil.database;
  static const tableName = 'key_value';

  static const columnKey = 'key';
  static const columnValue = 'value';

  static Future<void> createTable() async {
    AppLog.info('sql: create table $tableName');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnKey      TEXT PRIMARY KEY,
        $columnValue    TEXT
      );
    ''');
  }

  static Future<bool> hasKey(String key) async {
    return await SqliteUtil.count(
          tableName: tableName,
          columnName: columnKey,
          where: '$columnKey = ?',
          whereArgs: [key],
        ) >
        0;
  }

  static Future<int> setString(String key, String? value) async {
    if (!await hasKey(key)) {
      return db.insert(tableName, {
        columnKey: key,
        columnValue: value,
      });
    } else {
      return db.update(
        tableName,
        {
          columnKey: key,
          columnValue: value,
        },
        where: '$columnKey = ?',
        whereArgs: [key],
      );
    }
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
    if (!await hasKey(key)) {
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

  static Future<List<String>?> getStringList(String key) async {
    final rows = await db.query(
      tableName,
      columns: [columnValue],
      where: '$columnKey = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;

    final String? value = rows.first[columnValue] as String? ?? '';
    if (value == null || value.isEmpty) return null;

    try {
      return (jsonDecode(value) as List<dynamic>).cast<String>();
    } catch (exception) {
      AppLog.error(exception);
      return null;
    }
  }
}
