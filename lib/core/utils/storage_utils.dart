import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class StorageUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Gets the appropriate WhatsApp status directory path based on Android version
  static Future<String?> getWhatsAppStatusDirectory() async {
    if (!Platform.isAndroid) return null;
    
    final androidInfo = await _deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    // For Android 11 (API 30) and above
    if (sdkInt >= 30) {
      return '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
    } 
    // For Android 10 and below
    else {
      return '/storage/emulated/0/WhatsApp/Media/.Statuses';
    }
  }

  /// Requests the necessary permissions based on Android version
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // Android 13+ (API 33+)
      if (sdkInt >= 33) {
        final statuses = await Future.wait([
          Permission.photos.request(),
          Permission.videos.request(),
        ]);
        return statuses.every((status) => status.isGranted);
      } 
      // Android 10-12 (API 29-32)
      else if (sdkInt >= 29) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      // Android 9 and below
      else {
        // For Android 9 and below, we need to request storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Checks if we have the necessary permissions
  static Future<bool> hasRequiredPermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // Android 13+ (API 33+)
      if (sdkInt >= 33) {
        return await Permission.photos.isGranted && 
               await Permission.videos.isGranted;
      } 
      // Android 10-12 (API 29-32)
      else if (sdkInt >= 29) {
        return await Permission.storage.isGranted;
      }
      // Android 9 and below
      else {
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Lists all status files (images and videos) from the WhatsApp status directory
  static Future<List<FileSystemEntity>> listStatusFiles() async {
    try {
      final hasPermissions = await hasRequiredPermissions();
      if (!hasPermissions) {
        throw Exception('Storage permissions not granted');
      }

      final statusDir = await getWhatsAppStatusDirectory();
      if (statusDir == null) {
        throw Exception('Could not determine WhatsApp status directory');
      }

      final directory = Directory(statusDir);
      if (!await directory.exists()) {
        throw Exception('WhatsApp status directory does not exist');
      }

      // List all files and filter for images and videos
      final entities = await directory.list().toList();
      return entities.where((entity) {
        if (entity is! File) return false;
        
        final ext = path.extension(entity.path).toLowerCase();
        return isImageFile(ext) || isVideoFile(ext);
      }).toList();
    } catch (e) {
      debugPrint('Error listing status files: $e');
      rethrow;
    }
  }

  /// Checks if the file extension corresponds to an image
  static bool isImageFile(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension.toLowerCase());
  }

  /// Checks if the file extension corresponds to a video
  static bool isVideoFile(String extension) {
    return ['.mp4', '.3gp', '.mkv', '.webm'].contains(extension.toLowerCase());
  }
  
  /// Path for saving downloaded statuses
  static String get savedDirPath => '/storage/emulated/0/Download/StatusMate';
}
