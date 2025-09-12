import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// A utility class for handling app permissions
class PermissionUtils {
  // Check if the device is running Android 13 (API 33) or higher
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) {
      debugPrint("[PermissionUtils] Not Android device");
      return false;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      debugPrint("[PermissionUtils] Android SDK version: ${androidInfo.version.sdkInt}");
      return androidInfo.version.sdkInt >= 33; // Android 13 is API 33
    } catch (e) {
      debugPrint('[PermissionUtils] Error getting Android version: $e');
      return false;
    }
  }

  /// Request all necessary permissions for the app
  static Future<bool> requestStoragePermissions() async {
    try {
      debugPrint("[PermissionUtils] requestStoragePermissions called");

      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          debugPrint("[PermissionUtils] Android 13+ detected, requesting photo & video permissions");

          final photoStatus = await Permission.photos.request();
          debugPrint("[PermissionUtils] Photo permission: $photoStatus");

          final videoStatus = await Permission.videos.request();
          debugPrint("[PermissionUtils] Video permission: $videoStatus");

          if (photoStatus.isDenied || videoStatus.isDenied) {
            debugPrint("[PermissionUtils] One or more media permissions denied");
            return false;
          }

          if (await Permission.storage.isDenied) {
            debugPrint("[PermissionUtils] Storage permission denied, requesting now...");
            final storageStatus = await Permission.storage.request();
            debugPrint("[PermissionUtils] Storage permission result: $storageStatus");
            if (storageStatus.isDenied) {
              debugPrint("[PermissionUtils] Storage permission denied again");
              return false;
            }
          }

          return true;
        } else {
          // Android 11-12 (API 30-32)
          if (await Permission.manageExternalStorage.isRestricted == false) {
            debugPrint("[PermissionUtils] Requesting manageExternalStorage permission");
            final status = await Permission.manageExternalStorage.request();
            debugPrint("[PermissionUtils] manageExternalStorage result: $status");
            return status.isGranted;
          } else {
            // Android 10 and below
            debugPrint("[PermissionUtils] Requesting storage permission");
            final status = await Permission.storage.request();
            debugPrint("[PermissionUtils] Storage permission result: $status");
            return status.isGranted;
          }
        }
      }

      if (Platform.isIOS) {
        debugPrint("[PermissionUtils] iOS detected, requesting photos permission");
        final status = await Permission.photos.request();
        debugPrint("[PermissionUtils] Photos permission result: $status");
        return status.isGranted;
      }

      debugPrint("[PermissionUtils] Non-Android/iOS platform, assuming permissions granted");
      return true;
    } on PlatformException catch (e) {
      debugPrint('[PermissionUtils] Permission exception: $e');
      return false;
    } catch (e) {
      debugPrint('[PermissionUtils] Unexpected error: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> hasRequiredPermissions() async {
    debugPrint("[PermissionUtils] Checking if required permissions are granted");

    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final photosGranted = await Permission.photos.isGranted;
        final videosGranted = await Permission.videos.isGranted;
        debugPrint("[PermissionUtils] Photos granted: $photosGranted, Videos granted: $videosGranted");
        return photosGranted && videosGranted;
      } else {
        final storageGranted = await Permission.storage.isGranted;
        final manageGranted = await Permission.manageExternalStorage.isGranted;
        debugPrint("[PermissionUtils] Storage granted: $storageGranted, ManageExt granted: $manageGranted");
        return storageGranted || manageGranted;
      }
    }

    if (Platform.isIOS) {
      final granted = await Permission.photos.isGranted;
      debugPrint("[PermissionUtils] iOS Photos granted: $granted");
      return granted;
    }

    debugPrint("[PermissionUtils] Other platform, returning true");
    return true;
  }

  /// Open app settings so user can enable permissions
  static Future<bool> openAppSettings() async {
    debugPrint("[PermissionUtils] Opening app settings...");
    try {
      const platform = MethodChannel('flutter.baseflow.com/permissions/methods');
      await platform.invokeMethod('openAppSettings');
      debugPrint("[PermissionUtils] App settings opened successfully");
      return true;
    } on PlatformException catch (e) {
      debugPrint('[PermissionUtils] Error opening app settings: $e');
      return false;
    } catch (e) {
      debugPrint('[PermissionUtils] Unexpected error opening app settings: $e');
      return false;
    }
  }

  /// Check if we should show a request rationale for permissions
  static Future<bool> shouldShowRequestRationale() async {
    debugPrint("[PermissionUtils] Checking if rationale should be shown");

    if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      debugPrint("[PermissionUtils] ManageExternalStorage permanently denied");
      return false;
    }

    if (await Permission.storage.isPermanentlyDenied) {
      debugPrint("[PermissionUtils] Storage permanently denied");
      return false;
    }

    debugPrint("[PermissionUtils] Rationale can be shown");
    return true;
  }
}
