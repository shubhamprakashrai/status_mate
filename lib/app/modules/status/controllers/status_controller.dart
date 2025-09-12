import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:status_mate/core/errors/exceptions.dart';
import 'package:status_mate/core/logger/app_logger.dart';
import 'package:status_mate/core/storage/local_storage_service.dart';
import 'package:status_mate/core/utils/permission_utils.dart';

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

  // WhatsApp and WA Business status directories
  static const String _waStatusPath =
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
  static const String _waBusinessStatusPath =
      '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';

  // Saved status directory path
  static String get _savedDirPath => '/storage/emulated/0/Download/StatusMate';

  String get downloadsPath => _savedDirPath;

  @override
  void onInit() {
    super.onInit();
    _setupAutoRefresh();
    _loadInitialData();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isLoading.value) {
        fetchStatuses();
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _checkAndRequestPermissions();
    await fetchStatuses();
  }

  /// Fetches statuses from WhatsApp / WhatsApp Business folders
  Future<void> fetchStatuses() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (!await _checkAndRequestPermissions()) {
        throw const PermissionDeniedException('Storage permission not granted');
      }

      final possiblePaths = [_waStatusPath, _waBusinessStatusPath];
      Directory? foundDir;

      for (final dirPath in possiblePaths) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          foundDir = dir;
          _logger.i('Found statuses folder: $dirPath');
          break;
        } else {
          _logger.w('Directory not found: $dirPath');
        }
      }

      if (foundDir == null) {
        errorMessage.value =
            'No WhatsApp statuses found. Please open WhatsApp and check a status first.';
        return;
      }

      final files = await foundDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      final filteredFiles = files.where((file) {
        if (currentFilter.value == StatusType.image) {
          return _isImageFile(file.path);
        } else if (currentFilter.value == StatusType.video) {
          return _isVideoFile(file.path);
        }
        return _isImageFile(file.path) || _isVideoFile(file.path);
      }).toList();

      filteredFiles.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      statusList.assignAll(filteredFiles);
      _logger.i('Fetched ${filteredFiles.length} statuses');
    } catch (e, stackTrace) {
      _logger.e('Error fetching statuses', e, stackTrace);
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Downloads a status file to the downloads directory
  Future<void> downloadStatus(File file) async {
    final stopwatch = Stopwatch()..start();
    final fileSize = await file.length();
    _logger.d(
        'Starting download of file: ${file.path} (${fileSize / 1024} KB)');

    try {
      if (!await _checkAndRequestPermissions()) {
        throw const PermissionDeniedException('Storage permission not granted');
      }

      final savedDir = Directory(_savedDirPath);
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      // Generate a unique filename
      final fileName = _generateUniqueFileName(file.path);
      final newFilePath = path.join(_savedDirPath, fileName);

      _logger.d('Saving file to: $newFilePath');

      // Copy file safely
      final savedFile = await file.copy(newFilePath);

      // Verify integrity
      final savedFileSize = await savedFile.length();
      if (savedFileSize != fileSize) {
        _logger.e(
            'File size mismatch: expected $fileSize bytes, got $savedFileSize bytes');
        await savedFile.delete();
        throw Exception('File copy failed: size mismatch');
      }

      _logger.i(
          'File saved successfully: $newFilePath (${savedFileSize / 1024} KB in ${stopwatch.elapsedMilliseconds}ms)');

      // Optional: Update MediaStore so file appears in Gallery
      try {
        await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://$newFilePath']);
        _logger.i('MediaScanner updated for: $newFilePath');
      } catch (e) {
        _logger.w('MediaScanner update failed: $e');
      }
    } catch (e, stackTrace) {
      _logger.e('Error saving file', e, stackTrace);
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  // Helpers
  Future<bool> _checkAndRequestPermissions() async {
    bool hasPermissions = await PermissionUtils.hasRequiredPermissions();

    while (!hasPermissions) {
      final status = await PermissionUtils.requestStoragePermissions();

      if (!status) {
        errorMessage.value =
            'Storage permission is required to access WhatsApp statuses';
        final shouldOpenSettings = await showPermissionRequiredDialog();

        if (shouldOpenSettings) {
          try {
            await PermissionUtils.openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            _logger.e('Error opening app settings', e);
            await Get.snackbar(
              'Error',
              'Could not open settings. Please enable permissions manually.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } else {
          continue;
        }
      }
      hasPermissions = await PermissionUtils.hasRequiredPermissions();
    }

    return true;
  }

  Future<bool> showPermissionRequiredDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Storage permission is required to access WhatsApp statuses. '
              'Please grant the permission to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  bool _isVideoFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext);
  }

  String _generateUniqueFileName(String originalPath) {
    final fileName = path.basenameWithoutExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final ext = path.extension(originalPath).toLowerCase();
    return '${fileName}_${timestamp}_$random$ext';
  }
}
