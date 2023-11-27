import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MapboxTileDownloadService {
  final String _databaseName = 'offline_maps.db';
  final String _tableName = 'tiles';

  Database? _database;
  bool _mapDownloaded = false;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    _mapDownloaded = await _checkMapDownloaded(); // Check map downloaded status
    return _database!;
  }

  Future<void> checkIfMapDownload() async {
    _mapDownloaded = await _checkMapDownloaded(); // Check map downloaded status
  }

  Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // String path = join(documentsDirectory.path, _databaseName);
    String path = documentsDirectory.path + _databaseName;

    _database = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $_tableName (
          x INTEGER,
          y INTEGER,
          z INTEGER,
          image BLOB,
          PRIMARY KEY (x, y, z)
        )
      ''');
    });

    _mapDownloaded = await _checkMapDownloaded(); // Check map downloaded status
    return _database!;
  }

  Future<void> insertTile(int x, int y, int z, Uint8List imageBytes) async {
    final Database db = await database;
    await db.insert(
      _tableName,
      {'x': x, 'y': y, 'z': z, 'image': imageBytes},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _mapDownloaded = true; // Update flag after inserting a tile
  }

  Future<Uint8List?> getTile(int x, int y, int z) async {
    final Database db = await database;
    List<Map<String, dynamic>> tiles = await db.query(
      _tableName,
      where: 'x = ? AND y = ? AND z = ?',
      whereArgs: [x, y, z],
    );

    if (tiles.isNotEmpty) {
      return tiles.first['image'];
    }

    return null;
  }

  Future<bool> downloadAndSaveTiles({
    required String tilesetUrl,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) async {
    final Dio dio = Dio();

    try {
      int currentIteration = 1;
      final estimatedIteration = (maxZoom - minZoom) *
          (bounds.east.toInt() - bounds.west.toInt()) *
          (bounds.north.toInt() - bounds.south.toInt());

      for (int z = minZoom; z <= maxZoom; z++) {
        for (int x = bounds.west.toInt(); x <= bounds.east.toInt(); x++) {
          for (int y = bounds.south.toInt(); y <= bounds.north.toInt(); y++) {
            final String tileUrl0 = '$tilesetUrl/$z/$x/$y';
            final String tileUrl = getFinalUrl(url: tileUrl0);
            final String id = DateTime.now().millisecondsSinceEpoch.toString();
            try {
              final Uint8List tileImage = await _downloadTile(dio, tileUrl);

              debugPrint("Downlaoded Progress ${currentIteration / estimatedIteration} ");

              await insertTile(x, y, z, tileImage);
              debugPrint("Remaining Iteration${estimatedIteration - currentIteration} ");
              // debugPrint("Saved Part $id");
            } catch (e) {
              debugPrint('Failed to download tile $x, $y, $z: $e');
              return false;
            }
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint("SOME ERROR IN DOWNLOADING MAP $e");
      return false;
    }
  }

  Future<Uint8List> _downloadTile(Dio dio, String tileUrl) async {
    final Response<List<int>> response = await dio.get<List<int>>(
      tileUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data!);
  }

  Future<bool> _checkMapDownloaded() async {
    final Database db = await database;
    List<Map<String, dynamic>> tiles = await db.query(_tableName);
    return tiles.isNotEmpty;
  }

  Future<void> clearDownloadedTiles() async {
    final Database db = await database;
    await db.delete(_tableName);
    _mapDownloaded = false;
  }

  bool get isMapDownloaded => _mapDownloaded;
}
