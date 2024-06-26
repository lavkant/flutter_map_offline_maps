import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/app.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/bloc/offline_map_bloc.dart';
import 'package:flutter_map_offline_poc/src/services/databse/databse_helper.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/store_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? damagedDatabaseDeleted;
  await FlutterMapTileCaching.initialise(
    errorHandler: (error) => damagedDatabaseDeleted = error.message,
    debugMode: true,
  );

  GetIt getIt = GetIt.instance;

  loadAllDependency() async {
    //   getIt.registerSingleton<InitialBloc>(InitialBloc(), signalsReady: true);
    getIt.registerSingleton<OfflineMapBloc>(OfflineMapBloc(), signalsReady: true);
    getIt.registerSingleton<StoreService>(StoreService(), signalsReady: true);
    // THIS WILL INTIALISE THE DATABASE
    await DatabaseHelper.database;

    // getIt.registerSingleton<MapboxTileDownloadService>(MapboxTileDownloadService(), signalsReady: true);
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await loadAllDependency();
  runApp(MyApp(damagedDatabaseDeleted: damagedDatabaseDeleted));
}
