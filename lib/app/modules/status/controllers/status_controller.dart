import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:flutter/services.dart' show PlatformException;
import 'package:status_mate/core/logger/app_logger.dart';
import 'package:status_mate/core/storage/local_storage_service.dart';
import 'package:status_mate/core/utils/permission_utils.dart';
import 'package:status_mate/core/utils/whatsapp_status_utils.dart';
import 'package:status_mate/core/constants/app_strings.dart';

// Custom exception for permission errors
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException([this.message = '']);
  @override
  String toString() => message.isNotEmpty ? 'PermissionDeniedException: $message' : 'PermissionDeniedException';
}

// Custom exception for file operations
class FileExistsException implements Exception {
  final String message;
  const FileExistsException([this.message = '']);
  @override
  String toString() => message.isNotEmpty ? 'FileExistsException: $message' : 'FileExistsException';
}

/// Status types for filtering
enum StatusType { image, video, all }

class StatusController extends GetxController {
  final RxList<File> statusList = <File>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<StatusType> currentFilter = StatusType.all.obs;
  final _logger = AppLogger('StatusController');
  final LocalStorageService _storage = Get.find<LocalStorageService>();

  Timer? _refreshTimer;

  String? _statusDirPath;
  // List of possible WhatsApp status directories
  static const List<String> _possibleStatusPaths = [
    '/sdcard/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
  ];

  // Saved status directory path
  static String get _savedDirPath => '/storage/emulated/0/Download/StatusMate';

