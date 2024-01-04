import 'dart:io';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:fmtc_plus_sharing/fmtc_plus_sharing.dart';

final Map<String, String> baseMapStoreData = {
  "storeName": "baseMap",
  "sourceURL":
      // "https://api.mapbox.com/styles/v1/captainfreshin/clchytjyh002915mrs9klczdk/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w",
      "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibGF2a2FudCIsImEiOiJjbG9qemdzZ3MyNGRoMnFvaWxzMjYzemtoIn0.3lnV7d77eu-M8DnFZpRcoQ",
  "validDuration": "100",
  "maxLength": "20000"
};

final Map<String, String> bathyMapStoreData = {
  "storeName": "bathyMetryLayer",
  "sourceURL":
      "https://api.mapbox.com/styles/v1/captainfreshin/clcsqekjd001n14qz4f6xyorn/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w",
  "validDuration": "100",
  "maxLength": "20000"
};
// https://api.mapbox.com/styles/v1/captainfreshin/clopltpd800j401pb7e3ngit2/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w

class StoreService {
  // CREATE STORE
  StoreDirectory? _baseMapStore;
  StoreDirectory? bathymetryLayerStore;
  StoreDirectory? internationBoundryStore;
  DownloadService? downloadService;

  bool downloadForeground = true;

  List<StoreDirectory>? stores;

  Stream<DownloadProgress>? _downloadProgress;
  Stream<DownloadProgress>? get downloadProgress => _downloadProgress;
  void setDownloadProgress(
    Stream<DownloadProgress>? newStream, {
    bool notify = true,
  }) {
    _downloadProgress = newStream;
    // if (notify) notifyListeners();
  }

  getAvailableStores({List<StoreDirectory>? availableStores}) async {
    if (availableStores != null || availableStores!.isNotEmpty) {
      stores = availableStores;
    } else {
      stores = await FMTC.instance.rootDirectory.stats.storesAvailableAsync;
    }
  }

  createStoreForBaseMap() async {
    _baseMapStore = FMTC.instance(baseMapStoreData['storeName']!);
    await _baseMapStore!.manage.createAsync();
    await _baseMapStore!.metadata.addAsync(
      key: 'sourceURL',
      value: baseMapStoreData["sourceURL"]!,
    );
    await _baseMapStore!.metadata.addAsync(
      key: 'validDuration',
      value: baseMapStoreData["validDuration"]!,
    );
    await _baseMapStore!.metadata.addAsync(
      key: 'maxLength',
      value: baseMapStoreData["maxLength"]!,
    );
  }

  importStore({required List<File> files}) async {
    FMTC.instance.rootDirectory.import.withGUI(
        // [...files],
        );
  }

  get getBaseMapStore => stores![0];
  get getBaseMapStoreMeta => stores![0].metadata;

  get getBathymetryMapStore => stores![1];
  get getBathymetryMapStoreMeta => stores![1].metadata;

  createbathymetryLayerStore() async {
    bathymetryLayerStore = FMTC.instance(bathyMapStoreData['storeName']!);
    await bathymetryLayerStore!.manage.createAsync();
    await bathymetryLayerStore!.metadata.addAsync(
      key: 'sourceURL',
      value: bathyMapStoreData["sourceURL"]!,
    );
    await bathymetryLayerStore!.metadata.addAsync(
      key: 'validDuration',
      value: bathyMapStoreData["validDuration"]!,
    );
    await bathymetryLayerStore!.metadata.addAsync(
      key: 'maxLength',
      value: bathyMapStoreData["maxLength"]!,
    );
  }

  clearDataFromStore() async {
    await getBaseMapStore?.manage.delete();
    await getBathymetryMapStore?.manage.delete();
  }

