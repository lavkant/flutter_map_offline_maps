import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_offline_poc/src/features/region_selecor/bloc/download_provider.dart';
import 'package:flutter_map_offline_poc/src/features/region_selecor/model/region_mode.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';

class MapStateController {
  static const double _shapePadding = 15;
  static const _crosshairsMovement = Point<double>(10, 10);
  final mapKey = GlobalKey<State<StatefulWidget>>();
  final MapController mapController;
  final BuildContext context;

  late final StreamSubscription _polygonVisualizerStream;
  late final StreamSubscription _tileCounterTriggerStream;
  late final StreamSubscription _manualPolygonRecalcTriggerStream;

  late BehaviorSubject<Point<double>?> _crosshairsTop;
  late BehaviorSubject<Point<double>?> _crosshairsBottom;
  late BehaviorSubject<LatLng?> _coordsTopLeft;
  late BehaviorSubject<LatLng?> _coordsBottomRight;
  late BehaviorSubject<LatLng?> _center;
  late BehaviorSubject<double?> _radius;

  MapStateController(this.mapController, this.context);

  void initStreams() {
    _crosshairsTop = BehaviorSubject<Point<double>?>();
    _crosshairsBottom = BehaviorSubject<Point<double>?>();
    _coordsTopLeft = BehaviorSubject<LatLng?>();
    _coordsBottomRight = BehaviorSubject<LatLng?>();
    _center = BehaviorSubject<LatLng?>();
    _radius = BehaviorSubject<double?>();

    _manualPolygonRecalcTriggerStream = GetIt.instance<DownloadProvider>().manualPolygonRecalcTrigger.listen((_) {
      updatePointLatLng();
      countTiles();
    });
    // Provider.of<DownloadProvider>(context, listen: false).manualPolygonRecalcTrigger.stream.listen((_) {});

    _polygonVisualizerStream = mapController.mapEventStream.listen((_) => updatePointLatLng());
    _tileCounterTriggerStream =
        mapController.mapEventStream.debounceTime(const Duration(seconds: 1)).listen((_) => countTiles());
  }

  void disposeStreams() {
    _crosshairsTop.close();
    _crosshairsBottom.close();
    _coordsTopLeft.close();
    _coordsBottomRight.close();
    _center.close();
    _radius.close();

    _polygonVisualizerStream.cancel();
    _tileCounterTriggerStream.cancel();
    _manualPolygonRecalcTriggerStream.cancel();
  }

  bool get shouldShowTargetPolygon => downloadProvider.regionMode != RegionMode.circle;

  bool get shouldShowCrosshairs => _crosshairsTop.hasValue && _crosshairsBottom.hasValue;

  BehaviorSubject<Point<double>?> get crosshairsTopStream => _crosshairsTop;

  BehaviorSubject<Point<double>?> get crosshairsBottomStream => _crosshairsBottom;

  BehaviorSubject<LatLng?> get coordsTopLeftStream => _coordsTopLeft;

  BehaviorSubject<LatLng?> get coordsBottomRightStream => _coordsBottomRight;

  BehaviorSubject<LatLng?> get centerStream => _center;

  BehaviorSubject<double?> get radiusStream => _radius;

  DownloadProvider get downloadProvider => GetIt.instance<DownloadProvider>();

