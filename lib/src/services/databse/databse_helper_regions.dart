import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseRegionHelper {
  static Database? _database;
  static const _dbName = 'regions_database.db';
  static const _tableName = 'region_bounds';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      // Check if the table exists before creating it
      var tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName';",
      );

      if (tableExists.isEmpty) {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            minLat REAL,
            minLon REAL,
            maxLat REAL,
            maxLon REAL,
            isDownloaded INTEGER
          )
        ''');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getAllRegionBounds() async {
    Database db = await database;
    return db.query(_tableName);
  }

  static Future<void> insertRegionBound(Map<String, dynamic> regionData) async {
    Database db = await database;
    await db.insert(_tableName, regionData);
  }

  static Future<void> updateRegionDownloadStatus(String regionName, bool isDownloaded) async {
    Database db = await database;
    await db.update(
      _tableName,
      {'isDownloaded': isDownloaded ? 1 : 0},
      where: 'name = ?',
      whereArgs: [regionName],
    );
  }

  static Future<void> deleteRegionBound(String regionName) async {
    Database db = await database;
    await db.delete(
      _tableName,
      where: 'name = ?',
      whereArgs: [regionName],
    );
  }

  static Future<void> deleteAllRegionBounds() async {
    Database db = await database;
    await db.delete(_tableName);
  }
}
