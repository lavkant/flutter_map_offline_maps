import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:rxdart/subjects.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({Key? key}) : super(key: key);

  @override
  _ReceiverScreenState createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);
  List<File> receivedFiles = [];
  NearbyService? nearbyService;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    nearbyService?.stopBrowsingForPeers();
    nearbyService?.stopAdvertisingPeer();
    loadingController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receiver'),
      ),
      body: StreamBuilder(
          stream: loadingController,
          builder: (context, snapshot) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: receivedFiles.length,
                    itemBuilder: (context, index) {
                      final file = receivedFiles[index];
                      return ListTile(
                        title: Text(file.path),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
    );
  }

  void init() async {
    nearbyService = NearbyService();
    await nearbyService?.init(
      serviceType: 'mpconn',
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          await nearbyService?.stopAdvertisingPeer();
          await nearbyService?.stopBrowsingForPeers();
          await Future.delayed(const Duration(microseconds: 200));
          await nearbyService?.startBrowsingForPeers();
        }
      },
    );

    final subscription = nearbyService?.dataReceivedSubscription(callback: (data) {
      onFileReceived(data);
    });
  }

  void onFileReceived(String fileInfoJson) {
    Map<String, dynamic> fileInfo = jsonDecode(fileInfoJson);

    String fileName = fileInfo['fileName'];
    String fileExtension = fileInfo['fileExtension'];
    String mimeType = fileInfo['mimeType'];
    String base64Encoded = fileInfo['fileData'];

    List<int> fileBytes = base64Decode(base64Encoded);
    File receivedFile = File('/path/to/save/$fileName');
    receivedFile.writeAsBytesSync(fileBytes);

    loadingController.add(true);
    receivedFiles.add(receivedFile);
    loadingController.add(false);

    // Notify user that file transfer is complete
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('File Transfer Complete'),
          content: Text('Received file: $fileName'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
