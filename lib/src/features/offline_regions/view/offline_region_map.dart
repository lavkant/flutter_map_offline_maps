import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/bloc/offline_regions_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/bloc/regions_sqlite_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/models/region_with_bounds_model.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/view/custom_layer.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/view/offline_map_screen2.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/store_service2.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

class CustomMap extends StatefulWidget {
  final String? damagedDatabaseDeleted;

  const CustomMap({super.key, this.damagedDatabaseDeleted});

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  final stackKey = GlobalKey();
  late Future<List<StoreDirectory>> _stores;
  List<RegionBound>? _regionBoundsFromDB;
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

  initilizer() async {
    GetIt.instance<StoreService2>().createStoreForBaseMap();
    GetIt.instance<StoreService2>().createbathymetryLayerStore();
    await loadUpdatedRegions();
  }

  loadUpdatedRegions() async {
    _regionBoundsFromDB = await GetIt.instance<RegionsSqliteBloc>().getAllRegionBounds();
  }

  void download(double minLat, double minLon, double maxLat, double maxLon) {
    // Implement your download logic here
    debugPrint('Download tiles for box: $minLat, $minLon, $maxLat, $maxLon');
  }

  @override
  Widget build(BuildContext context) {
    // mapState = FlutterMapState.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OfflineMapScreen2()));
        },
        child: const Icon(Icons.arrow_right_alt_outlined),
      ),
      body: StreamBuilder(
          stream: GetIt.instance<OfflineRegionsBloc>().loadingController,
          builder: (context, snapshot) {
            loadUpdatedRegions();
            return StreamBuilder<DownloadProgress>(
                stream: GetIt.instance<StoreService2>().downloadProgress,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SizedBox(height: 50, child: Text(snapshot.error.toString()));
                  }

                  return Stack(
                    children: [
                      FlutterMap(
                          options: MapOptions(
                            center: LatLng(15.06, 78.12),
                            zoom: 3.5,
                            // maxBounds: LatLngBounds(LatLng(3.8539, 52.006), LatLng(31.0418, 102.1124)),

                            // maxZoom: 3.5,
                            // minZoom: 3.5,
                            // bounds: LatLngBounds(LatLng(3.8539, 52.0 06), LatLng(31.0418, 102.1124))
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibGF2a2FudCIsImEiOiJjbG9qemdzZ3MyNGRoMnFvaWxzMjYzemtoIn0.3lnV7d77eu-M8DnFZpRcoQ",
                              tileProvider: NetworkNoRetryTileProvider(),
                            ),
                            CustomLayer(
                              polygons: GetIt.instance<OfflineRegionsBloc>().polygons,
                              regionBounds: _regionBoundsFromDB,
                            )
                          ]),
                      if (snapshot.data?.percentageProgress != null && snapshot.data?.percentageProgress != 100.0)
                        Container(
                          color: Colors.grey.withOpacity(0.2),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                              Text(
                                "${snapshot.data?.percentageProgress.toInt()}%",
                                style: const TextStyle(color: Colors.black),
                              )
                            ],
                          ),
                        )
                    ],
                  );
                });
          }),
      bottomNavigationBar: StreamBuilder(
        stream: GetIt.instance<StoreService2>().loadingController,
        builder: (context, snapshot) {
          return StreamBuilder<DownloadProgress>(
            stream: GetIt.instance<StoreService2>().downloadProgress,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SizedBox(height: 50, child: Text(snapshot.error.toString()));
              }

              return SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Text("${snapshot.data?.percentageProgress} %"),
                      IconButton(
                        onPressed: () {
                          GetIt.instance<StoreService2>().clearDataFromStore();
                          GetIt.instance<OfflineRegionsBloc>().removeAllDownloadStatusAndRegions();
                        },
                        icon: const Icon(Icons.delete_forever),
                      )
                    ],
                  ));
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    GetIt.instance<OfflineRegionsBloc>().dispose();
    super.dispose();
  }
}
