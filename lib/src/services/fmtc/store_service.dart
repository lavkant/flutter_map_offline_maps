import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';

final Map<String, String> baseMapStoreData = {
  "storeName": "baseMap",
  "sourceURL":
      "https://api.mapbox.com/styles/v1/captainfreshin/cls8pagpx006j01qz6ycx8jn8/tiles/256/%7Bz%7D/%7Bx%7D/%7By%7D@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w",
  // "",
  "validDuration": "100",
  "maxLength": "20000"
};

final Map<String, String> bathyMapStoreData = {
  "storeName": "bathyMetryLayer",
  "sourceURL":
      "https://api.mapbox.com/styles/v1/captainfreshin/clcsqekjd001n14qz4f6xyorn/tiles/256/%7Bz%7D/%7Bx%7D/%7By%7D@2x?access_token=pk.eyJ1IjoiY2FwdGFpbmZyZXNoaW4iLCJhIjoiY2xjNXI0cGQ3MHQ3azNvbWg4eWprdWc2MyJ9.wMWDqLuaXJ2aUc8drxbv2w",
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

  Stream<DownloadProgress>? _downloadProgress;
  Stream<DownloadProgress>? get downloadProgress => _downloadProgress;
  void setDownloadProgress(
    Stream<DownloadProgress>? newStream, {
    bool notify = true,
  }) {
    _downloadProgress = newStream;
    // if (notify) notifyListeners();
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

  get getBaseMapStore => _baseMapStore;
  get getBaseMapStoreMeta => _baseMapStore?.metadata;

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
    await _baseMapStore?.manage.delete();
    await bathymetryLayerStore?.manage.delete();
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
