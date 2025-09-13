import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class WhatsAppStatusUtils {
  static const List<String> _imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
  static const List<String> _videoExtensions = ['.mp4', '.3gp', '.mkv', '.webm'];

  /// Get the appropriate WhatsApp status directory based on Android version
  static Future<List<String>> _getWhatsAppStatusDirs() async {
    final List<String> statusDirs = [];
    
    // For Android 10 and below
    statusDirs.add('/storage/emulated/0/WhatsApp/Media/.Statuses');
    
    // For Android 11 and above
    statusDirs.add('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses');
    
    // Check which directories exist
    final List<String> existingDirs = [];
    for (final dir in statusDirs) {
      if (await Directory(dir).exists()) {
        existingDirs.add(dir);
      }
    }
    
    return existingDirs;
  }

  /// Check if we have storage permissions
  static Future<bool> hasStoragePermission() async {
    if (await perm.Permission.manageExternalStorage.isGranted) {
      return true;
    }

    if (await perm.Permission.storage.isGranted) {
      return true;
    }

    if (await perm.Permission.photos.isGranted && 
        await perm.Permission.videos.isGranted) {
      return true;
    }

    return false;
  }

  /// Request storage permissions
  static Future<bool> requestStoragePermission() async {
    if (await hasStoragePermission()) {
      return true;
    }

    // For Android 13+ (API 33+)
    if (await perm.Permission.videos.isRestricted ||
        await perm.Permission.photos.isRestricted) {
      return false;
    }

    // Request appropriate permissions based on Android version
    if (await perm.Permission.manageExternalStorage.isDenied) {
      final status = await perm.Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    }

    // For Android 11-12 (API 30-32)
    if (await perm.Permission.storage.isDenied) {
      final status = await perm.Permission.storage.request();
      if (status.isGranted) return true;
    }

    // For Android 13+ (API 33+)
    if (await perm.Permission.photos.isDenied || 
        await perm.Permission.videos.isDenied) {
      final statuses = await [
        perm.Permission.photos,
        perm.Permission.videos,
      ].request();
      
      if (statuses[perm.Permission.photos]!.isGranted &&
          statuses[perm.Permission.videos]!.isGranted) {
        return true;
      }
    }

    return false;
  }

  /// Get status files using direct file access (requires MANAGE_EXTERNAL_STORAGE)
  static Future<List<File>> getStatusFilesDirect() async {
    final List<File> statusFiles = [];
    final statusDirs = await _getWhatsAppStatusDirs();

    for (final dir in statusDirs) {
      try {
        final directory = Directory(dir);
        if (await directory.exists()) {
          final List<FileSystemEntity> entities = directory.listSync(recursive: false);
          
          for (final entity in entities) {
            if (entity is File) {
              final ext = path.extension(entity.path).toLowerCase();
              if (_imageExtensions.contains(ext) || _videoExtensions.contains(ext)) {
                statusFiles.add(entity);
              }
            }
          }
        }
      } catch (e) {
        print('Error accessing directory $dir: $e');
      }
    }

    // Sort by last modified (newest first)
    statusFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return statusFiles;
  }

  static String? _lastSelectedDirectory;

  /// Get status files using Storage Access Framework (SAF)
  static Future<List<File>> getStatusFilesViaSAF() async {
    try {
      // Open directory picker to get access to WhatsApp status directory
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory == null) {
        // If user cancels, return empty list
        return [];
      }

      // Save the selected directory for future use
      _lastSelectedDirectory = selectedDirectory;

      // Check if the selected directory is a WhatsApp status directory
      final statusDirs = await _getWhatsAppStatusDirs();
      
      // If we have a previously selected directory, use that first
      if (_lastSelectedDirectory != null && await Directory(_lastSelectedDirectory!).exists()) {
        return _getFilesFromDirectory(Directory(_lastSelectedDirectory!));
      }
      
      if (!statusDirs.any((dir) => selectedDirectory.contains(dir))) {
        // If not, try to find the status directory in the selected path
        for (final dir in statusDirs) {
          if (selectedDirectory.contains('WhatsApp')) {
            final statusDir = Directory('$selectedDirectory/Media/.Statuses');
            if (await statusDir.exists()) {
              _lastSelectedDirectory = statusDir.path;
              return _getFilesFromDirectory(statusDir);
            }
          }
        }
        return [];
      }

      return _getFilesFromDirectory(Directory(selectedDirectory));
    } catch (e) {
      print('Error in getStatusFilesViaSAF: $e');
      return [];
    }
  }

  static Future<List<File>> _getFilesFromDirectory(Directory directory) async {
    final List<File> statusFiles = [];
    
    try {
      final entities = directory.listSync(recursive: false);
      
      for (final entity in entities) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (_imageExtensions.contains(ext) || _videoExtensions.contains(ext)) {
            statusFiles.add(entity);
          }
        }
      }
      
      // Sort by last modified (newest first)
      statusFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      print('Error reading directory ${directory.path}: $e');
    }
    
    return statusFiles;
  }

  /// Get status files using the best available method
  static Future<List<File>> getStatusFiles({bool forceSAF = false}) async {
    if (!forceSAF && await hasStoragePermission()) {
      try {
        final files = await getStatusFilesDirect();
        if (files.isNotEmpty) {
          return files;
        }
      } catch (e) {
        print('Error in direct file access, falling back to SAF: $e');
      }
    }
    
    // Fall back to SAF if direct access fails or is forced
    return getStatusFilesViaSAF();
  }
}
