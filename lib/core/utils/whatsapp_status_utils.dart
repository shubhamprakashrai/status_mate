import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============ TOP-LEVEL FUNCTIONS FOR ISOLATE ============

/// Scans directory and returns file paths - runs in isolate
List<String> _scanDirectoryIsolate(String dirPath) {
  try {
    final directory = Directory(dirPath);
    if (!directory.existsSync()) return [];

    final List<String> filePaths = [];
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    final videoExtensions = ['.mp4', '.3gp', '.mkv', '.webm', '.avi', '.mov', '.m4v', '.flv'];

    final entities = directory.listSync(recursive: false);
    for (final entity in entities) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (imageExtensions.contains(ext) || videoExtensions.contains(ext)) {
          filePaths.add(entity.path);
        }
      }
    }

    // Sort by last modified (newest first) - done in isolate
    filePaths.sort((a, b) {
      try {
        final aTime = File(a).lastModifiedSync();
        final bTime = File(b).lastModifiedSync();
        return bTime.compareTo(aTime);
      } catch (e) {
        return 0;
      }
    });

    return filePaths;
  } catch (e) {
    return [];
  }
}

/// Scans multiple directories - runs in isolate
List<String> _scanMultipleDirectoriesIsolate(List<String> dirPaths) {
  final List<String> allFilePaths = [];

  for (final dirPath in dirPaths) {
    allFilePaths.addAll(_scanDirectoryIsolate(dirPath));
  }

  // Sort all files by last modified
  allFilePaths.sort((a, b) {
    try {
      final aTime = File(a).lastModifiedSync();
      final bTime = File(b).lastModifiedSync();
      return bTime.compareTo(aTime);
    } catch (e) {
      return 0;
    }
  });

  return allFilePaths;
}

/// Recursively scan directory for media files - runs in isolate
List<String> _scanRecursiveIsolate(String dirPath) {
  try {
    final directory = Directory(dirPath);
    if (!directory.existsSync()) return [];

    final List<String> filePaths = [];
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    final videoExtensions = ['.mp4', '.3gp', '.mkv', '.webm', '.avi', '.mov', '.m4v', '.flv'];

    final entities = directory.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (imageExtensions.contains(ext) || videoExtensions.contains(ext)) {
          filePaths.add(entity.path);
        }
      }
    }

    filePaths.sort((a, b) {
      try {
        final aTime = File(a).lastModifiedSync();
        final bTime = File(b).lastModifiedSync();
        return bTime.compareTo(aTime);
      } catch (e) {
        return 0;
      }
    });

    return filePaths;
  } catch (e) {
    return [];
  }
}

// ============ MAIN CLASS ============

class WhatsAppStatusUtils {
  static const String _prefsKeyLastSelectedDir = 'last_selected_status_dir';
  static String? _lastSelectedDirectory;

  /// Get the appropriate WhatsApp status directory based on Android version
  static List<String> _getWhatsAppStatusDirPaths() {
    return [
      '/storage/emulated/0/WhatsApp/Media/.Statuses',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    ];
  }

  /// Check which directories exist
  static Future<List<String>> _getExistingWhatsAppDirs() async {
    final dirs = _getWhatsAppStatusDirPaths();
    final existing = <String>[];
    for (final dir in dirs) {
      if (await Directory(dir).exists()) {
        existing.add(dir);
      }
    }
    return existing;
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

    if (await perm.Permission.videos.isRestricted ||
        await perm.Permission.photos.isRestricted) {
      return false;
    }

    if (await perm.Permission.manageExternalStorage.isDenied) {
      final status = await perm.Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    }

    if (await perm.Permission.storage.isDenied) {
      final status = await perm.Permission.storage.request();
      if (status.isGranted) return true;
    }

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

  /// Get status files using direct file access - OPTIMIZED WITH ISOLATE
  static Future<List<File>> getStatusFilesDirect() async {
    final statusDirs = await _getExistingWhatsAppDirs();
    if (statusDirs.isEmpty) return [];

    // Run heavy file scanning in isolate
    final filePaths = await compute(_scanMultipleDirectoriesIsolate, statusDirs);

    // Convert paths to File objects (lightweight operation)
    return filePaths.map((p) => File(p)).toList();
  }

  static Future<void> _saveSelectedDirectory(String? dirPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (dirPath != null) {
      await prefs.setString(_prefsKeyLastSelectedDir, dirPath);
    } else {
      await prefs.remove(_prefsKeyLastSelectedDir);
    }
  }

  static Future<String?> _getSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyLastSelectedDir);
  }

  /// Get status files using Storage Access Framework (SAF) - OPTIMIZED
  static Future<List<File>> getStatusFilesViaSAF() async {
    try {
      _lastSelectedDirectory = await _getSavedDirectory();

      // Try saved directory first
      if (_lastSelectedDirectory != null &&
          await Directory(_lastSelectedDirectory!).exists()) {
        final filePaths = await compute(_scanDirectoryIsolate, _lastSelectedDirectory!);
        if (filePaths.isNotEmpty) {
          return filePaths.map((p) => File(p)).toList();
        }
      }

      // Show directory picker
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return [];

      _lastSelectedDirectory = selectedDirectory;
      await _saveSelectedDirectory(selectedDirectory);

      // Try direct scan
      var filePaths = await compute(_scanDirectoryIsolate, selectedDirectory);
      if (filePaths.isNotEmpty) {
        return filePaths.map((p) => File(p)).toList();
      }

      // Try common subdirectories
      final possibleSubdirs = [
        'Media/.Statuses',
        'WhatsApp/Media/.Statuses',
        'Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      ];

      for (final subdir in possibleSubdirs) {
        final statusDirPath = '$selectedDirectory/$subdir';
        if (await Directory(statusDirPath).exists()) {
          _lastSelectedDirectory = statusDirPath;
          await _saveSelectedDirectory(statusDirPath);
          filePaths = await compute(_scanDirectoryIsolate, statusDirPath);
          if (filePaths.isNotEmpty) {
            return filePaths.map((p) => File(p)).toList();
          }
        }
      }

      // Recursive scan as last resort
      filePaths = await compute(_scanRecursiveIsolate, selectedDirectory);
      return filePaths.map((p) => File(p)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get status files using the best available method - OPTIMIZED
  static Future<List<File>> getStatusFiles({bool forceSAF = false}) async {
    // Check saved directory first
    final savedDir = await _getSavedDirectory();
    if (savedDir != null && await Directory(savedDir).exists()) {
      final filePaths = await compute(_scanDirectoryIsolate, savedDir);
      if (filePaths.isNotEmpty) {
        return filePaths.map((p) => File(p)).toList();
      }
    }

    // Try direct access
    if (!forceSAF && await hasStoragePermission()) {
      final files = await getStatusFilesDirect();
      if (files.isNotEmpty) return files;
    }

    // Fall back to SAF
    return getStatusFilesViaSAF();
  }
}