  downloadBaseMapStore({
    required bool downloadForeground,
    required LatLngBounds bound,
    required int minZoom,
    required int maxZoom,
  }) async {
    await createStoreForBaseMap();
    final Map<String, String> metadata = await _baseMapStore!.metadata.readAsync;
    BaseRegion? region = RegionService().getBaseMapRegionFromCoOrdinates(bound);
    int parallelThreads = 5;
    if (downloadForeground == true) {
      setDownloadProgress(_baseMapStore!.download
          .startForeground(
              region: region!.toDownloadable(
                  minZoom,
                  maxZoom,
                  TileLayer(
                    urlTemplate: metadata['sourceURL'],
                  ),
                  // preventRedownload: ,
                  seaTileRemoval: false,
                  // parallelThreads: (await SharedPreferences.getInstance()).getBool(
                  //           'bypassDownloadThreadsLimitation',
                  //         ) ??
                  //         false
                  //     ? 10
                  //     : 2,
                  parallelThreads: parallelThreads))
          .asBroadcastStream());
    } else {
      // DOWNLOAD BACKGROUND
      _baseMapStore!.download.startBackground(
          region: region!.toDownloadable(
              minZoom,
              maxZoom,
              TileLayer(
                urlTemplate: metadata['sourceURL'],
              ),
              // preventRedownload: ,
              seaTileRemoval: false,
              // parallelThreads: (await SharedPreferences.getInstance()).getBool(
              //           'bypassDownloadThreadsLimitation',
              //         ) ??
              //         false
              //     ? 10
              //     : 2,
              parallelThreads: parallelThreads));
    }
  }

  downloadBathyMetryMapStore({
    required bool downloadForeground,
    required LatLngBounds bound,
    required int minZoom,
    required int maxZoom,
  }) async {
    await createbathymetryLayerStore();
    final Map<String, String> metadata = await bathymetryLayerStore!.metadata.readAsync;
    BaseRegion? region = RegionService().getBaseMapRegionFromCoOrdinates(bound);
    int parallelThreads = 5;
    if (downloadForeground == true) {
      setDownloadProgress(bathymetryLayerStore!.download
          .startForeground(
              region: region!.toDownloadable(
                  minZoom,
                  maxZoom,
                  TileLayer(
                    urlTemplate: metadata['sourceURL'],
                  ),
                  // preventRedownload: ,
                  seaTileRemoval: false,
                  // parallelThreads: (await SharedPreferences.getInstance()).getBool(
                  //           'bypassDownloadThreadsLimitation',
                  //         ) ??
                  //         false
                  //     ? 10
                  //     : 2,
                  parallelThreads: parallelThreads))
          .asBroadcastStream());
    } else {
      // DOWNLOAD BACKGROUND
      bathymetryLayerStore!.download.startBackground(
          region: region!.toDownloadable(
              minZoom,
              maxZoom,
              TileLayer(
                urlTemplate: metadata['sourceURL'],
              ),
              // preventRedownload: ,
              seaTileRemoval: false,
              // parallelThreads: (await SharedPreferences.getInstance()).getBool(
              //           'bypassDownloadThreadsLimitation',
              //         ) ??
              //         false
              //     ? 10
              //     : 2,
              parallelThreads: parallelThreads));
    }
  }

  // GET STORE
}

class RegionService {
  BaseRegion? _baseMapRegion;
  BaseRegion? _bathyMetryRegion;
  BaseRegion? _internationalBorderRegion;

  BaseRegion? get baseMapRegion => _baseMapRegion;
  set baseMapRegion(BaseRegion? region) {
    if (region != null) {
      _baseMapRegion = region;
    }
  }

  BaseRegion? getBaseMapRegionFromCoOrdinates(LatLngBounds bound) {
    _baseMapRegion = RectangleRegion(bound
        // LatLngBounds(_coordsTopLeft!, _coordsBottomRight!),
        );
    return _baseMapRegion;
  }

  BaseRegion? get bathyMetryRegion => _bathyMetryRegion;
  set bathyMetryRegion(BaseRegion? region) {
    if (region != null) {
      _bathyMetryRegion = region;
    }
  }

  // RectangleRegion(
  //           LatLngBounds(_coordsTopLeft!, _coordsBottomRight!),
  //         )
}
