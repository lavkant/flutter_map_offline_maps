import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/view/component/store_tile.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/view/offline_map_screen.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/bloc/offline_regions_bloc.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/store_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get_it/get_it.dart';

class OfflineMapInit extends StatefulWidget {
  final String? damagedDatabaseDeleted;
  const OfflineMapInit({super.key, this.damagedDatabaseDeleted});

  @override
  State<OfflineMapInit> createState() => _OfflineMapInitState();
}

class _OfflineMapInitState extends State<OfflineMapInit> {
  late Future<List<StoreDirectory>> _stores;
  @override
  void initState() {
    if (widget.damagedDatabaseDeleted != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'At least one corrupted database has been deleted.\n${widget.damagedDatabaseDeleted}',
            ),
          ),
        ),
      );
    }
    initilizer();
    void listStores() => _stores = FMTC.instance.rootDirectory.stats.storesAvailableAsync;

    listStores();
    FMTC.instance.rootDirectory.stats.watchChanges().listen((_) {
      if (mounted) {
        listStores();
        setState(() {});
      }
    });

    // GetIt.instance<StoreService>().downloadProgress?.listen((event) {
    //   if (event.percentageProgress == 100) {
    //     ifMapDownlaodedMoveToMapScreen();
    //   }
    // });

    GetIt.instance<OfflineRegionsBloc>().loadCSVData(csvPath: 'assets/csv/squared_region.csv');

    super.initState();
  }

  void initilizer() async {
    // PROCESS ALL FIRST
    // offlineTileProvider!.preloadTiles();

    GetIt.instance<StoreService>().createStoreForBaseMap();
    GetIt.instance<StoreService>().createStoreForBaseMap2();

    GetIt.instance<StoreService>().createbathymetryLayerStore();

    // IN THE END TRY REDIRECTION
  }

  // IF MAP IS DOWNLOADED THEN GO TO MAP SCREEN DIRECT
  void ifMapDownlaodedMoveToMapScreen() async {
    // final isDownloaded = GetIt.instance<MapboxTileDownloadService>().isMapDownloaded;
    // ITS DOWNLOADED ON ANOTHER THREAD SO WE CANT LISTEN TO UPDATES

    // if (isDownloaded == true) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OfflineMapScreen()));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   Navigator.of(context).push(MaterialPageRoute<void>(
      //       builder: (_) => OfflineMapScreen(
      //             item: GetIt.instance<OfflineMapBloc>().userSelectedRegionToDownload!,
      //           )));
      // }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OfflineMapScreen()));
          // GetIt.instance<StoreService>().clearDataFromStore();
        },
        child: const Icon(Icons.fork_right),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<StoreDirectory>>(
                future: _stores,
                builder: (context, snapshot) => snapshot.hasError
                    ? throw snapshot.error! as FMTCDamagedStoreException
                    : snapshot.hasData
                        ? snapshot.data!.isEmpty
                            ? const SizedBox()
                            : ListView.builder(
                                itemCount: snapshot.data!.length,
                                // itemBuilder: (context, index) => ListTile(
                                //   title: Text(snapshot.data![index].storeName),
                                //   key: ValueKey(
                                //     snapshot.data![index].storeName,
                                //   ),
                                // ),
                                itemBuilder: (context, index) => StoreTile(
                                      store: snapshot.data![index],
                                    ))
                        : const CircularProgressIndicator(),
              ),
            ),
            TextButton(
                onPressed: () async {
                  await GetIt.instance<StoreService>().downloadBathyMetryMapStore(
                      downloadForeground: true, bound: tempBound, minZoom: tempMinZoom, maxZoom: tempMaxZoom);
                },
                child: const Text("Download BathyMetry")),
            TextButton(
                onPressed: () async {
                  await GetIt.instance<StoreService>().downloadBaseMapStore(
                      downloadForeground: true, bound: tempBound, minZoom: tempMinZoom, maxZoom: tempMaxZoom);
                },
                child: const Text("Download Base Map 1")),
            TextButton(
                onPressed: () async {
                  await GetIt.instance<StoreService>().downloadBaseMapStore2(
                      downloadForeground: true, bound: tempBound2, minZoom: tempMinZoom, maxZoom: tempMaxZoom);
                },
                child: const Text("Download Base Map 2")),
            TextButton(
                onPressed: () async {
                  await GetIt.instance<StoreService>().clearDataFromStore();
                },
                child: const Icon(Icons.delete)),
            const CircularProgressIndicator(),
            StreamBuilder<DownloadProgress>(
              stream: GetIt.instance<StoreService>().downloadProgress,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }

                return Text("${snapshot.data?.percentageProgress} %");
              },
            )
          ],
        ),
      ),
    );
  }
}
