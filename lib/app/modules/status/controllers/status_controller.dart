import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:status_mate/app/routes/app_pages.dart';
import 'package:status_mate/core/constants/storage_keys.dart';
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

  // Timer for auto-refresh
  Timer? _refreshTimer;

  // Status directory path
  static const String _statusDirPath =
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';

  // Saved status directory path
  static String get _savedDirPath => '/storage/emulated/0/Download/StatusMate';

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
    // Check for new statuses every 30 seconds
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

  /// Fetches statuses from the WhatsApp status directory
  Future<void> fetchStatuses() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check if we have necessary permissions
      if (!await _checkAndRequestPermissions()) {
        throw const PermissionDeniedException('Storage permission not granted');
      }

      final dir = Directory(_statusDirPath);
      _logger.d('Checking status directory: ${dir.path}');

      if (!await dir.exists()) {
        _logger.w('Status directory does not exist');
        errorMessage.value = 'WhatsApp status directory not found. Make sure you have statuses saved.';
        return;
      }

      // List all files and filter by type
      final files = await dir.list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      // Filter based on current filter setting
      final filteredFiles = files.where((file) {
        if (currentFilter.value == StatusType.image) {
          return _isImageFile(file.path);
        } else if (currentFilter.value == StatusType.video) {
          return _isVideoFile(file.path);
        }
        return _isImageFile(file.path) || _isVideoFile(file.path);
      }).toList();

      // Sort by last modified (newest first)
      filteredFiles.sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

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

  // Helper methods
  Future<bool> _checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true;

    final permissions = await PermissionUtils.requestStoragePermissions();
    return permissions.isGranted;
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
    final fileName = path.basename(originalPath);
    final timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    final ext = path.extension(originalPath).toLowerCase();
    return ext;
  }


}



