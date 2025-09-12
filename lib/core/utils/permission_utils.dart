import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

/// A utility class for handling app permissions
class PermissionUtils {
  /// Request all necessary permissions for the app
  static Future<bool> requestStoragePermissions() async {
    try {
      if (!await Permission.storage.isGranted) {
        final status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          return false;
        }
      }

      // For Android 10 (API 29) and below, we need to request manage external storage
      if (await Permission.manageExternalStorage.isRestricted) {
        return true; // Can't request this permission, return true if storage is granted
      }

      // For Android 11 (API 30) and above, we need to request manage external storage
      if (!await Permission.manageExternalStorage.isGranted) {
        final status = await Permission.manageExternalStorage.request();
        if (status != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } on PlatformException catch (e) {
      print('Permission exception: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> hasRequiredPermissions() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    
    if (await Permission.storage.isGranted) {
      return true;
    }
    
    return false;
  }

  /// Open app settings so user can enable permissions
  static Future<bool> openAppSettings() async {
    final result = await openAppSettings();
    return result;
  }

  /// Check if we should show a request rationale for permissions
  static Future<bool> shouldShowRequestRationale() async {
    if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      return false;
    }

    if (await Permission.storage.isPermanentlyDenied) {
      return false;
    }

    return true;
  }
}
