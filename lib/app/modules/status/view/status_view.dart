import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:status_mate/app/modules/status/controllers/status_controller.dart'
    as status_controller;
import 'package:status_mate/app/modules/status/view/image_preview.dart';
import 'package:status_mate/app/modules/status/view/video_preview_page.dart';
import 'package:status_mate/app/theme/app_theme.dart';
import 'package:status_mate/core/utils/permission_utils.dart';

// Widgets
import 'widgets/status_item.dart';
import 'widgets/permission_dialog.dart';
// Remove unused import

class StatusView extends StatefulWidget {
  const StatusView({super.key});

  @override
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView>
    with SingleTickerProviderStateMixin {
  final status_controller.StatusController _statusController =
      Get.find<status_controller.StatusController>();
  late TabController _tabController;
  status_controller.StatusType _currentFilter =
      status_controller.StatusType.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  // Remove unused field

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _checkPermissions();
  }

  Future<void> _refreshStatuses() async {
    _searchController.clear();
    await _statusController.loadStatuses(forceRefresh: true);
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _statusController.checkAndRequestPermissions();
    if (!hasPermission) {
      final shouldOpenSettings = await _showPermissionDialog();
      if (shouldOpenSettings) {
        await PermissionUtils.openAppSettingsPage();
      }
    } else {
      await _statusController.loadStatuses();
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await PermissionDialog.show(context);
  }

  void _handleTabChange() {
    setState(() {
      _currentFilter =
          status_controller.StatusType.values[_tabController.index];
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<File> _getFilteredStatuses() {
    return _statusController.statusList.where((file) {
      final isVideo = file.path.toLowerCase().endsWith('.mp4');
      final matchesSearch = _searchController.text.isEmpty ||
          file.path
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      if (_currentFilter == status_controller.StatusType.image) {
        return !isVideo && matchesSearch;
      } else if (_currentFilter == status_controller.StatusType.video) {
        return isVideo && matchesSearch;
      }
      return matchesSearch;
    }).toList();
  }

  Widget _buildStatusItem(File file, BuildContext context) {
    return StatusItem(
      file: file,
      onTap: () {
        final isVideo = file.path.toLowerCase().endsWith('.mp4');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return isVideo ? VideoPreviewPage(file) : ImagePreviewPage(file);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      onDelete: () {
        // Implement delete functionality
        Get.snackbar('Info', 'Delete functionality will be implemented here');
      },
      onSave: () => _downloadFile(file),
      onShare: () => _shareFile(file, context),
    );
  }

  Future<void> _downloadFile(File file) async {
  try {
    final fileName = file.uri.pathSegments.last;
    final isVideo = fileName.toLowerCase().endsWith('.mp4');

    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Choose correct folder
      final saveDir = isVideo
          ? Directory('${downloadsDir.path}/StatusMate/Videos')
          : Directory('${downloadsDir.path}/StatusMate/Images');

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final newPath = '${saveDir.path}/$fileName';
      await file.copy(newPath);

       await MediaScanner.loadMedia(path: newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $newPath'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      // iOS: save to app documents
      final appDir = await getApplicationDocumentsDirectory();
      final newPath = '${appDir.path}/$fileName';
      await file.copy(newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to app storage: $newPath')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}


  Future<void> _shareFile(File file, BuildContext context) async {
    try {
      // Copy to cache (for Android 11+ scoped storage issues)
      final tempDir = await getTemporaryDirectory();
      final tempFile = await file.copy(
        '${tempDir.path}/${file.uri.pathSegments.last}',
      );

      ShareParams params;

      // Only set sharePositionOrigin for iPad
      if (Theme.of(context).platform == TargetPlatform.iOS &&
          MediaQuery.of(context).size.shortestSide > 600) {
        final box = context.findRenderObject();
        if (box is RenderBox) {
          params = ShareParams(
            files: [XFile(tempFile.path)],
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
          );
        } else {
          // fallback if context isn't a RenderBox
          params = ShareParams(files: [XFile(tempFile.path)]);
        }
      } else {
        // Android / iPhone → no need for sharePositionOrigin
        params = ShareParams(files: [XFile(tempFile.path)]);
      }

      await SharePlus.instance.share(params);
    } catch (e) {
      print("Failed to share file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share file: $e')),
        );
      }
    }
  }



  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 9, // Number of shimmer items
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  // Error handling is now done in _buildEmptyState

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _statusController.errorMessage.value.isEmpty
                ? 'No statuses found'
                : _statusController.errorMessage.value,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshStatuses,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'Images'),
        Tab(text: 'Videos'),
      ],
      onTap: (index) {
        setState(() {
          _currentFilter = status_controller.StatusType.values[index];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Saver'),
        bottom: _buildTabBar(),
      ),
      body: Obx(() {
        if (_statusController.isLoading.value) {
          return _buildLoadingShimmer();
        }

        final statuses = _getFilteredStatuses();
        if (statuses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshStatuses,
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.7,
            ),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              return _buildStatusItem(statuses[index], context);
            },
          ),
        );
      }),
    );
  }
}
