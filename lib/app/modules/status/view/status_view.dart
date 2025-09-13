import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:status_mate/app/modules/status/controllers/status_controller.dart' as status_controller;
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

class _StatusViewState extends State<StatusView> with SingleTickerProviderStateMixin {
  final status_controller.StatusController _statusController = Get.find<status_controller.StatusController>();
  late TabController _tabController;
  status_controller.StatusType _currentFilter = status_controller.StatusType.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  // Remove unused field

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed length to 3 for All, Images, Videos
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
      _currentFilter = status_controller.StatusType.values[_tabController.index];
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
          file.path.toLowerCase().contains(_searchController.text.toLowerCase());
      
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
              return isVideo 
                  ? VideoPreviewPage(file) 
                  : ImagePreviewPage(file);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
      onShare: () => _shareFile(file),
    );
  }


  Future<void> _downloadFile(File file) async {
    try {
      await _statusController.downloadStatus(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Downloaded successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share file')),
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
