import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getLocalVideoFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  static Future<bool> checkVideoExists(String filename) async {
    try {
      final file = await getLocalVideoFile(filename);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  static Future<void> copyVideoToLocal(
      String sourceVideoPath, String targetFilename) async {
    try {
      final sourceFile = File(sourceVideoPath);
      if (!await sourceFile.exists()) {
        throw Exception('Source video file does not exist: $sourceVideoPath');
      }

      final targetFile = await getLocalVideoFile(targetFilename);
      if (!await targetFile.exists()) {
        await sourceFile.copy(targetFile.path);
      }
    } catch (e) {
      throw Exception('Failed to copy video to local storage: $e');
    }
  }

  static Future<void> deleteLocalVideo(String filename) async {
    try {
      final file = await getLocalVideoFile(filename);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete local video: $e');
    }
  }
}
