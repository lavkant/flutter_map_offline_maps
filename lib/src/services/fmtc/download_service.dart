import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_map_offline_poc/src/constants/constants.dart';
import 'package:flutter_map_offline_poc/src/services/file_handling/file_handling_service.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  late final String _downloadPath;
  final String _prefsKey = 'download_task_ids';

  // ReceivePort _port = ReceivePort();
  late SharedPreferences _prefs;

  List<String> _downloadTaskIds = [];
  static final BehaviorSubject<Map<String, dynamic>> _downloadStatusSubject = BehaviorSubject.seeded({});

  BehaviorSubject<Map<String, dynamic>> get downloadStatusController => _downloadStatusSubject;

  DownloadService() {
    initialize();
  }

  Future<void> initialize() async {
    await FlutterDownloader.initialize(debug: true);
    // _downloadPath = '${(await getExternalStorageDirectory())?.path}/$_downloadDir';
    _downloadPath =
        await GetIt.instance<FileHandlingService>().getExternalStoragePath(additionalPath: AppConstants.downloadPath);

    await Directory(_downloadPath).create(recursive: true);
    await FlutterDownloader.registerCallback(downloadCallback);

    _prefs = await SharedPreferences.getInstance();
    _downloadTaskIds = _prefs.getStringList(_prefsKey) ?? [];
  }

  Future<void> storeDownloadTaskIds() async {
    await _prefs.setStringList(_prefsKey, _downloadTaskIds);
  }

  Future<void> downloadFMTCFile(String url, String fileName) async {
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: _downloadPath,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    ).whenComplete(() {
      // GetIt.instance<StoreService>().importStore(files: [File('$_downloadPath/$fileName')]);
    });
    if (taskId != null) {
      _downloadTaskIds.add(taskId);
      await storeDownloadTaskIds();
    } else {
      debugPrint("$fileName Failed to download");
    }
  }

  Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  Future<void> resumeDownload(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
  }

  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
    _downloadTaskIds.remove(taskId);
    await storeDownloadTaskIds();
  }

  static void downloadCallback(String id, int status, int progress) {
    // Handle download callback here
    // You can broadcast this status to listeners using a stream

    final downloadStatus = {
      "taskId": id,
      "progress": progress,
      "status": status,
      "fileName": id, // You might want to update this to get the actual file name
    };

    // Send the download status to the BehaviorSubject
    _downloadStatusSubject.add(downloadStatus);
    debugPrint('Download task ($id) is in status ($status) with progress ($progress)');
  }

  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    // Return a list of downloads with their details (ID, status, progress, etc.)
    final downloads = await FlutterDownloader.loadTasks();
    if (downloads == null) {
      debugPrint("Failed to get download list");
    }
    // return downloads.map((task) => task.toMap()).toList();
    return downloads!
        .map((e) => {
              "taskId": e.taskId,
              "progress": e.progress,
              "status": e.status,
              "fileName": e.filename,
            })
        .toList();
    // }
  }

  Future<void> clearAllDownloads() async {
    final tasks = await FlutterDownloader.loadTasks();

    if (tasks == null || tasks.isEmpty) {
      debugPrint("Nothing to delete No downloads found");
      return;
    }

    for (final task in tasks) {
      await FlutterDownloader.cancel(taskId: task.taskId);
      await FlutterDownloader.remove(taskId: task.taskId, shouldDeleteContent: true);
    }
  }
}
