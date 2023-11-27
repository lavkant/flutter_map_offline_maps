import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/view/offline_map_screen.dart';
import 'package:flutter_map_offline_poc/src/services/map_box_tile_download_service/map_box_tile_download_service.dart';
import 'package:flutter_map_offline_poc/src/services/map_box_tile_download_service/offline_tile_provider.dart';
import 'package:get_it/get_it.dart';

class OfflineMapInit extends StatefulWidget {
  const OfflineMapInit({super.key});

  @override
  State<OfflineMapInit> createState() => _OfflineMapInitState();
}

class _OfflineMapInitState extends State<OfflineMapInit> {
  SQLiteTileProvider? offlineTileProvider;
  @override
  void initState() {
    initilizer();

    super.initState();
  }

  void initilizer() async {
    // PROCESS ALL FIRST
    offlineTileProvider =
        SQLiteTileProvider('tiles', 'offline_maps.db', await GetIt.instance<MapboxTileDownloadService>().database);
    // offlineTileProvider!.preloadTiles();
    await GetIt.instance<MapboxTileDownloadService>().checkIfMapDownload();
    final bool isDownloaded = GetIt.instance<MapboxTileDownloadService>().isMapDownloaded;
    if (isDownloaded) {
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => OfflineMapScreen(
                tileProvider: offlineTileProvider!,
              )));
      return;
    } else {
      final bool downloaded = await GetIt.instance<MapboxTileDownloadService>().downloadAndSaveTiles(
          tilesetUrl: finalUrlForDownload, bounds: tempBound, minZoom: tempMinZoom, maxZoom: tempMaxZoom);
      if (downloaded == true) {
        debugPrint("DOWNLOAD COMPLETE");
      } else {
        debugPrint("DOWNLOAD FAILED");
      }
    }
    // IN THE END TRY REDIRECTION
    ifMapDownlaodedMoveToMapScreen();
  }

  // IF MAP IS DOWNLOADED THEN GO TO MAP SCREEN DIRECT
  void ifMapDownlaodedMoveToMapScreen() async {
    final isDownloaded = GetIt.instance<MapboxTileDownloadService>().isMapDownloaded;
    // ITS DOWNLOADED ON ANOTHER THREAD SO WE CANT LISTEN TO UPDATES

    if (isDownloaded == true) {
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => OfflineMapScreen(
                tileProvider: offlineTileProvider!,
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   Navigator.of(context).push(MaterialPageRoute<void>(
      //       builder: (_) => OfflineMapScreen(
      //             item: GetIt.instance<OfflineMapBloc>().userSelectedRegionToDownload!,
      //           )));
      // }),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
