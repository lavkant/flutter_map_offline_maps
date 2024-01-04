import 'dart:io';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_sharing/fmtc_plus_sharing.dart';
import 'package:rxdart/rxdart.dart';

class ImportStoreService {
  // CREATE STORE
  StoreDirectory? baseMapStore;
  StoreDirectory? bathymetryLayerStore;
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  List<StoreDirectory>? stores;
  static const String _downloadDir = 'fmtc_downloads';
  final String _downloadPath = '';

  getAvailableStores({List<StoreDirectory>? availableStores}) async {
    // _downloadPath = '${(await getExternalStorageDirectory())?.path}/$_downloadDir';
    if (availableStores != null && availableStores.isNotEmpty) {
      stores = availableStores;
    } else {
      stores = await FMTC.instance.rootDirectory.stats.storesAvailableAsync;
    }
  }

  Future<List<Map<String, String>>> importStore({required List<File> files}) async {
    // FMTC.instance.rootDirectory.import.withGUI(
    //     // [...files],
    //     );

    Map<String, Future<ImportResult>> importResult = FMTC.instance.rootDirectory.import.manual(
      files,
      collisionHandler: (filename, storeName) {
        return true;
      },
    );

    final List<Map<String, String>> status = [{}];

    importResult.forEach((key, value) async {
      status.clear();
      await importResult[key]?.then((value) {
        status.add({value.storeName.toString(): value.successful.toString()});
      });
    });

    return status;

    // debugPrint(importResult['']);
  }

  get getBaseMapStore {
    loadingController.add(true);
    if (stores == null || stores!.isEmpty) {
      getAvailableStores();
    } else {
      baseMapStore = stores!.where((element) => element.storeName == "baseMap").first;
    }
    loadingController.add(false);

    return baseMapStore;
  }

  get getBaseMapStoreMeta {
    loadingController.add(true);

    if (stores == null || stores!.isEmpty) {
      getAvailableStores();
    } else {
      baseMapStore = stores!.where((element) => element.storeName == "baseMap").first;
    }
    loadingController.add(false);

    return baseMapStore?.metadata;
  }

  get getBathymetryMapStore {
    loadingController.add(true);

    if (stores == null || stores!.isEmpty) {
      getAvailableStores();
    } else {
      try {
        bathymetryLayerStore = stores!.where((element) => element.storeName == "bathyMetryLayer").first;
      } catch (e) {
        bathymetryLayerStore = null;
      }
    }
    loadingController.add(false);

    return bathymetryLayerStore;
  }

  get getBathymetryMapStoreMeta {
    loadingController.add(true);

    if (stores == null || stores!.isEmpty) {
      getAvailableStores();
    } else {
      bathymetryLayerStore = stores!.where((element) => element.storeName == "bathyMetryLayer").first;
    }
    loadingController.add(false);

    return bathymetryLayerStore?.metadata;
  }

  clearDataFromStore() async {
    loadingController.add(true);

    await getBaseMapStore?.manage.delete();
    await getBathymetryMapStore?.manage.delete();
    loadingController.add(false);
  }

  dispose() {
    loadingController.close();
  }
}