  void updatePointLatLng() {
    final Size mapSize = mapKey.currentContext!.size!;
    final bool isHeightLongestSide = mapSize.width < mapSize.height;

    final centerNormal = Point<double>(mapSize.width / 2, mapSize.height / 2);
    final centerInversed = Point<double>(mapSize.height / 2, mapSize.width / 2);

    late final Point<double> calculatedTopLeft;
    late final Point<double> calculatedBottomRight;

    switch (downloadProvider.regionMode) {
      case RegionMode.square:
        final double offset = (mapSize.shortestSide - (_shapePadding * 2)) / 2;

        calculatedTopLeft = Point<double>(
          centerNormal.x - offset,
          centerNormal.y - offset,
        );
        calculatedBottomRight = Point<double>(
          centerNormal.x + offset,
          centerNormal.y + offset,
        );
        break;
      case RegionMode.rectangleVertical:
        final allowedArea = Size(
          mapSize.width - (_shapePadding * 2),
          (mapSize.height - (_shapePadding * 2)) / 1.5 - 50,
        );

        calculatedTopLeft = Point<double>(
          centerInversed.y - allowedArea.shortestSide / 2,
          _shapePadding,
        );
        calculatedBottomRight = Point<double>(
          centerInversed.y + allowedArea.shortestSide / 2,
          mapSize.height - _shapePadding - 25,
        );
        break;
      case RegionMode.rectangleHorizontal:
        final allowedArea = Size(
          mapSize.width - (_shapePadding * 2),
          (mapSize.width < mapSize.height + 250)
              ? (mapSize.width - (_shapePadding * 2)) / 1.75
              : (mapSize.height - (_shapePadding * 2) - 0),
        );

        calculatedTopLeft = Point<double>(
          _shapePadding,
          centerNormal.y - allowedArea.height / 2,
        );
        calculatedBottomRight = Point<double>(
          mapSize.width - _shapePadding,
          centerNormal.y + allowedArea.height / 2 - 25,
        );
        break;
      case RegionMode.circle:
        final allowedArea = Size.square(mapSize.shortestSide - (_shapePadding * 2));

        final calculatedTop = Point<double>(
          centerNormal.x,
          (isHeightLongestSide ? centerNormal.y : centerInversed.x) - allowedArea.width / 2,
        );

        _crosshairsTop.add(calculatedTop - _crosshairsMovement);
        _crosshairsBottom.add(centerNormal - _crosshairsMovement);

        _center.add(mapController.pointToLatLng(_customPointFromPoint(centerNormal)));
        _radius.add(const Distance(roundResult: false).distance(
              _center.value!,
              mapController.pointToLatLng(_customPointFromPoint(calculatedTop))!,
            ) /
            1000);
        break;
    }

    if (downloadProvider.regionMode != RegionMode.circle) {
      _crosshairsTop.add(calculatedTopLeft - _crosshairsMovement);
      _crosshairsBottom.add(calculatedBottomRight - _crosshairsMovement);

      _coordsTopLeft.add(mapController.pointToLatLng(_customPointFromPoint(calculatedTopLeft)));
      _coordsBottomRight.add(mapController.pointToLatLng(_customPointFromPoint(calculatedBottomRight)));
    }

    downloadProvider.region = downloadProvider.regionMode == RegionMode.circle
        ? CircleRegion(_center.value!, _radius.value!)
        : RectangleRegion(
            LatLngBounds(_coordsTopLeft.value!, _coordsBottomRight.value!),
          );
  }

  Future<void> countTiles() async {
    if (downloadProvider.region != null) {
      downloadProvider
        ..regionTiles = null
        ..regionTiles = await FMTC.instance('').download.check(
              downloadProvider.region!.toDownloadable(
                downloadProvider.minZoom,
                downloadProvider.maxZoom,
                TileLayer(),
              ),
            );
    }
  }

  StreamBuilder buildTargetPolygon(MapStateController mapStateController) {
    return StreamBuilder(
        stream: mapStateController.downloadProvider.regionStream,
        builder: (context, snapshot) {
          return PolygonLayer(
            polygons: [
              Polygon(
                points: [
                  LatLng(-90, 180),
                  LatLng(90, 180),
                  LatLng(90, -180),
                  LatLng(-90, -180),
                ],
                holePointsList: [downloadProvider.region!.toOutline()],
                isFilled: true,
                borderColor: Colors.black,
                borderStrokeWidth: 2,
                color: Theme.of(context).colorScheme.background.withOpacity(2 / 3),
              ),
            ],
          );
        });
  }

  CustomPoint<E> _customPointFromPoint<E extends num>(Point<E> point) => CustomPoint(point.x, point.y);
}
