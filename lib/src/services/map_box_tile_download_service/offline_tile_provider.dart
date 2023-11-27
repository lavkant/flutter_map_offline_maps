import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteTileProvider extends TileProvider {
  final String tableName;
  final String databaseName;
  final Database db;
  final Map<String, Uint8List> tileCache = {};

  SQLiteTileProvider(this.tableName, this.databaseName, this.db);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final tileKey = '${coordinates.x}_${coordinates.y}_${coordinates.z}';
    final tileBytes = tileCache[tileKey];

    return MemoryImage(tileBytes ?? Uint8List(0));
  }

  Future<void> preloadTiles(List<TileCoordinates> tileCoordinatesList) async {
    for (final coordinates in tileCoordinatesList) {
      final tileBytes = await _getTile(coordinates.x.toInt(), coordinates.y.toInt(), coordinates.z.toInt());
      final tileKey = '${coordinates.x}_${coordinates.y}_${coordinates.z}';
      tileCache[tileKey] = tileBytes!;
    }
  }

  Future<Uint8List?> _getTile(int x, int y, int z) async {
    // Your logic to fetch the tile bytes from the SQLite database
    // Replace this with the actual implementation based on your database structure

    // Open the database
    return await _fetchTileFromDatabase(x, y, z);
  }

  Future<Uint8List?> _fetchTileFromDatabase(int x, int y, int z) async {
    try {
      // Query the database for the tile
      List<Map<String, dynamic>> tiles = await db.query(
        tableName,
        columns: ['image'],
        where: 'x = ? AND y = ? AND z = ?',
        whereArgs: [x, y, z],
      );

      if (tiles.isNotEmpty) {
        // Return the tile bytes
        return tiles.first['image'];
      } else {
        // Return null or a default tile if the requested tile is not found
        return null;
      }
    } finally {
      // No need to close the database here since it's a shared resource
    }
  }
}
