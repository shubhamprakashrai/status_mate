import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:flutter/services.dart';

/// A utility class for handling app permissions
class PermissionUtils {
  /// Request all necessary permissions for the app
  static Future<bool> requestStoragePermissions() async {
    try {
      // For Android 13+ (API 33+)
      if (await perm.Permission.videos.isRestricted ||
          await perm.Permission.photos.isRestricted) {
        return false;
      }

      if (await perm.Permission.videos.isPermanentlyDenied ||
          await perm.Permission.photos.isPermanentlyDenied) {
        return false;
      }

      if (!await perm.Permission.videos.isGranted ||
          !await perm.Permission.photos.isGranted) {
        final statuses = await [
          perm.Permission.photos,
          perm.Permission.videos,
        ].request();

        if (statuses[perm.Permission.photos] != perm.PermissionStatus.granted ||
            statuses[perm.Permission.videos] != perm.PermissionStatus.granted) {
          return false;
        }
      }

      // For Android 11-12 (API 30-32)
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
    if (await perm.Permission.videos.isGranted &&
        await perm.Permission.photos.isGranted) {
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

    return true;
  }
}
