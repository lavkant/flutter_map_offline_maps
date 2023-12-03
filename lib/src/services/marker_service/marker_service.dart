import 'package:flutter_map_offline_poc/src/services/databse/databse_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/subjects.dart';
import 'package:sqflite/sqflite.dart';

class CustomMarker {
  int? id;
  LatLng position;
  String notes;

  CustomMarker({this.id, required this.position, required this.notes});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'notes': notes,
    };
  }

  static CustomMarker fromMap(Map<String, dynamic> map) {
    return CustomMarker(
      id: map['id'],
      position: LatLng(map['latitude'], map['longitude']),
      notes: map['notes'],
    );
  }
}

class MarkerService {
  final BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  List<CustomMarker> markers = [];

  Future<void> addMarker(LatLng position, String notes) async {
    loadingController.add(true);
    final CustomMarker newMarker = CustomMarker(position: position, notes: notes);
    newMarker.id = await _insertMarker(newMarker);
    markers.add(newMarker);
    loadingController.add(false);
    getMarkers();
  }

  Future<int> _insertMarker(CustomMarker marker) async {
    final Database db = await DatabaseHelper.database;
    return await db.insert('markers', marker.toMap());
  }

  Future<List<CustomMarker>> getMarkers() async {
    loadingController.add(true);
    final Database db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('markers');

    markers = List.generate(maps.length, (index) {
      return CustomMarker(
        id: maps[index]['id'],
        position: LatLng(maps[index]['latitude'], maps[index]['longitude']),
        notes: maps[index]['notes'],
      );
    });
    loadingController.add(false);

    return markers;
  }

  Future<void> removeMarker(int markerId) async {
    loadingController.add(true);
    await _deleteMarker(markerId);
    markers.removeWhere((marker) => marker.id == markerId);
    loadingController.add(false);
  }

  Future<void> editMarker(int markerId, String newNotes) async {
    loadingController.add(true);
    await _updateMarker(markerId, newNotes);
    final CustomMarker editedMarker = markers.firstWhere((marker) => marker.id == markerId);
    editedMarker.notes = newNotes;
    loadingController.add(false);
  }

  Future<void> _deleteMarker(int markerId) async {
    final Database db = await DatabaseHelper.database;
    await db.delete('markers', where: 'id = ?', whereArgs: [markerId]);
  }

  Future<void> _updateMarker(int markerId, String newNotes) async {
    final Database db = await DatabaseHelper.database;
    await db.update('markers', {'notes': newNotes}, where: 'id = ?', whereArgs: [markerId]);
  }

  Future<void> clearMarkers() async {
    loadingController.add(true);
    await _deleteAllMarkers();
    markers.clear();
    loadingController.add(false);
  }

  Future<void> _deleteAllMarkers() async {
    final Database db = await DatabaseHelper.database;
    await db.delete('markers');
  }

  // Implement other methods like updateMarker, deleteMarker, etc.
}
