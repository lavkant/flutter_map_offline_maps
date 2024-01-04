import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_map_offline_poc/src/features/download_manager/bloc/download_service_bloc.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/view/offline_map_init_screen.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
// import 'package:flutter_map_offline_poc/src/services/fmtc/download_service.dart';
import 'package:get_it/get_it.dart';
// import 'package:your_project_path/download_service.dart';

class DownloadManagerScreen extends StatefulWidget {
  final String? damagedDatabaseDeleted;

  const DownloadManagerScreen({super.key, this.damagedDatabaseDeleted});

  @override
  _DownloadManagerScreenState createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  @override
  void initState() {
    // _initDownloadService();
    super.initState();
  }

  Future<void> _initDownloadService() async {
    await GetIt.instance<DownloadService>().initialize();

    // setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    GetIt.instance<DownloadServiceBloc>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: GetIt.instance<DownloadServiceBloc>().loadingController,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Download Manager'),
              actions: [
                IconButton(
                    onPressed: () {
                      GetIt.instance<DownloadServiceBloc>().clearAllDownloads();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear))
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => OfflineMapInit(
                          damagedDatabaseDeleted: widget.damagedDatabaseDeleted,
                        )));
                // GetIt.instance<StoreService>().clearDataFromStore();
              },
              child: const Icon(Icons.fork_right),
            ),
            body: FutureBuilder(
              future: GetIt.instance<DownloadServiceBloc>().getAllDownloads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final List<Map<String, dynamic>> downloads = snapshot.data as List<Map<String, dynamic>>;

                  if (downloads.isEmpty) {
                    // If no previous downloads, display two list tiles with hardcoded URLs
                    return Column(
                      children: [
                        _buildHardcodedDownloadTile(
                            'https://tmpfiles.org/dl/3755195/export_basemap.fmtc', 'export_baseMap.fmtc'),
                        _buildHardcodedDownloadTile(
                            'https://drive.google.com/uc?export=download&id=1C0-tS_P-14M7SfYjPVcWQ56Hz3f0srX3',
                            'export_bathyMetryLayer.fmtc'),
                      ],
                    );
                  } else {
                    return ListView.builder(
                      itemCount: downloads.length,
                      itemBuilder: (context, index) {
                        final download = downloads[index];
                        final String taskId = download['taskId'];
                        final String fileName = download['fileName'];
                        final int progress = download['progress'];
                        final DownloadTaskStatus status = download['status'];
                        final String statusText = _getStatusText(status);

                        return StreamBuilder(
                            stream: GetIt.instance<DownloadService>().downloadStatusController,
                            builder: (context, snapshot) {
                              return ListTile(
                                title: Text(fileName),
                                subtitle: Text('Status: $statusText, Progress: $progress%'),
                                trailing: _buildControls(taskId, status),
                              );
                            });
                      },
                    );
                  }
                }
              },
            ),
          );
        });
  }

  Widget _buildControls(String taskId, DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.undefined:
      case DownloadTaskStatus.failed:
        return ElevatedButton(
          onPressed: () => _startDownload(taskId),
          child: const Text('Start Download'),
        );
      case DownloadTaskStatus.enqueued:
        return ElevatedButton(
          onPressed: () => _pauseDownload(taskId),
          child: const Text('Pause'),
        );
      case DownloadTaskStatus.running:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _pauseDownload(taskId),
              child: const Text('Pause'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _cancelDownload(taskId),
              child: const Text('Cancel'),
            ),
          ],
        );
      case DownloadTaskStatus.complete:
        return ElevatedButton(
          onPressed: () => _resumeDownload(taskId),
          child: const Text('Resume'),
        );
      default:
        return Container();
    }
  }

  void _startDownload(String taskId) async {
    // Replace this with the actual URL and file name

    await GetIt.instance<DownloadServiceBloc>().resumeDownload(taskId);

    setState(() {});
  }

  void _pauseDownload(String taskId) async {
    await GetIt.instance<DownloadServiceBloc>().pauseDownload(taskId);
    setState(() {});
  }

  void _resumeDownload(String taskId) async {
    await GetIt.instance<DownloadServiceBloc>().resumeDownload(taskId);
    setState(() {});
  }

  void _cancelDownload(String taskId) async {
    await GetIt.instance<DownloadServiceBloc>().cancelDownload(taskId);
    setState(() {});
  }

  String _getStatusText(DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.undefined:
        return 'Undefined';
      case DownloadTaskStatus.enqueued:
        return 'Queued';
      case DownloadTaskStatus.running:
        return 'Running';
      case DownloadTaskStatus.complete:
        return 'Complete';
      case DownloadTaskStatus.failed:
        return 'Failed';
      case DownloadTaskStatus.canceled:
        return 'Canceled';
      case DownloadTaskStatus.paused:
        return 'Paused';
    }
  }

  Widget _buildHardcodedDownloadTile(String url, String fileName) {
    return ListTile(
      title: Text(fileName),
      subtitle: Text(
        'URL: $url',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10),
      ),
      trailing: ElevatedButton(
        onPressed: () => _startDownloadHardcoded(url, fileName),
        child: const Text('Start Download'),
      ),
    );
  }

  void _startDownloadHardcoded(String url, String fileName) async {
    await GetIt.instance<DownloadServiceBloc>().downloadFMTCFile(url, fileName);
    setState(() {});
  }
}
