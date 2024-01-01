import 'package:latlong2/latlong.dart';

// class PolygonData {
//   List<LatLng> polygonPoints;
//   double minLatitude, minLongitude, maxLatitude, maxLongitude;
//   int rowIndex, colIndex;

//   PolygonData(
//       {required this.polygonPoints,
//       required this.minLatitude,
//       required this.minLongitude,
//       required this.maxLatitude,
//       required this.maxLongitude,
//       required this.rowIndex,
//       required this.colIndex});
// }

class PolygonData {
  List<LatLng> polygonPoints;
  double minLatitude, minLongitude, maxLatitude, maxLongitude;
  int rowIndex, colIndex;

  PolygonData({
    required this.polygonPoints,
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
    required this.rowIndex,
    required this.colIndex,
  });

  factory PolygonData.fromCsvLine(String csvLine) {
    final parts = csvLine.trim().split('((')[1].split('))"')[1].split(',');

    final polygonPointsString = csvLine.trim().split('((')[1].split('))"')[0];
    final polygonPoints = polygonPointsString.split(',').map((point) {
      final coordinates = point.trim().split(' ');
      final latitude = double.parse(coordinates[1]);
      final longitude = double.parse(coordinates[0]);
      return LatLng(latitude, longitude);
    }).toList();

    final minLatitude = double.parse(parts[3]);
    final minLongitude = double.parse(parts[2]);
    final maxLatitude = double.parse(parts[5]);
    final maxLongitude = double.parse(parts[4]);
    final colIndex = int.parse(parts[6]);
    final rowIndex = int.parse(parts[7]);

    return PolygonData(
      polygonPoints: polygonPoints,
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: maxLatitude,
      maxLongitude: maxLongitude,
      rowIndex: rowIndex,
      colIndex: colIndex,
    );
  }
}

List<PolygonData> parseCSV(String csvData) {
  List<PolygonData> polygons = [];

  List<String> lines = csvData.split('\n');
  for (int i = 1; i < lines.length; i++) {
    final polygon = PolygonData.fromCsvLine(lines[i]);

    polygons.add(polygon);
  }

  return polygons;
}
