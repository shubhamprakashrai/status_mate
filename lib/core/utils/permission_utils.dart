import 'package:permission_handler/permission_handler.dart';

/// A utility class for handling app permissions
class PermissionUtils {
  /// Request all necessary permissions for the app
  static Future<PermissionStatus> requestStoragePermissions() async {
    if (await Permission.manageExternalStorage.isRestricted) {
      // On some devices, we can't request manage external storage
      // Fall back to storage permission
      return await Permission.storage.request();
    }

    // Request both storage and manage external storage permissions
    final status = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    // Return the most restrictive status
    if (status[Permission.manageExternalStorage] == PermissionStatus.granted &&
        status[Permission.storage] == PermissionStatus.granted) {
      return PermissionStatus.granted;
    }

    return PermissionStatus.denied;
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
