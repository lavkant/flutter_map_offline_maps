// import 'dart:async';

// import 'package:flutter_map_offline_poc/src/features/region_selecor/model/region_mode.dart';
// import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
// import 'package:rxdart/rxdart.dart';

// class DownloadProvider {
//   final BehaviorSubject<RegionMode> _regionModeSubject = BehaviorSubject<RegionMode>.seeded(RegionMode.square);
//   Stream<RegionMode> get regionModeStream => _regionModeSubject.stream;

//   RegionMode get regionMode => _regionModeSubject.value;
//   set regionMode(RegionMode newMode) {
//     _regionModeSubject.add(newMode);
//   }

//   final BehaviorSubject<BaseRegion?> _regionSubject = BehaviorSubject<BaseRegion?>.seeded(null);
//   BehaviorSubject<BaseRegion?> get regionStream => _regionSubject;

//   BaseRegion? get region => _regionSubject.value;
//   set region(BaseRegion? newRegion) {
//     _regionSubject.add(newRegion);
//   }

//   final BehaviorSubject<int?> _regionTilesSubject = BehaviorSubject<int?>.seeded(null);
//   Stream<int?> get regionTilesStream => _regionTilesSubject.stream;

//   int? get regionTiles => _regionTilesSubject.value;
//   set regionTiles(int? newNum) {
//     _regionTilesSubject.add(newNum);
//   }

//   final BehaviorSubject<int> _minZoomSubject = BehaviorSubject<int>.seeded(1);
//   Stream<int> get minZoomStream => _minZoomSubject.stream;

//   int get minZoom => _minZoomSubject.value;
//   set minZoom(int newNum) {
//     _minZoomSubject.add(newNum);
//   }

//   final BehaviorSubject<int> _maxZoomSubject = BehaviorSubject<int>.seeded(16);
//   Stream<int> get maxZoomStream => _maxZoomSubject.stream;

//   int get maxZoom => _maxZoomSubject.value;
//   set maxZoom(int newNum) {
//     _maxZoomSubject.add(newNum);
//   }

//   final BehaviorSubject<StoreDirectory?> _selectedStoreSubject = BehaviorSubject<StoreDirectory?>.seeded(null);
//   Stream<StoreDirectory?> get selectedStoreStream => _selectedStoreSubject.stream;

//   StoreDirectory? get selectedStore => _selectedStoreSubject.value;
//   void setSelectedStore(StoreDirectory? newStore, {bool notify = true}) {
//     // if (notify) {
//     _selectedStoreSubject.add(newStore);
//     // }
//   }

//   final StreamController<void> _manualPolygonRecalcTrigger = StreamController<void>.broadcast();
//   Stream<void> get manualPolygonRecalcTrigger => _manualPolygonRecalcTrigger.stream;
//   void triggerManualPolygonRecalc() => _manualPolygonRecalcTrigger.add(null);

//   final BehaviorSubject<Stream<DownloadProgress>?> _downloadProgressSubject =
//       BehaviorSubject<Stream<DownloadProgress>?>.seeded(null);
//   Stream<Stream<DownloadProgress>?> get downloadProgressStream => _downloadProgressSubject.stream;

//   Stream<DownloadProgress>? get downloadProgress => _downloadProgressSubject.value;
//   void setDownloadProgress(Stream<DownloadProgress>? newStream, {bool notify = true}) {
//     _downloadProgressSubject.add(newStream);
//     // if (notify) notifyListeners();
//   }

//   final BehaviorSubject<bool> _preventRedownloadSubject = BehaviorSubject<bool>.seeded(false);
//   Stream<bool> get preventRedownloadStream => _preventRedownloadSubject.stream;

//   bool get preventRedownload => _preventRedownloadSubject.value;
//   set preventRedownload(bool newBool) {
//     _preventRedownloadSubject.add(newBool);
//   }

//   final BehaviorSubject<bool> _seaTileRemovalSubject = BehaviorSubject<bool>.seeded(true);
//   Stream<bool> get seaTileRemovalStream => _seaTileRemovalSubject.stream;

//   bool get seaTileRemoval => _seaTileRemovalSubject.value;
//   set seaTileRemoval(bool newBool) {
//     _seaTileRemovalSubject.add(newBool);
//   }

//   final BehaviorSubject<bool> _disableRecoverySubject = BehaviorSubject<bool>.seeded(false);
//   Stream<bool> get disableRecoveryStream => _disableRecoverySubject.stream;

//   bool get disableRecovery => _disableRecoverySubject.value;
//   set disableRecovery(bool newBool) {
//     _disableRecoverySubject.add(newBool);
//   }

//   final BehaviorSubject<DownloadBufferMode> _bufferModeSubject =
//       BehaviorSubject<DownloadBufferMode>.seeded(DownloadBufferMode.tiles);
//   Stream<DownloadBufferMode> get bufferModeStream => _bufferModeSubject.stream;

//   DownloadBufferMode get bufferMode => _bufferModeSubject.value;
//   set bufferMode(DownloadBufferMode newMode) {
//     _bufferModeSubject.add(newMode);
//     _bufferingAmountSubject.add(newMode == DownloadBufferMode.tiles ? 500 : 5000);
//   }

//   final BehaviorSubject<int> _bufferingAmountSubject = BehaviorSubject<int>.seeded(500);
//   Stream<int> get bufferingAmountStream => _bufferingAmountSubject.stream;

//   int get bufferingAmount => _bufferingAmountSubject.value;
//   set bufferingAmount(int newNum) {
//     _bufferingAmountSubject.add(newNum);
//   }

//   void dispose() {
//     _regionModeSubject.close();
//     _regionSubject.close();
//     _regionTilesSubject.close();
//     _minZoomSubject.close();
//     _maxZoomSubject.close();
//     _selectedStoreSubject.close();
//     _manualPolygonRecalcTrigger.close();
//     _downloadProgressSubject.close();
//     _preventRedownloadSubject.close();
//     _seaTileRemovalSubject.close();
//     _disableRecoverySubject.close();
//     _bufferModeSubject.close();
//     _bufferingAmountSubject.close();
//   }
// }
