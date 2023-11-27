import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_offline_poc/src/data/intial_data_offline.dart';
import 'package:flutter_map_offline_poc/src/services/map_box_tile_download_service/map_box_tile_download_service.dart';
import 'package:get_it/get_it.dart';

class OfflineMapScreen extends StatefulWidget {
  TileProvider tileProvider;
  OfflineMapScreen({super.key, required this.tileProvider});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await GetIt.instance<MapboxTileDownloadService>().clearDownloadedTiles();
        },
        child: const Icon(Icons.delete),
      ),
      body: FlutterMap(
        options: const MapOptions(maxZoom: tempMaxZoom * 1.0),
        children: [
          TileLayer(
            tileProvider: widget.tileProvider,
            maxZoom: 18.0,
            urlTemplate: '',
          ),
        ],
      ),
    );
  }
}
