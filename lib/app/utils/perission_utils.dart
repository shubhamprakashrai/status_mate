import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // For Android 11+ (API 30+), request manage external storage
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      return false;
    }
    return true; // iOS doesn't require permission
  }
}
