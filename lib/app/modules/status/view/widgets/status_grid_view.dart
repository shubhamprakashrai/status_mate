import 'dart:io';

import 'package:flutter/material.dart';
import 'package:status_mate/app/modules/status/view/widgets/status_list_item.dart';

class StatusGridView extends StatelessWidget {
  final List<File> statusList;
  final Function(File) onItemTap;
  final Function(File) onDownload;
  final Function(File) onShare;

  const StatusGridView({
    super.key,
    required this.statusList,
    required this.onItemTap,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (statusList.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: statusList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final file = statusList[index];
        return StatusListItem(
          file: file,
          onTap: onItemTap,
          onDownload: onDownload,
          onShare: onShare,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No statuses found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or pull down to refresh',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
