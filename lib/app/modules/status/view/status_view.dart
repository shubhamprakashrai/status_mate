import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:status_mate/app/modules/status/view/image_preview.dart';
import 'package:status_mate/app/modules/status/view/video_preview_page.dart';
import 'package:status_mate/app/theme/app_theme.dart';
import 'package:status_mate/core/constants/app_strings.dart';
import 'package:status_mate/core/utils/permission_utils.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../controllers/status_controller.dart';

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
    _checkPermissions();

    // Listen to permission error changes
    ever(controller.permissionError, (error) {
      if (error.isNotEmpty) {
        _showPermissionDialog();
      }
    });
  }

  Future<void> _refreshStatuses() async {
    // Reset search when refreshing
    _searchController.clear();
    _isSearching = false;
    // Force refresh to ensure we get the latest statuses
    await controller.loadStatuses(forceRefresh: true);
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await controller.checkAndRequestPermissions();
    if (!hasPermission) {
      final shouldOpenSettings = await _showPermissionDialog();
      if (shouldOpenSettings) {
        await PermissionUtils.openAppSettingsPage();
      }
    } else {
      // Refresh statuses if we have permissions
      await controller.loadStatuses();
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to access WhatsApp statuses.\n\nPlease grant the permission in app settings or use the file picker to select the WhatsApp status folder.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              PermissionUtils.openAppSettingsPage();
            },
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    ) ?? false;
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

  Widget _buildStatusItem(File file, BuildContext context) {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    final fileName = path.basename(file.path);
    final fileSize = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    final lastModified = DateFormat('MMM d, yyyy').format(file.lastModifiedSync());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Thumbnail
            Hero(
              tag: file.path,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.black12,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                size: 48,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VIDEO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // File info
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$fileSize MB • $lastModified',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        children: [
                          // Share button
                          _buildIconButton(
                            icon: Icons.share,
                            onPressed: () => _shareFile(file),
                            tooltip: 'Share',
                          ),
                          const SizedBox(width: 4),
                          // Download button
                          _buildIconButton(
                            icon: Icons.download,
                            onPressed: () => _downloadFile(file),
                            tooltip: 'Download',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
      ),
    );
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
      await Share.shareXFiles([XFile(file.path)],
          text: 'Check out this status!');
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading statuses',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.loadStatuses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => PermissionUtils.openAppSettingsPage(),
              child: const Text('Open Settings'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await controller.checkAndRequestPermissions();
                await controller.loadStatuses();
              },
              child: const Text('Try with File Picker'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search statuses...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Status Saver'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshStatuses,
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                } else {
                  _searchFocusNode.requestFocus();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Images'),
            Tab(text: 'Videos'),
          ],
          onTap: (index) {
            setState(() {
              _currentFilter = StatusType.values[index];
            });
          },
        ),
      ),
      body: Obx(() {
        if (controller.permissionError.value.isNotEmpty) {
          return _buildErrorView();
        }

        if (controller.isLoading.value) {
          return _buildLoadingShimmer();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadStatuses(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final statuses = _getFilteredStatuses();

        if (statuses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No statuses found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later or pull down to refresh',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.loadStatuses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final filteredStatuses = _getFilteredStatuses();

        if (filteredStatuses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No matching statuses found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchController.text.isNotEmpty) ...{
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                }
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadStatuses(),
          color: AppTheme.primaryColor,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredStatuses.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              return _buildStatusItem(filteredStatuses[index], context);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.loadStatuses,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
