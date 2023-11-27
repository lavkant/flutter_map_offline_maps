import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/app.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/bloc/offline_map_bloc.dart';
import 'package:flutter_map_offline_poc/src/services/map_box_tile_download_service/map_box_tile_download_service.dart';
import 'package:get_it/get_it.dart';

void main() async {
  GetIt getIt = GetIt.instance;

  loadAllDependency() async {
    //   getIt.registerSingleton<InitialBloc>(InitialBloc(), signalsReady: true);
    getIt.registerSingleton<OfflineMapBloc>(OfflineMapBloc(), signalsReady: true);
    getIt.registerSingleton<MapboxTileDownloadService>(MapboxTileDownloadService(), signalsReady: true);
  }

  await loadAllDependency();
  runApp(const MyApp());
}
