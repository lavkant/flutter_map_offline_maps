import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/models/offline_region_model.dart';
import 'package:flutter_map_offline_poc/src/features/offline_regions/models/region_with_bounds_model.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/store_service2.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
// import 'package:flutter_map_offline_poc/src/services/proximity_service/proximity_service.dart';

class CustomLayer extends StatefulWidget {
  final List<PolygonData>? polygons;
  final List<RegionBound>? regionBounds;

  const CustomLayer({super.key, this.polygons, this.regionBounds});

  @override
  State<CustomLayer> createState() => _CustomLayerState();
}

class _CustomLayerState extends State<CustomLayer> {
  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.of(context);

    if (widget.polygons != null) {
      return Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              ...widget.polygons!.map((e) {
                final index = widget.polygons?.indexOf(e);
                return DrawComponent(
                  offsets: e.polygonPoints.map((e) => mapState.getOffsetFromOrigin(e)).toList(),
                  points: e.polygonPoints.map((e) => e).toList(),
                  regionBound: widget.regionBounds!.elementAt(index!),
                );
              }).toList(),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}

class DrawComponent extends StatelessWidget {
  final List<Offset> offsets;
  final List<LatLng> points;
  final RegionBound regionBound;
  const DrawComponent({super.key, required this.offsets, required this.points, required this.regionBound});

  @override
  Widget build(BuildContext context) {
    final x1 = offsets[0].dx;
    final y1 = offsets[0].dy;

    final x2 = offsets[1].dx;
    final y2 = offsets[1].dy;

    final x3 = offsets[2].dx;
    final y3 = offsets[2].dy;

    final x4 = offsets[3].dx;
    final y4 = offsets[3].dy;

    final height = y3 - y2;
    final width = x2 - x1;

    final topLeft = points[0];
    final bottomRight = points[2];

    return Positioned(
        left: x1,
        top: y1,
        child: Container(
          decoration: BoxDecoration(
              color: regionBound.isDownloaded == true ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
              border: Border.all(width: 0.2)),
          height: height,
          width: width,
          child: GestureDetector(
              onTap: () async {
                debugPrint("TOP LEFT $topLeft BOTTOM RIGHT $bottomRight");
                GetIt.instance<StoreService2>().downloadBasemap(regionName: regionBound.name);
              },
              child: regionBound.isDownloaded == false
                  ? Icon(
                      Icons.download,
                      color: Colors.black.withOpacity(0.1),
                    )
                  : Icon(
                      Icons.check,
                      color: Colors.black.withOpacity(0.1),
                    )

              // child: Text(
              //   "$topLeft $bottomRight",
              //   style: const TextStyle(fontSize: 10),
              // ),
              ),
        ));
  }
}
