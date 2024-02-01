import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_offline_poc/src/features/region_selecor/bloc/map_state_controller.dart';
import 'package:flutter_map_offline_poc/src/features/region_selecor/model/region_mode.dart';
import 'package:flutter_map_offline_poc/src/features/region_selecor/view/cross_hair.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

class RegionSelectorMapView extends StatefulWidget {
  const RegionSelectorMapView({
    Key? key,
  }) : super(key: key);

  @override
  State<RegionSelectorMapView> createState() => _RegionSelectorMapViewState();
}

class _RegionSelectorMapViewState extends State<RegionSelectorMapView> {
  late MapController _mapController;
  late MapStateController _mapStateController;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
    _mapStateController = MapStateController(_mapController, context);

    _mapStateController.initStreams();
    _mapStateController.region = _mapStateController.regionMode == RegionMode.circle
        ? CircleRegion(
            _mapStateController.centerStream.value ?? LatLng(0, 0), _mapStateController.radiusStream.valueOrNull ?? 0)
        : RectangleRegion(
            LatLngBounds(_mapStateController.coordsTopLeftStream.valueOrNull ?? LatLng(0, 0),
                _mapStateController.coordsBottomRightStream.valueOrNull ?? LatLng(0, 0)),
          );
  }

  final String urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRegionModeMenu(context),
        child: const Icon(Icons.map),
      ),
      body: Stack(
        key: _mapStateController.mapKey,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(51.509364, -0.128928),
              zoom: 9.2,
              maxZoom: 22,
              maxBounds: LatLngBounds.fromPoints([
                LatLng(-90, 180),
                LatLng(90, 180),
                LatLng(90, -180),
                LatLng(-90, -180),
              ]),
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              scrollWheelVelocity: 0.002,
              keepAlive: true,
              onMapReady: () {
                _mapStateController.updatePointLatLng();
                _mapStateController.countTiles();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: urlTemplate,
                maxZoom: 20,
                keepBuffer: 5,
                backgroundColor: const Color(0xFFaad3df),
              ),
              if (_mapStateController.shouldShowTargetPolygon)
                _mapStateController.buildTargetPolygon(_mapStateController),
            ],
          ),
          if (_mapStateController.shouldShowCrosshairs) ...[
            StreamBuilder<Point<double>?>(
              stream: _mapStateController.crosshairsTopStream,
              builder: (context, snapshot) {
                Point<double>? crosshairsTop = snapshot.data;
                double top = crosshairsTop?.y ?? 0.0;
                double left = crosshairsTop?.x ?? 0.0;

                return Positioned(
                  top: top,
                  left: left,
                  child: const Crosshairs(),
                );
              },
            ),
            StreamBuilder<Point<double>?>(
              stream: _mapStateController.crosshairsBottomStream,
              builder: (context, snapshot) {
                Point<double>? crosshairsBottom = snapshot.data;
                double top = crosshairsBottom?.y ?? 0.0;
                double left = crosshairsBottom?.x ?? 0.0;

                return Positioned(
                  top: top,
                  left: left,
                  child: const Crosshairs(),
                );
              },
            ),
          ],
          Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 50,
                child: Column(
                  children: [
                    StreamBuilder(
                        stream: _mapStateController.coordsTopLeftStream,
                        builder: (context, snapshot) {
                          return Text(
                              "Lat ${snapshot.data?.longitude.toString()} ${snapshot.data?.longitude.toString()}");
                        }),
                    StreamBuilder(
                        stream: _mapStateController.coordsBottomRightStream,
                        builder: (context, snapshot) {
                          return Text(
                              "Lon ${snapshot.data?.latitude.toString()} ${snapshot.data?.longitude.toString()}");
                        }),
                  ],
                ),
              )),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: Colors.white,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    StreamBuilder(
                        stream: _mapStateController.regionTilesStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            return const CircularProgressIndicator(
                              strokeWidth: 1,
                            );
                          }
                          return Text("Tiles Count : ${snapshot.data.toString()}");
                        })
                  ],
                ),
              ))
        ],
      ),
    );
  }

  void _showRegionModeMenu(BuildContext context) async {
    final selectedMode = await showMenu<RegionMode>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 100, 0, 0),
      items: [
        const PopupMenuItem<RegionMode>(
          value: RegionMode.square,
          child: Text('Square'),
        ),
        const PopupMenuItem<RegionMode>(
          value: RegionMode.rectangleVertical,
          child: Text('Vertical Rectangle'),
        ),
        const PopupMenuItem<RegionMode>(
          value: RegionMode.rectangleHorizontal,
          child: Text('Horizontal Rectangle'),
        ),
        // const PopupMenuItem<RegionMode>(
        //   value: RegionMode.circle,
        //   child: Text('Circle'),
        // ),
      ],
      elevation: 8.0,
    );

    if (selectedMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapStateController.regionMode = selectedMode;
        _mapStateController.updatePointLatLng();
      });

      // You might want to trigger other logic based on the selected region mode.
    }
  }
}
