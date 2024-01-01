import 'package:flutter_map/flutter_map.dart';

class RegionBound {
  final String name;
  final LatLngBounds bounds;
  bool isDownloaded;
  RegionBound({required this.name, required this.bounds, this.isDownloaded = false});
}
