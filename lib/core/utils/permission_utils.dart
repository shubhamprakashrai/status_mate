import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:flutter/services.dart';

/// A utility class for handling app permissions
class PermissionUtils {
  /// Request all necessary permissions for the app
  static Future<bool> requestStoragePermissions() async {
    try {
      // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
      if (await perm.Permission.manageExternalStorage.isDenied) {
        final status = await perm.Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
      }

      if (await perm.Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // For Android 10 and below, request storage permission
      if (!await perm.Permission.storage.isGranted) {
        final status = await perm.Permission.storage.request();
        if (status != perm.PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } on PlatformException catch (e) {
      debugPrint('Permission exception: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> hasRequiredPermissions() async {
    if (await perm.Permission.manageExternalStorage.isGranted) {
      return true;
    }

    if (await perm.Permission.storage.isGranted) {
      return true;
    }

    return false;
  }

  /// Show permission dialog with option to open settings
  static Future<bool> showPermissionDialog(BuildContext context,
      {String? message}) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text(
              message ??
                  'Storage permission is required to access WhatsApp statuses.\n\nPlease grant the permission in app settings.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  PermissionUtils.openAppSettingsPage();
                },
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Open app settings so user can enable permissions
  static Future<bool> openAppSettingsPage() async {
    final result = await perm.openAppSettings();
    return result;
  }

  /// Check if we should show a request rationale for permissions
  static Future<bool> shouldShowRequestRationale() async {
    if (await perm.Permission.manageExternalStorage.isPermanentlyDenied) {
      return false;
    }

    if (await perm.Permission.storage.isPermanentlyDenied) {
      return false;
    }

    debugPrint("[PermissionUtils] Rationale can be shown");
    return true;
  }
}
