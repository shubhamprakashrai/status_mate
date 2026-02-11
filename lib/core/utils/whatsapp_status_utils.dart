import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    return false;
  }

  /// Request storage permissions
  static Future<bool> requestStoragePermission() async {
    if (await hasStoragePermission()) {
      return true;
    }

    // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
    if (await perm.Permission.manageExternalStorage.isDenied) {
      final status = await perm.Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    }

    // For Android 10 and below
    if (await perm.Permission.storage.isDenied) {
      final status = await perm.Permission.storage.request();
      if (status.isGranted) return true;
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

  static const String _prefsKeyLastSelectedDir = 'last_selected_status_dir';
  static String? _lastSelectedDirectory;

  static Future<void> _saveSelectedDirectory(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_prefsKeyLastSelectedDir, path);
    } else {
      await prefs.remove(_prefsKeyLastSelectedDir);
    }
  }

  static Future<String?> _getSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyLastSelectedDir);
  }

  /// Get status files using Storage Access Framework (SAF)
  static Future<List<File>> getStatusFilesViaSAF() async {
    try {
      // Check for saved directory first
      _lastSelectedDirectory = await _getSavedDirectory();
      
      // If we have a valid saved directory, try to use it
      if (_lastSelectedDirectory != null && await Directory(_lastSelectedDirectory!).exists()) {
        try {
          final files = await _getFilesFromDirectory(Directory(_lastSelectedDirectory!));
          if (files.isNotEmpty) {
            return files;
          }
        } catch (e) {
          print('Error reading saved directory: $e');
        }
      }
      
      // If no saved directory or it's invalid, show directory picker
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory == null) {
        // If user cancels, return empty list
        return [];
      }

      // Save the selected directory for future use
      _lastSelectedDirectory = selectedDirectory;
      await _saveSelectedDirectory(selectedDirectory);

      // First try to read directly from the selected directory
      try {
        final files = await _getFilesFromDirectory(Directory(selectedDirectory));
        if (files.isNotEmpty) {
          return files;
        }
      } catch (e) {
        print('Error reading selected directory: $e');
      }

      // If no files found, try common WhatsApp status subdirectories
      final statusDirs = await _getWhatsAppStatusDirs();
      
      // Check if the selected directory is a parent of a WhatsApp status directory
      for (final dir in statusDirs) {
        if (selectedDirectory.contains('WhatsApp') && dir.contains(selectedDirectory)) {
          final statusDir = Directory(dir);
          if (await statusDir.exists()) {
            _lastSelectedDirectory = dir;
            await _saveSelectedDirectory(dir);
            return _getFilesFromDirectory(statusDir);
          }
        }
      }
      
      // If still no files, try common status subdirectories
      final possibleSubdirs = [
        'Media/.Statuses',
        'WhatsApp/Media/.Statuses',
        'Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
        'com.whatsapp/WhatsApp/Media/.Statuses'
      ];
      
      for (final subdir in possibleSubdirs) {
        final statusDir = Directory('$selectedDirectory/$subdir');
        if (await statusDir.exists()) {
          _lastSelectedDirectory = statusDir.path;
          await _saveSelectedDirectory(statusDir.path);
          return _getFilesFromDirectory(statusDir);
        }
      }
      
      // As a last resort, try to find any media files in the selected directory recursively
      try {
        final dir = Directory(selectedDirectory);
        final files = <File>[];
        await for (var entity in dir.list(recursive: true)) {
          if (entity is File) {
            final ext = path.extension(entity.path).toLowerCase();
            if (_imageExtensions.contains(ext) || _videoExtensions.contains(ext)) {
              files.add(entity);
            }
          }
        }
        if (files.isNotEmpty) {
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          return files;
        }
      } catch (e) {
        print('Error searching for media files: $e');
      }
      
      // If all else fails, return an empty list
      return [];
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
    // First check if we have a saved directory
    final savedDir = await _getSavedDirectory();
    if (savedDir != null && await Directory(savedDir).exists()) {
      try {
        final files = await _getFilesFromDirectory(Directory(savedDir));
        if (files.isNotEmpty) {
          return files;
        }
      } catch (e) {
        print('Error reading saved directory: $e');
      }
    }

    // If no saved directory or it failed, try direct access
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
    
    // Fall back to SAF if other methods fail or are forced
    return getStatusFilesViaSAF();
  }
}