  // Permission error message
  final RxString permissionError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStatuses();
    // Set up auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isLoading.value) {
        _loadStatuses();
      }
    });
  }

  // Check and request storage permissions
  Future<bool> checkAndRequestPermissions() async {
    return await WhatsAppStatusUtils.requestStoragePermission();
  }

  // Load status files
  Future<void> loadStatuses({bool forceRefresh = false}) async {
    try {
      if (isLoading.value && !forceRefresh) return;

      isLoading.value = true;
      errorMessage.value = '';

      // Clear existing statuses if this is a refresh
      if (forceRefresh) {
        statusList.clear();
      }

      // Get status files using the best available method
      final files = await WhatsAppStatusUtils.getStatusFiles(forceSAF: forceRefresh);

      if (files.isNotEmpty) {
        statusList.clear(); // Clear existing statuses before adding new ones
        statusList.addAll(files);
        // Filter based on current selection
        _filterStatuses();
      } else if (statusList.isEmpty) {
        // Only show error if we don't have any statuses at all
        errorMessage.value = 'No statuses found. Make sure you have WhatsApp statuses saved or try selecting the status folder manually.';
      }
    } catch (e) {
      _logger.e('Error loading statuses: $e');
      errorMessage.value = 'Failed to load statuses: ${e.toString()}';

      // If direct access failed, try using SAF
      if (e is FileSystemException) {
        _logger.i('Trying to load statuses using Storage Access Framework');
        final files = await WhatsAppStatusUtils.getStatusFiles(forceSAF: true);
        if (files.isNotEmpty) {
          statusList.clear();
          statusList.addAll(files);
          _filterStatuses();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Find the correct status directory
  Future<void> _findStatusDirectory() async {
    for (final path in _possibleStatusPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        _statusDirPath = path;
        _logger.i('Found status directory at: $path');
        return;
      }
    }
    _logger.e('Could not find WhatsApp status directory');
    errorMessage.value = 'Could not find WhatsApp status directory. Please ensure WhatsApp is installed.';
  }

  // Check and request necessary permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+)
        if (await perm.Permission.videos.isRestricted ||
            await perm.Permission.photos.isRestricted) {
          permissionError.value = AppStrings.storagePermissionRequired;
          return false;
        }

        // For Android 13+ (API 33+)
        if (await perm.Permission.videos.isPermanentlyDenied ||
            await perm.Permission.photos.isPermanentlyDenied) {
          permissionError.value = AppStrings.storagePermissionRequired;
          return false;
        }

        // For Android 13+ (API 33+)
        if (!await perm.Permission.videos.isGranted || !await perm.Permission.photos.isGranted) {
          final statuses = await [
            perm.Permission.photos,
            perm.Permission.videos,
          ].request();

          if (statuses[perm.Permission.photos] != perm.PermissionStatus.granted ||
              statuses[perm.Permission.videos] != perm.PermissionStatus.granted) {
            permissionError.value = AppStrings.storagePermissionRequired;
            return false;
          }
        }

        // For Android 11-12 (API 30-32)
        if (!await perm.Permission.storage.isGranted) {
          final status = await perm.Permission.storage.request();
          if (status != perm.PermissionStatus.granted) {
            permissionError.value = AppStrings.storagePermissionRequired;
            return false;
          }
        }
      }
      return true;
    } on PlatformException catch (e) {
      _logger.e('Error checking permissions: $e');
      permissionError.value = '${AppStrings.errorOccurred}: ${e.message}';
      return false;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadInitialData() async {
    try {
      if (_statusDirPath == null) {
        await _findStatusDirectory();
        if (_statusDirPath == null) {
          throw Exception('Status directory not found');
        }
      }

      isLoading.value = true;
      errorMessage.value = '';
      await _loadStatuses();
    } catch (e) {
      _logger.e('Error loading initial data: $e');
      if (e is PermissionDeniedException) {
        errorMessage.value = 'Permission denied. Please grant storage permission to continue.';
      } else {
        errorMessage.value = 'Failed to load statuses: ${e.toString()}';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches statuses from the WhatsApp status directory
  Future<void> _loadStatuses() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check if we have storage permissions
      if (!await WhatsAppStatusUtils.hasStoragePermission()) {
        final hasPermission = await WhatsAppStatusUtils.requestStoragePermission();
        if (!hasPermission) {
          errorMessage.value = 'Storage permission is required to access WhatsApp statuses';
          return;
        }
      }

      // Clear existing statuses
      statusList.clear();

      // Get status files using the best available method
      final files = await WhatsAppStatusUtils.getStatusFiles();

      if (files.isNotEmpty) {
        statusList.addAll(files);
        // Filter based on current selection
        _filterStatuses();
      } else {
        errorMessage.value = 'No statuses found. Make sure you have WhatsApp statuses saved.';
      }

    } catch (e) {
      _logger.e('Error loading statuses: $e');
      errorMessage.value = 'Failed to load statuses: ${e.toString()}';

      // If direct access failed, try using SAF
      if (e is FileSystemException) {
        _logger.i('Trying to load statuses using Storage Access Framework');
        final files = await WhatsAppStatusUtils.getStatusFiles(forceSAF: true);
        if (files.isNotEmpty) {
          statusList.addAll(files);
          _filterStatuses();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Downloads a status file to the downloads directory
  Future<void> downloadStatus(File file) async {
    try {
      if (!await _checkAndRequestPermissions()) {
        throw const PermissionDeniedException('Storage permission not granted');
      }

      final savedDir = Directory(_savedDirPath);
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final fileName = _generateUniqueFileName(file.path);
      final newFilePath = path.join(_savedDirPath, fileName);

      _logger.d('Saving file to: $newFilePath');

      // Check if file already exists
      final existingFile = File(newFilePath);
      if (await existingFile.exists()) {
        throw FileExistsException('File already exists');
      }

      // Copy the file
      await file.copy(newFilePath);

      // Update media store for gallery visibility
      // await _updateMediaStore(newFilePath);

      _logger.i('File saved successfully: $newFilePath');

      // Track download in analytics if needed
      // _trackDownload(file);

    } catch (e, stackTrace) {
      _logger.e('Error saving file', e, stackTrace);
      rethrow;
    }
  }

  // Filter statuses based on current filter setting
  void _filterStatuses() {
    if (currentFilter.value == StatusType.all) return;

    statusList.value = statusList.where((file) {
      final ext = path.extension(file.path).toLowerCase();
      if (currentFilter.value == StatusType.image) {
        return ['.jpg', '.jpeg', '.png', '.gif'].contains(ext);
      } else if (currentFilter.value == StatusType.video) {
        return ['.mp4', '.3gp', '.mkv', '.webm'].contains(ext);
      }
      return true;
    }).toList();
  }

  // Check if a file is an image
  bool isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif'].contains(ext);
  }

  // Check if a file is a video
  bool isVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['.mp4', '.3gp', '.mkv', '.webm'].contains(ext);
  }

  String _generateUniqueFileName(String originalPath) {
    final fileName = path.basename(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = path.extension(originalPath).toLowerCase();
    final nameWithoutExt = path.basenameWithoutExtension(fileName);
    return '${nameWithoutExt}_$timestamp$ext';
  }


}



