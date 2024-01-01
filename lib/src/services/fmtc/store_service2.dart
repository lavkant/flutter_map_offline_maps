import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/bloc/offline_regions_bloc.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

class StoreService2 {
  // CREATE STORE
  StoreDirectory? _baseMapStore;

  StoreDirectory? bathymetryLayerStore;

  StoreDirectory? internationBoundryStore;

  DownloadService? downloadService;
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  bool downloadForeground = true;
  int parallelThreads = 10;

  Stream<DownloadProgress>? _downloadProgress;
  Stream<DownloadProgress>? get downloadProgress => _downloadProgress;
  void setDownloadProgress(
    Stream<DownloadProgress>? newStream, {
    bool notify = true,
  }) {
    loadingController.add(true);
    _downloadProgress = newStream;
    loadingController.add(false);

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

  void downloadBasemap({required String regionName}) async {
    await createStoreForBaseMap();
    final Map<String, String> metadata = await _baseMapStore!.metadata.readAsync;

    // BaseRegion? region = offlineRegionsBloc.getBaseRegionForBaseMap(regionName: regionName);
    BaseRegion? region = await GetIt.instance<OfflineRegionsBloc>().getBaseRegionForBaseMap(regionName: regionName);

    int parallelThreads = this.parallelThreads;
    if (downloadForeground == true) {
      setDownloadProgress(_baseMapStore!.download
          .startForeground(
              region: region!.toDownloadable(
                  tempMinZoom,
                  tempMaxZoom,
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
          .asBroadcastStream()
          .doOnDone(() {
        GetIt.instance<OfflineRegionsBloc>().updateBaseRegionDownloadStatus(regionName: regionName);
      }));
    } else {
      // DOWNLOAD BACKGROUND
      _baseMapStore!.download.startBackground(
          region: region!.toDownloadable(
              tempMinZoom,
              tempMaxZoom,
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

  downloadBathyMetryMapStore({required String regionName}) async {
    // await createbathymetryLayerStore();
    final Map<String, String> metadata = await bathymetryLayerStore!.metadata.readAsync;
    BaseRegion? region = GetIt.instance<OfflineRegionsBloc>().getBaseRegionForBaseMap(regionName: regionName);
    int parallelThreads = this.parallelThreads;
    if (downloadForeground == true) {
      setDownloadProgress(bathymetryLayerStore!.download
          .startForeground(
              region: region!.toDownloadable(
                  tempMinZoom,
                  tempMaxZoom,
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
              tempMinZoom,
              tempMaxZoom,
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
