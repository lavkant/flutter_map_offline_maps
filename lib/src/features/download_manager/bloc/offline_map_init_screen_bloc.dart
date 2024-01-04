import 'dart:io';

import 'package:flutter_map_offline_poc/src/constants/constants.dart';
import 'package:flutter_map_offline_poc/src/core/bloc/base_bloc.dart';
import 'package:flutter_map_offline_poc/src/services/file_handling/file_handling_service.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

class OfflineMapInitScreenBloc extends BaseBloc {
  // VARIABLES STREAM INITIALIZERS
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);
  List<File> availableFiles = [];

  // METHODS

  getAllDownloadedFMTCFiles() async {
    loadingController.add(true);
    final extenalDirectory =
        await GetIt.instance<FileHandlingService>().getExternalStoragePath(additionalPath: AppConstants.downloadPath);
    availableFiles =
        await GetIt.instance<FileHandlingService>().getAllFilesInDirectory(directoryPath: extenalDirectory);

    loadingController.add(false);
  }

  // GETTER

  // SETTER

  // DISPOSE

  clearData() {
    availableFiles.clear();
    loadingController.add(false);
  }

  @override
  dispose() {
    loadingController.close();
  }
}
