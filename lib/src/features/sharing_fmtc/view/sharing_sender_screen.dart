import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:mime/mime.dart';
import 'package:rxdart/subjects.dart';

class SenderScreen extends StatefulWidget {
  const SenderScreen({Key? key}) : super(key: key);

  @override
  _SenderScreenState createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  List<Device> devices = [];
  List<File> selectedFiles = [];
  NearbyService? nearbyService;
  Device? selectedDevice;
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    nearbyService?.stopAdvertisingPeer();
    loadingController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sender'),
      ),
      body: StreamBuilder(
          stream: loadingController,
          builder: (context, snapshot) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                          selected: selectedDevice == device,
                          title: Text(device.deviceName),
                          // onTap: () {
                          //   _deviceSelectAndPickFiles(device);
                          // },
                          trailing: ElevatedButton(
                            onPressed: () {
                              _deviceSelectAndPickFiles(device);
                            },
                            child: const Text('Select Files'),
                          ),
                          leading: ElevatedButton(
                            onPressed: () {
                              connectDevice(device);
                            },
                            child: selectedDevice == device ? const Text('Connected') : const Text('Connect'),
                          ));
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = selectedFiles[index];
                      return ListTile(
                          title: Text(file.path),
                          trailing: ElevatedButton(
                            onPressed: () {
                              selectedFiles.removeAt(index);
                              setState(() {});
                            },
                            child: const Text('Remove'),
                          ));
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDevice != null && selectedFiles.isNotEmpty) {
                      _connectAndSendFiles(selectedDevice!, selectedFiles);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a device and files to send.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Connect and Send Files'),
                ),
              ],
            );
          }),
    );
  }

  void init() async {
    nearbyService = NearbyService();
    final subscription = nearbyService?.stateChangedSubscription(callback: (devicesList) {
      loadingController.add(true);
      devices.clear();
      devices.addAll(devicesList);
      loadingController.add(false);
    });
  }

  void _deviceSelectAndPickFiles(Device device) async {
    loadingController.add(true);

    try {
      FilePickerResult? pickedFiles = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (pickedFiles?.files != null && pickedFiles!.files.isNotEmpty) {
        selectedFiles.addAll(pickedFiles.files.map((e) => File(e.path!)).toList() ?? []);
        // Update the UI or perform any other actions with the selected files
      } else {
        // User canceled file picking
      }
    } catch (e) {
      print("Error picking files: $e");
      // Handle the error as needed
    }

    loadingController.add(false);
  }

  void connectDevice(device) async {
    loadingController.add(true);
    selectedDevice = device;
    selectedFiles.clear();
    await nearbyService?.invitePeer(
      deviceID: selectedDevice!.deviceId,
      deviceName: selectedDevice!.deviceName,
    );
    loadingController.add(false);
  }

  void _connectAndSendFiles(Device device, List<File> files) async {
    // await nearbyService?.invitePeer(
    //   deviceID: device.deviceId,
    //   deviceName: device.deviceName,
    // );

    loadingController.add(true);
    selectedDevice = device;
    selectedFiles.clear();
    loadingController.add(false);
    // SELECT FILES
    // Wait for the connection to be established
    await Future.delayed(const Duration(seconds: 2));

    // Now, you can send files to the connected device
    for (var file in files) {
      sendFileToDevice(device, file);
    }
  }

  void sendFileToDevice(Device device, File file) async {
    List<int> fileBytes = await file.readAsBytes();

    // Convert the bytes to a format suitable for sending (e.g., base64)
    String base64Encoded = base64Encode(fileBytes);

    // Include file information (name, extension, mime type)
    String fileName = file.path.split('/').last;
    String fileExtension = fileName.split('.').last;
    String mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    Map<String, dynamic> fileInfo = {
      'fileName': fileName,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'fileData': base64Encoded,
    };

    // Convert the fileInfo map to a JSON string
    String fileInfoJson = jsonEncode(fileInfo);

    nearbyService?.sendMessage(device.deviceId, fileInfoJson);
  }
}
