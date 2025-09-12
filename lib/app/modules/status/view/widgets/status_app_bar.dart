import 'package:flutter/material.dart';
import 'package:status_mate/app/theme/app_theme.dart';

class StatusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchPressed;
  final TabController? tabController;

  const StatusAppBar({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchPressed,
    this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: isSearching
          ? TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search statuses...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            )
          : const Text(
              'Status Saver',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: onSearchPressed,
        ),
      ],
      bottom: tabController != null
          ? TabBar(
              controller: tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Images'),
                Tab(text: 'Video'),
                Tab(text: 'All'),
              ],
            )
          : null,
    );
  }

  @override
  Size get preferredSize {
    if (tabController != null) {
      return const Size.fromHeight(kToolbarHeight * 2);
    }
    return const Size.fromHeight(kToolbarHeight);
  }
}
