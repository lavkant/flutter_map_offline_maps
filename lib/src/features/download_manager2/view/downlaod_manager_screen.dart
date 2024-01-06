import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_map_offline_poc/src/features/offline_map/view/offline_map_init_screen.dart';
import 'package:flutter_map_offline_poc/src/services/fmtc/download_service2.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

class DownloadManagerScreen2 extends StatefulWidget with WidgetsBindingObserver {
  final String? damagedDatabaseDeleted;
  const DownloadManagerScreen2({super.key, required this.damagedDatabaseDeleted});

  @override
  _DownloadManagerScreen2State createState() => _DownloadManagerScreen2State();
}

class _DownloadManagerScreen2State extends State<DownloadManagerScreen2> {
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);
  final ReceivePort _port = ReceivePort();
  List<Map> downloadsListMaps = [];

  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    loadingController.add(false);
    task();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    super.initState();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    loadingController.close();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) async {
      loadingController.add(true);
      debugPrint("lavkant");
      debugPrint("$data");

      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);
      int progress = data[2];
      var tasks = downloadsListMaps.where((element) => element['id'] == id);
      for (var element in tasks) {
        element['progress'] = progress;
        element['status'] = status;
      }
      await task();

      loadingController.add(false);
    });
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future task() async {
    loadingController.add(true);
    downloadsListMaps.clear();
    List<DownloadTask>? getTasks = await FlutterDownloader.loadTasks();
    if (getTasks == null) {
      return;
    }
    for (var _task in getTasks) {
      Map map = {};
      map['status'] = _task.status;
      map['progress'] = _task.progress;
      map['id'] = _task.taskId;
      map['filename'] = _task.filename;
      map['savedDirectory'] = _task.savedDir;
      downloadsListMaps.add(map);
    }
    // setState(() {});
    loadingController.add(false);
  }

  void _showAddDownloadPopup(BuildContext context) {
    _urlController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Download'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'Enter URL'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      loadingController.add(true);
                      GetIt.instance<DownloadManagerService2>().addDownload(_urlController.text);
                      await task();
                      loadingController.add(false);
                      // _urlController.clear();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: loadingController,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox(
              child: Text('Something went wrong'),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Offline Downloads'),
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => OfflineMapInit(
                                damagedDatabaseDeleted: widget.damagedDatabaseDeleted,
                              )));
                    },
                    icon: const Icon(Icons.moving_rounded))
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                _showAddDownloadPopup(context);
              },
              child: const Icon(Icons.add),
            ),
            body: downloadsListMaps.isEmpty
                ? const Center(child: Text("No Downloads yet"))
                : Container(
                    child: ListView.builder(
                      itemCount: downloadsListMaps.length,
                      itemBuilder: (BuildContext context, int i) {
                        Map map = downloadsListMaps[i];
                        String filename = map['filename'] ?? "";
                        int progress = map['progress'];
                        DownloadTaskStatus status = map['status'];
                        String id = map['id'];
                        String savedDirectory = map['savedDirectory'];
                        List<FileSystemEntity> directories = Directory(savedDirectory).listSync(followLinks: true);
                        File? file = directories.isNotEmpty ? File(directories.first.path) : null;
                        return GestureDetector(
                          onTap: () {
                            if (status == DownloadTaskStatus.complete) {
                              showDialogue(file!);
                            }
                          },
                          child: Card(
                            elevation: 10,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                ListTile(
                                  isThreeLine: false,
                                  title: Text(filename),
                                  subtitle: downloadStatus(status),
                                  trailing: SizedBox(
                                    width: 60,
                                    child: buttons(status, id, i),
                                  ),
                                ),
                                status == DownloadTaskStatus.complete ? Container() : const SizedBox(height: 5),
                                status == DownloadTaskStatus.complete
                                    ? Container()
                                    : Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Text('$progress%'),
                                            Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: LinearProgressIndicator(
                                                    value: progress / 100,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                const SizedBox(height: 10)
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          );
        });
  }

  Widget downloadStatus(DownloadTaskStatus status) {
    return status == DownloadTaskStatus.canceled
        ? const Text('Download canceled')
        : status == DownloadTaskStatus.complete
            ? const Text('Download completed')
            : status == DownloadTaskStatus.failed
                ? const Text('Download failed')
                : status == DownloadTaskStatus.paused
                    ? const Text('Download paused')
                    : status == DownloadTaskStatus.running
                        ? const Text('Downloading..')
                        : const Text('Download waiting');
  }

  Widget buttons(DownloadTaskStatus status, String taskid, int index) {
    void changeTaskID(String taskid, String newTaskID) {
      loadingController.add(true);
      Map task = downloadsListMaps.firstWhere(
        (element) => element['taskId'] == taskid,
        orElse: () => {},
      );
      task['taskId'] = newTaskID;
      loadingController.add(false);
    }

    return status == DownloadTaskStatus.canceled
        ? Row(
            children: [
              GestureDetector(
                child: const Icon(Icons.cached, size: 20, color: Colors.green),
                onTap: () async {
                  await FlutterDownloader.retry(taskId: taskid).then((newTaskID) {
                    changeTaskID(taskid, newTaskID!);
                  });
                },
              ),
              GestureDetector(
                child: const Icon(Icons.delete, size: 20, color: Colors.red),
                onTap: () {
                  loadingController.add(true);
                  downloadsListMaps.removeAt(index);
                  FlutterDownloader.remove(taskId: taskid, shouldDeleteContent: true);
                  loadingController.add(false);
                },
              )
            ],
          )
        : status == DownloadTaskStatus.failed
            ? Row(
                children: [
                  GestureDetector(
                    child: const Icon(Icons.cached, size: 20, color: Colors.green),
                    onTap: () async {
                      await FlutterDownloader.retry(taskId: taskid).then((newTaskID) {
                        changeTaskID(taskid, newTaskID!);
                      });
                    },
                  ),
                  GestureDetector(
                    child: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onTap: () {
                      loadingController.add(true);

                      downloadsListMaps.removeAt(index);
                      FlutterDownloader.remove(taskId: taskid, shouldDeleteContent: true);
                      // setState(() {});
                      loadingController.add(false);
                    },
                  )
                ],
              )
            : status == DownloadTaskStatus.paused
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      GestureDetector(
                        child: const Icon(Icons.play_arrow, size: 20, color: Colors.blue),
                        onTap: () async {
                          await FlutterDownloader.resume(taskId: taskid).then(
                            (newTaskID) => changeTaskID(taskid, newTaskID ?? ""),
                          );
                        },
                      ),
                      GestureDetector(
                        child: const Icon(Icons.close, size: 20, color: Colors.red),
                        onTap: () {
                          FlutterDownloader.cancel(taskId: taskid);
                        },
                      )
                    ],
                  )
                : status == DownloadTaskStatus.running
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            child: const Icon(Icons.pause, size: 20, color: Colors.green),
                            onTap: () {
                              FlutterDownloader.pause(taskId: taskid);
                            },
                          ),
                          GestureDetector(
                            child: const Icon(Icons.close, size: 20, color: Colors.red),
                            onTap: () {
                              FlutterDownloader.cancel(taskId: taskid);
                            },
                          )
                        ],
                      )
                    : status == DownloadTaskStatus.complete
                        ? GestureDetector(
                            child: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onTap: () {
                              loadingController.add(true);

                              downloadsListMaps.removeAt(index);
                              FlutterDownloader.remove(taskId: taskid, shouldDeleteContent: true);
                              // setState(() {});
                              loadingController.add(false);
                            },
                          )
                        : Container();
  }

  showDialogue(File file) {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        });
  }
}
