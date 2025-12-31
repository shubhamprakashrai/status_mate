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

import 'widgets/status_item.dart';
import 'widgets/permission_dialog.dart';

class StatusView extends StatefulWidget {
  const StatusView({super.key});

  @override
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final status_controller.StatusController _statusController =
      Get.find<status_controller.StatusController>();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
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

  List<File> _getFilteredStatuses(status_controller.StatusType filterType) {
    return _statusController.statusList.where((file) {
      final matchesSearch = _searchController.text.isEmpty ||
          file.path.toLowerCase().contains(_searchController.text.toLowerCase());

      final isVideoFile = _isVideo(file);

      switch (filterType) {
        case status_controller.StatusType.all:
          return matchesSearch;
        case status_controller.StatusType.image:
          return !isVideoFile && matchesSearch;
        case status_controller.StatusType.video:
          return isVideoFile && matchesSearch;
      }
    }).toList();
  }

  bool _isVideo(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.avi') ||
        path.endsWith('.mov') ||
        path.endsWith('.3gp') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm') ||
        path.endsWith('.m4v') ||
        path.endsWith('.flv');
  }

  Widget _buildTabContent(status_controller.StatusType filterType) {
    return Obx(() {
      if (_statusController.isLoading.value) {
        return _buildLoadingShimmer();
      }

      final statuses = _getFilteredStatuses(filterType);
      if (statuses.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: _refreshStatuses,
        edgeOffset: 0,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          cacheExtent: 500, // Pre-cache items for smoother scrolling
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return RepaintBoundary(
                      child: _buildStatusItem(statuses[index], context, index),
                    );
                  },
                  childCount: statuses.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: false, // We handle this manually
                ),
              ),
            ),
            // Add bottom padding for better scroll experience
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1D4D3A), // Darker green for contrast
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF25D366), Color(0xFF20BD5A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          splashBorderRadius: BorderRadius.circular(10),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('All'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Images'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Videos'),
                ],
              ),
            ),
          ],
          onTap: (index) {
            _searchController.clear();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildStatusItem(File file, BuildContext context, int index) {
    return StatusItem(
      key: ValueKey(file.path), // Stable key for better recycling
      file: file,
      onTap: () {
        final isVideo = _isVideo(file);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return isVideo ? VideoPreviewPage(file) : ImagePreviewPage(file);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      onDelete: () {
        Get.snackbar('Info', 'Delete functionality will be implemented here');
      },
      onSave: () => _downloadFile(file),
      onShare: () => _shareFile(file, context),
    );
  }

  Future<void> _downloadFile(File file) async {
    try {
      final fileName = file.uri.pathSegments.last;
      final isVideo = _isVideo(file);

      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

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
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final extension = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      final tempDir = await getTemporaryDirectory();
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final tempFile = await file.copy('${tempDir.path}/$uniqueFileName');

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: mimeType)],
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error sharing file: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: ${e.toString().split(':').last.trim()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case '3gp':
        return 'video/3gpp';
      default:
        return 'application/octet-stream';
    }
  }

  Widget _buildLoadingShimmer() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Saver'),
        bottom: _buildTabBar(),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(), // Smooth tab switching
        children: [
          _buildTabContent(status_controller.StatusType.all),
          _buildTabContent(status_controller.StatusType.image),
          _buildTabContent(status_controller.StatusType.video),
        ],
      ),
    );
  }
}
