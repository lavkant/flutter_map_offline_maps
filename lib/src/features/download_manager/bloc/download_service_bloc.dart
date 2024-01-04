import 'dart:async';

import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

class DownloadServiceBloc {
  final BehaviorSubject<bool> _loadingController = BehaviorSubject.seeded(false);
  final BehaviorSubject<List<Map<String, dynamic>>> _downloadsController = BehaviorSubject.seeded([]);

  // Streams
  BehaviorSubject<bool> get loadingController => _loadingController;
  BehaviorSubject<List<Map<String, dynamic>>> get downloadsController => _downloadsController;

  // Getters
  bool get loading => _loadingController.value ?? false;
  List<Map<String, dynamic>> get downloads => _downloadsController.value ?? [];

  // Methods
  Future<void> initialize() async {
    // Initialize your download service or any other setup here
    GetIt.instance<DownloadService>().initialize();
  }

  Future<void> downloadFMTCFile(String url, String fileName) async {
    _loadingController.add(true);

    // Perform download using your download service
    await GetIt.instance<DownloadService>().downloadFMTCFile(url, fileName);

    // Update downloads list
    await _updateDownloadsList();

    _loadingController.add(false);
  }

  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    // _loadingController.add(true);

    // _loadingController.add(false);
    return await GetIt.instance<DownloadService>().getAllDownloads();
    // return [{}];
  }

  Future<void> pauseDownload(String taskId) async {
    // Perform pause download using your download service
    // Example: await GetIt.instance<DownloadService>().pauseDownload(taskId);

    // Update downloads list
    await _updateDownloadsList();
  }

  Future<void> resumeDownload(String taskId) async {
    _loadingController.add(true);

    // Perform resume download using your download service
    await GetIt.instance<DownloadService>().resumeDownload(taskId);

    // Update downloads list
    await _updateDownloadsList();

    _loadingController.add(false);
  }

  Future<void> cancelDownload(String taskId) async {
    _loadingController.add(true);

    // Perform cancel download using your download service
    await GetIt.instance<DownloadService>().cancelDownload(taskId);

    // Update downloads list
    await _updateDownloadsList();

    _loadingController.add(false);
  }

  Future<void> clearAllDownloads() async {
    _loadingController.add(true);

    // Perform clear all downloads using your download service
    await GetIt.instance<DownloadService>().clearAllDownloads();

    // Update downloads list
    await _updateDownloadsList();

    _loadingController.add(false);
  }

  Future<void> _updateDownloadsList() async {
    // Update downloads list using your download service
    _loadingController.add(true);
    final downloads = await GetIt.instance<DownloadService>().getAllDownloads();
    _downloadsController.add(downloads);
    _loadingController.add(false);
  }

  void dispose() {
    _loadingController.close();
    _downloadsController.close();
  }
}

// final DownloadServiceBloc downloadServiceBloc = DownloadServiceBloc();
