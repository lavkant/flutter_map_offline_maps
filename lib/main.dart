import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/app.dart';
import 'package:flutter_map_offline_poc/src/features/download_manager/bloc/download_service_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/bloc/offline_map_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/bloc/offline_map_init_screen_bloc.dart';
import 'package:flutter_map_offline_poc/src/services/databse/databse_helper.dart';
import 'package:flutter_map_offline_poc/src/services/file_handling/file_handling_service.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service2.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/import_store_service.dart';
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
    getIt.registerSingleton<ImportStoreService>(ImportStoreService(), signalsReady: true);

    getIt.registerSingleton<DownloadService>(DownloadService(), signalsReady: true);
    getIt.registerSingleton<DownloadServiceBloc>(DownloadServiceBloc(), signalsReady: true);
    getIt.registerSingleton<FileHandlingService>(FileHandlingService(), signalsReady: true);
    getIt.registerSingleton<OfflineMapInitScreenBloc>(OfflineMapInitScreenBloc(), signalsReady: true);

    // DOWNLOAD MANAGER SERVICE 2
    getIt.registerSingleton<DownloadManagerService2>(DownloadManagerService2(), signalsReady: true);

    // THIS WILL INTIALISE THE DATABASE
    await DatabaseHelper.database;

    // getIt.registerSingleton<MapboxTileDownloadService>(MapboxTileDownloadService(), signalsReady: true);
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await loadAllDependency();

  // Plugin must be initialized before using

  // INITIALIZE DOWNLOAD SERVICE
  // await GetIt.instance<DownloadService>().initialize();
  runApp(MyApp(damagedDatabaseDeleted: damagedDatabaseDeleted));
}
