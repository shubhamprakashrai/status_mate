import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:status_mate/app/modules/status/view/image_preview.dart';
import 'package:status_mate/app/modules/status/view/video_preview_page.dart';
import 'package:status_mate/app/theme/app_theme.dart';
import '../controllers/status_controller.dart';
import 'widgets/status_app_bar.dart';
import 'widgets/status_grid_view.dart';
import 'widgets/status_shimmer_loader.dart';

enum StatusType { image, video, all }

class StatusView extends StatefulWidget {
  const StatusView({super.key});

  @override
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView> with SingleTickerProviderStateMixin {
  final StatusController controller = Get.put(StatusController());
  late TabController _tabController;
  StatusType _currentFilter = StatusType.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Initial fetch of statuses
    controller.fetchStatuses();
  }

  void _handleTabChange() {
    setState(() {
      _currentFilter = StatusType.values[_tabController.index];
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
    return controller.statusList.where((file) {
      final isVideo = file.path.toLowerCase().endsWith('.mp4');
      final matchesSearch = _searchController.text.isEmpty ||
          file.path.toLowerCase().contains(_searchController.text.toLowerCase());
      
      if (_currentFilter == StatusType.image) {
        return !isVideo && matchesSearch;
      } else if (_currentFilter == StatusType.video) {
        return isVideo && matchesSearch;
      }
      return matchesSearch;
    }).toList();
  }

  Future<void> _openDownloadsFolder() async {
    try {
      final directory = Directory(controller.downloadsPath);
      if (await directory.exists()) {
        // Try to open the directory
        final result = await OpenFile.open(directory.path);
        
        // If opening directory fails (which can happen on some platforms),
        // show a snackbar with the directory path
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opened download folder at: ${directory.path}'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download folder not found'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening folder: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(File file) async {
    try {
      await controller.downloadStatus(file);
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
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: _openDownloadsFolder,
            ),
            duration: const Duration(seconds: 4), // Give user more time to see and tap the action
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
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Check out this status!',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToPreview(File file) {
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
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: StatusAppBar(
        isSearching: _isSearching,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        tabController: _tabController,
        onSearchPressed: _toggleSearch,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const StatusShimmerLoader();
        }

        return StatusGridView(
          statusList: _getFilteredStatuses(),
          onItemTap: _navigateToPreview,
          onDownload: _downloadFile,
          onShare: _shareFile,
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.fetchStatuses,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
