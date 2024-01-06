import 'dart:convert';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_map_offline_poc/src/constants/constants.dart';
import 'package:flutter_map_offline_poc/src/services/file_handling/file_handling_service.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManagerService2 {
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  final BehaviorSubject<List<DownloadItem>> _downloads = BehaviorSubject<List<DownloadItem>>.seeded([]);

  BehaviorSubject<List<DownloadItem>> get downloads => _downloads;

  DownloadManagerService2() {
    FlutterDownloader.initialize(debug: true);
    initializeDirectory();
    _loadDownloads();
  }

  Future<void> initializeDirectory() async {
    final downloadPath = await GetIt.instance<FileHandlingService>().getExternalStoragePath(
      additionalPath: AppConstants.downloadPath,
    );

    await Directory(downloadPath).create(recursive: true);
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDownloads = prefs.getString('downloads');
    if (storedDownloads != null) {
      final List<dynamic> decodedDownloads = jsonDecode(storedDownloads);
      final List<DownloadItem> loadedDownloads =
          decodedDownloads.map((download) => DownloadItem.fromJson(download)).toList();

      _downloads.add(loadedDownloads);
    }
  }

  void _saveDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> downloadMapList = _downloads.value.map((download) => download.toJson()).toList();
    final String downloadJson = jsonEncode(downloadMapList);
    prefs.setString('downloads', downloadJson);
  }

  void addDownload(String url) async {
    final downloadItem = DownloadItem(url);
    _downloads.add([..._downloads.value, downloadItem]);

    final taskId = await _startDownload(url);
    downloadItem.taskId = taskId;

    _saveDownloads();
  }

  Future<String> _startDownload(String url) async {
    final localPath = await GetIt.instance<FileHandlingService>().getExternalStoragePath(
      additionalPath: AppConstants.downloadPath,
    );
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: localPath,
      showNotification: true,
      openFileFromNotification: true,
      headers: {},
    );
    // await FlutterDownloader.registerCallback();

    return taskId!;
  }

  DownloadItem _findDownloadItemByTaskId(String taskId) {
    return _downloads.value.firstWhere((item) => item.taskId == taskId);
  }

  void removeDownload(DownloadItem item) {
    _downloads.add(_downloads.value..remove(item));
    _saveDownloads();
  }

  void pauseDownload(DownloadItem item) async {
    await FlutterDownloader.pause(taskId: item.taskId);
  }

  void resumeDownload(DownloadItem item) async {
    await FlutterDownloader.resume(taskId: item.taskId);
  }
}

class DownloadItem {
  final String url;
  String taskId = '';
  double progress = 0.0;
  bool isPaused = false;

  DownloadItem(this.url);

  DownloadItem.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        taskId = json['taskId'],
        progress = json['progress'],
        isPaused = json['isPaused'] ?? false;

  Map<String, dynamic> toJson() => {
        'url': url,
        'taskId': taskId,
        'progress': progress,
        'isPaused': isPaused,
      };
}
