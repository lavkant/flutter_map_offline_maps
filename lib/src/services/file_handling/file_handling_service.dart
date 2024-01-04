import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FileHandlingService {
  // Check if a file exists in a directory
  Future<bool> doesFileExist(String directoryPath, String fileName) async {
    Directory directory = Directory(directoryPath);
    File file = File('${directory.path}/$fileName');
    return await file.exists();
  }

  // Get a list of all files in a directory
  Future<List<File>> getAllFilesInDirectory({String? directoryPath}) async {
    if (directoryPath == null || directoryPath.isEmpty) {
      return [];
    }
    Directory directory = Directory(directoryPath);
    List<File> files = [];

    try {
      List<FileSystemEntity> entities = directory.listSync();

      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (e) {
      debugPrint('Error while listing files: $e');
    }

    return files;
  }

  // Return a file from a specified path
  File getFileFromPath(String filePath) {
    return File(filePath);
  }

  Future<String> getExternalStoragePath({String? additionalPath}) async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      debugPrint("ERROR Directory is null");
      return '';
    }

    if (additionalPath != null && additionalPath.isNotEmpty) {
      return "${directory.path}/$additionalPath";
    }
    return directory.path;
  }

  // Other functions can be added as needed (e.g., create, delete, read, etc.)
}
