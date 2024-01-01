import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_offline_poc/src/core/bloc/base_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/models/region_with_bounds_model.dart';
import 'package:flutter_map_offline_poc/src/services/databse/databse_helper_regions.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';

class RegionsSqliteBloc extends BaseBloc {
  final BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  // Create
  Future<void> createRegionBound(RegionBound region) async {
    try {
      await DatabaseRegionHelper.insertRegionBound({
        'name': region.name,
        'minLat': region.bounds.south,
        'minLon': region.bounds.west,
        'maxLat': region.bounds.north,
        'maxLon': region.bounds.east,
        'isDownloaded': region.isDownloaded ? 1 : 0,
      });
    } catch (e) {
      // Handle the exception
      debugPrint('Error creating region: $e');
    }
  }

  // Read
  Future<List<RegionBound>> getAllRegionBounds() async {
    try {
      final List<Map<String, dynamic>> result = await DatabaseRegionHelper.getAllRegionBounds();
      return result.map((row) {
        return RegionBound(
          name: row['name'],
          bounds: LatLngBounds(
            LatLng(row['minLat'], row['minLon']),
            LatLng(row['maxLat'], row['maxLon']),
          ),
          isDownloaded: row['isDownloaded'] == 1,
        );
      }).toList();
    } catch (e) {
      // Handle the exception
      debugPrint('Error fetching region bounds: $e');
      return [];
    }
  }

  // Update
  Future<void> updateRegionDownloadStatus(String regionName, bool isDownloaded) async {
    try {
      await DatabaseRegionHelper.updateRegionDownloadStatus(regionName, isDownloaded);
    } catch (e) {
      // Handle the exception
      debugPrint('Error updating region download status: $e');
    }
  }

  // Delete
  Future<void> deleteRegionBound(String regionName) async {
    try {
      await DatabaseRegionHelper.deleteRegionBound(regionName);
    } catch (e) {
      // Handle the exception
      debugPrint('Error deleting region: $e');
    }
  }

  Future<void> deleteAllRegionBounds() async {
    try {
      await DatabaseRegionHelper.deleteAllRegionBounds();
    } catch (e) {
      // Handle the exception
      debugPrint('Error deleting region: $e');
    }
  }

  @override
  dispose() {
    loadingController.close();
  }
}
