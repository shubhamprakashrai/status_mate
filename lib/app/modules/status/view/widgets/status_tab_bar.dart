import 'package:flutter/material.dart';
import 'status_type.dart';

class StatusTabBar extends StatelessWidget {
  final TabController tabController;
  final ValueChanged<StatusType> onTabChanged;

  const StatusTabBar({
    super.key,
    required this.tabController,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 3.0,
      onTap: (index) => onTabChanged(StatusType.values[index]),
      tabs: const [
        Tab(icon: Icon(Icons.photo_library), text: 'Images'),
        Tab(icon: Icon(Icons.video_library), text: 'Videos'),
        Tab(icon: Icon(Icons.all_inbox), text: 'All'),
      ],
    );
  }
}
