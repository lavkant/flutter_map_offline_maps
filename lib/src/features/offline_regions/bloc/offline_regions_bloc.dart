import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_offline_poc/src/core/bloc/base_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/bloc/regions_sqlite_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/models/offline_region_model.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/models/region_with_bounds_model.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/subjects.dart';

final Map<String, String> baseMapStoreData = {
  "storeName": "baseMapStreet",
  "sourceURL":
      // "https://api.mapbox.com/styles/v1/captainfreshin/clchytjyh002915mrs9klczdk/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w",
      "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibGF2a2FudCIsImEiOiJjbG9qemdzZ3MyNGRoMnFvaWxzMjYzemtoIn0.3lnV7d77eu-M8DnFZpRcoQ",
  "validDuration": "100",
  "maxLength": "20000"
};

final Map<String, String> bathyMapStoreData = {
  "storeName": "bathyMetryLayer",
  "sourceURL":
      "https://api.mapbox.com/styles/v1/captainfreshin/clq9cj58n005n01o34jrgdh2i/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w",
  "validDuration": "100",
  "maxLength": "20000"
};

class OfflineRegionsBloc extends BaseBloc {
  final BehaviorSubject<bool> _loadingController = BehaviorSubject.seeded(false);
  List<PolygonData>? polygons;

  final String regionString = "REGION";
  List<RegionBound>? regionBounds;
  // GETTERS
  BehaviorSubject get loadingController => _loadingController;

  // METHODS
  Future<List<RegionBound>?> getPolygonsFromDB() async {
    return await GetIt.instance<RegionsSqliteBloc>().getAllRegionBounds();
  }

  loadCSVData({required String csvPath}) async {
    polygons?.clear();
    regionBounds?.clear();
    _loadingController.add(true);
    WidgetsFlutterBinding.ensureInitialized();
    String csvData = await rootBundle.loadString(csvPath);
    polygons = parseCSV(csvData);

    if (polygons != null && polygons!.isNotEmpty) {
      regionBounds = getRegionBounds(polygons: polygons!);
      // Save the data to the database
      for (var region in regionBounds!) {
        await GetIt.instance<RegionsSqliteBloc>().createRegionBound(region);
      }
    }

    _loadingController.add(false);
  }

  List<RegionBound> getRegionBounds({required List<PolygonData> polygons}) {
    List<RegionBound> list = [];
    for (var e in polygons) {
      final index = polygons.indexOf(e);
      final LatLngBounds latLongBound = LatLngBounds(e.polygonPoints[0], e.polygonPoints[2]);
      list.add(RegionBound(name: "$regionString$index", bounds: latLongBound));
    }
    return list;
  }

  getBaseRegionForBaseMap({required String regionName}) {
    final region = regionBounds?.where((element) => element.name == regionName);
    if (region != null) {
      return RectangleRegion(region.first.bounds, name: region.first.name);
    }
  }

  updateBaseRegionDownloadStatus({required String regionName}) async {
    _loadingController.add(true);
    final region = regionBounds?.where((element) => element.name == regionName);
    if (region != null) {
      final index = regionBounds?.indexOf(region.first);
      // regionBounds![index!] = RegionBound(name: region.first.name, bounds: region.first.bounds, isDownloaded: true);
      // GetIt.instance
      await GetIt.instance<RegionsSqliteBloc>().updateRegionDownloadStatus(regionName, true);
    }
    _loadingController.add(false);
  }

  removeAllDownloadStatusAndRegions() async {
    _loadingController.add(true);
    await GetIt.instance<RegionsSqliteBloc>().deleteAllRegionBounds();

    _loadingController.add(false);
  }

  @override
  dispose() {
    // TODO: implement dispose
    _loadingController.close();
  }
}

// final OfflineRegionsBloc offlineRegionsBloc = OfflineRegionsBloc();
