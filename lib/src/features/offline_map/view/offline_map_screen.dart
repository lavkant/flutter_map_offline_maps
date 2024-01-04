import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/bloc/map_ui_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/view/component/marker_widget.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/import_store_service.dart';
// import 'package:flutter_map_offline_poc/src/services/fmtc/store_service.dart';
import 'package:flutter_map_offline_poc/src/services/marker_service/marker_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:lat_lon_grid_plugin/lat_lon_grid_plugin.dart';
import 'package:latlong2/latlong.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({
    super.key,
  });

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final MarkerService markerService = MarkerService();
  final _mapKey = GlobalKey<State<StatefulWidget>>();
  final MapController _mapController = MapController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    markerService.getMarkers();
    // Listen to location changes
    Geolocator.getPositionStream().listen((Position position) {
      // setState(() {
      _currentPosition = position;
      // });
    });
    _getCurrentLocation();
    GetIt.instance<ImportStoreService>().getAvailableStores();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _showAddMarkerDialog(BuildContext context, LatLng position) async {
    TextEditingController notesController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Marker'),
          content: Column(
            children: [
              const Text('Enter notes:'),
              TextField(controller: notesController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await markerService.addMarker(position, notesController.text);
                await markerService.getMarkers();
                // setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditMarkerDialog(BuildContext context, CustomMarker marker) async {
    TextEditingController notesController = TextEditingController(text: marker.notes);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Marker'),
          content: Column(
            children: [
              const Text('Enter new notes:'),
              TextField(controller: notesController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await markerService.editMarker(marker.id!, notesController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await markerService.clearMarkers();
          },
          child: const Icon(Icons.delete_forever),
        ),
        body: Stack(
          children: [
            StreamBuilder(
                stream: mapUIBloc.loadingController,
                builder: (context, snapshot) {
                  if (snapshot.hasError || GetIt.instance<ImportStoreService>().getBaseMapStore == null) {
                    return const Center(
                      child: SizedBox(
                        child: Text("Something went wrong"),
                      ),
                    );
                  }
                  return FlutterMap(
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
                      onLongPress: (tapPosition, point) {
                        _showAddMarkerDialog(context, point);
                      },
                    ),

                    // nonRotatedChildren: buildStdAttribution(
                    //   urlTemplate,
                    //   alignment: AttributionAlignment.bottomLeft,
                    // ),
                    children: [
                      if (_currentPosition?.latitude != null && _currentPosition?.longitude != null)
                        LocationMarkerLayer(
                            position: LocationMarkerPosition(
                                latitude: _currentPosition?.latitude ?? 0,
                                longitude: _currentPosition?.longitude ?? 0,
                                accuracy: _currentPosition?.accuracy ?? 0)),
                      TileLayer(
                        backgroundColor: Colors.transparent,
                        urlTemplate: GetIt.instance<ImportStoreService>().getBaseMapStoreMeta.read['sourceURL'],
                        tileProvider: GetIt.instance<ImportStoreService>().getBaseMapStore != null
                            ? FMTC
                                .instance(GetIt.instance<ImportStoreService>().getBaseMapStore.storeName)
                                .getTileProvider(
                                  FMTCTileProviderSettings(
                                    behavior: CacheBehavior.cacheOnly,
                                    cachedValidDuration: int.parse(
                                              GetIt.instance<ImportStoreService>()
                                                  .getBaseMapStoreMeta
                                                  .read['validDuration']!,
                                            ) ==
                                            0
                                        ? Duration.zero
                                        : Duration(
                                            days: int.parse(
                                              GetIt.instance<ImportStoreService>()
                                                  .getBaseMapStoreMeta
                                                  .read['validDuration']!,
                                            ),
                                          ),
                                    maxStoreLength: int.parse(
                                      GetIt.instance<ImportStoreService>().getBaseMapStoreMeta.read['maxLength']!,
                                    ),
                                  ),
                                )
                            : NetworkNoRetryTileProvider(),
                        maxZoom: tempMaxZoom * 1.0,
                        // userAgentPackageName: 'dev.org.fmtc.example.app',
                        // panBuffer: 3,
                        // backgroundColor: const Color(0xFFaad3df),
                        // backgroundColor: Colors.transparent,
                      ),
                      if (mapUIBloc.enableBathyMetry == true &&
                          GetIt.instance<ImportStoreService>().getBathymetryMapStore != null)
                        TileLayer(
                          backgroundColor: Colors.transparent,

                          urlTemplate: GetIt.instance<ImportStoreService>().getBathymetryMapStoreMeta.read['sourceURL'],
                          tileProvider: GetIt.instance<ImportStoreService>().getBathymetryMapStore != null
                              ? FMTC
                                  .instance(GetIt.instance<ImportStoreService>().getBathymetryMapStore.storeName)
                                  .getTileProvider(
                                    FMTCTileProviderSettings(
                                      behavior: CacheBehavior.cacheOnly,
                                      cachedValidDuration: int.parse(
                                                GetIt.instance<ImportStoreService>()
                                                    .getBathymetryMapStoreMeta
                                                    .read['validDuration']!,
                                              ) ==
                                              0
                                          ? Duration.zero
                                          : Duration(
                                              days: int.parse(
                                                GetIt.instance<ImportStoreService>()
                                                    .getBathymetryMapStoreMeta
                                                    .read['validDuration']!,
                                              ),
                                            ),
                                      maxStoreLength: int.parse(
                                        GetIt.instance<ImportStoreService>()
                                            .getBathymetryMapStoreMeta
                                            .read['maxLength']!,
                                      ),
                                    ),
                                  )
                              : NetworkNoRetryTileProvider(),

                          // maxZoom: tempMaxZoom * 1.0,
                          // panBuffer: 3,
                          // backgroundColor:,
                        ),

                      if (mapUIBloc.enableGrid == true)
                        LatLonGridLayer(
                          options: LatLonGridLayerOptions(
                            lineWidth: 0.5,
                            lineColor: Colors.black87,
                            labelStyle: const TextStyle(
                              color: Colors.black87,
                              fontSize: 10.0,
                            ),
                            showCardinalDirections: true,
                            showCardinalDirectionsAsPrefix: false,
                            showLabels: true,
                            rotateLonLabels: true,
                            placeLabelsOnLines: false,
                            offsetLonLabelsBottom: 200.0,
                            offsetLatLabelsLeft: 20.0,
                          ),
                        ),

                      // if (markerService.markers.isNotEmpty)
                      // StreamBuilder(
                      //     stream: markerService.loadingController,
                      //     builder: (context, snapshot) {
                      //       return MarkerLayer(
                      //         markers: markerService.markers
                      //             .map((e) => Marker(
                      //                   point: e.position,
                      //                   builder: (context) {
                      //                     return MarkerWidget(
                      //                       marker: e,
                      //                       onEdit: () async {
                      //                         Navigator.pop(context);

                      //                         await _showEditMarkerDialog(context, e);
                      //                       },
                      //                       onDelete: () async {
                      //                         Navigator.pop(context);
                      //                         await markerService.removeMarker(e.id!);
                      //                       },
                      //                     );
                      //                   },
                      //                 ))
                      //             .toList(),
                      //       );
                      //     })
                      // if (markerService.markers.isNotEmpty)
                      if (mapUIBloc.enableCustomMarkers && markerService.markers.isNotEmpty)
                        StreamBuilder(
                            stream: markerService.loadingController,
                            builder: (context, snapshot) {
                              return MarkerClusterLayerWidget(
                                options: MarkerClusterLayerOptions(
                                  maxClusterRadius: 120,
                                  size: const Size(40, 40),
                                  // alignment: Alignment.center,
                                  // padding: const EdgeInsets.all(50),
                                  // maxZoom: 15,
                                  markers: markerService.markers
                                      .map((e) => Marker(
                                            point: e.position,
                                            builder: (context) {
                                              return MarkerWidget(
                                                marker: e,
                                                onEdit: () async {
                                                  Navigator.pop(context);

                                                  await _showEditMarkerDialog(context, e);
                                                },
                                                onDelete: () async {
                                                  Navigator.pop(context);
                                                  await markerService.removeMarker(e.id!);
                                                },
                                              );
                                            },
                                          ))
                                      .toList(),
                                  builder: (context, markers) {
                                    return Container(
                                      decoration:
                                          BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.blue),
                                      child: Center(
                                        child: Text(
                                          markers.length.toString(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),

                      // if (GetIt.instance<StoreService>().bathymetryLayerStore != null)
                    ],
                  );
                }),
            if (GetIt.instance<ImportStoreService>().getBaseMapStore != null)
              Positioned(
                  bottom: 60,
                  left: 10,
                  child: StreamBuilder(
                      stream: mapUIBloc.loadingController,
                      builder: (context, snapshot) {
                        return IconButton(
                            onPressed: () {
                              mapUIBloc.toggleCustomMarkers();
                            },
                            icon: mapUIBloc.enableCustomMarkers
                                ? const Icon(Icons.toggle_on_rounded)
                                : const Icon(Icons.toggle_off_rounded));
                      })),
            if (GetIt.instance<ImportStoreService>().getBaseMapStore != null)
              Positioned(
                  bottom: 30,
                  left: 10,
                  child: StreamBuilder(
                      stream: mapUIBloc.loadingController,
                      builder: (context, snapshot) {
                        return IconButton(
                            onPressed: () {
                              mapUIBloc.toggleGrid();
                            },
                            icon: mapUIBloc.enableGrid
                                ? const Icon(Icons.toggle_on_rounded)
                                : const Icon(Icons.toggle_off_rounded));
                      })),
            if (GetIt.instance<ImportStoreService>().getBathymetryMapStore != null)
              Positioned(
                  bottom: 10,
                  left: 10,
                  child: StreamBuilder(
                      stream: mapUIBloc.loadingController,
                      builder: (context, snapshot) {
                        return IconButton(
                            onPressed: () {
                              mapUIBloc.toggleBathyMetry();
                            },
                            icon: mapUIBloc.enableBathyMetry
                                ? const Icon(Icons.toggle_on_rounded)
                                : const Icon(Icons.toggle_off_rounded));
                      }))
          ],
        ));
  }
}
