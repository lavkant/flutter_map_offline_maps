import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/store_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({
    super.key,
  });

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final _mapKey = GlobalKey<State<StatefulWidget>>();
  final MapController _mapController = MapController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {},
        child: const Icon(Icons.delete),
      ),
      // body: FlutterMap(
      //   options: MapOptions(maxZoom: tempMaxZoom * 1.0),
      //   children: [
      //     TileLayer(
      //       tileProvider: FMTC.instance(baseMapStoreData['storeName']!).getTileProvider(
      //             FMTCTileProviderSettings(
      //               behavior: CacheBehavior.cacheOnly,
      //               cachedValidDuration: int.parse(
      //                         FMTC.instance(baseMapStoreData['storeName']!).metadata['validDuration'],
      //                       ) ==
      //                       0
      //                   ? Duration.zero
      //                   : Duration(
      //                       days: int.parse(GetIt.instance<StoreService>().getBaseMapStoreMeta['validDuration']),
      //                     ),
      //               maxStoreLength: int.parse(GetIt.instance<StoreService>().getBaseMapStoreMeta['maxLength']),
      //             ),
      //           ),
      //       maxZoom: tempMaxZoom * 1.0,
      //       urlTemplate: '',
      //     ),
      //   ],
      // ),
      body: FutureBuilder<Map<String, String>?>(
        future: GetIt.instance<StoreService>().getBaseMapStore == null
            ? Future.sync(() => {})
            : FMTC.instance(baseMapStoreData['storeName']!).metadata.readAsync,
        builder: (context, metadata) {
          if (!metadata.hasData ||
              metadata.data == null ||
              (GetIt.instance<StoreService>().getBaseMapStore != null && (metadata.data ?? {}).isEmpty)) {
            return const CircularProgressIndicator();
          }

          final String urlTemplate = GetIt.instance<StoreService>().getBaseMapStore != null && metadata.data != null
              ? metadata.data!['sourceURL']!
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: LatLng(16.159146, 73.332974),
                  zoom: tempMinZoom * 1.0,
                  maxZoom: tempMaxZoom * 1.0,
                  // maxBounds: LatLngBounds.fromPoints([
                  //   // LatLng(-90, 180),
                  //   // LatLng(90, 180),
                  //   // LatLng(90, -180),
                  //   // LatLng(-90, -180),
                  // ]),
                  interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  scrollWheelVelocity: 0.002,
                  keepAlive: true,
                  onMapReady: () {
                    // _updatePointLatLng();
                    // _countTiles();
                  },
                ),
                // nonRotatedChildren: buildStdAttribution(
                //   urlTemplate,
                //   alignment: AttributionAlignment.bottomLeft,
                // ),
                children: [
                  TileLayer(
                    urlTemplate: urlTemplate,
                    tileProvider: GetIt.instance<StoreService>().getBaseMapStore != null
                        ? FMTC.instance(baseMapStoreData['storeName']!).getTileProvider(
                              FMTCTileProviderSettings(
                                behavior: CacheBehavior.cacheOnly,
                                cachedValidDuration: int.parse(
                                          metadata.data!['validDuration']!,
                                        ) ==
                                        0
                                    ? Duration.zero
                                    : Duration(
                                        days: int.parse(
                                          metadata.data!['validDuration']!,
                                        ),
                                      ),
                                maxStoreLength: int.parse(
                                  metadata.data!['maxLength']!,
                                ),
                              ),
                            )
                        : NetworkNoRetryTileProvider(),
                    maxZoom: tempMaxZoom * 1.0,
                    userAgentPackageName: 'dev.org.fmtc.example.app',
                    panBuffer: 3,
                    backgroundColor: const Color(0xFFaad3df),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
