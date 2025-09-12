import 'dart:io';
import 'package:flutter/material.dart';

class StatusListItem extends StatelessWidget {
  final File file;
  final Function(File) onDownload;
  final Function(File) onShare;
  final Function(File) onTap;

  const StatusListItem({
    super.key,
    required this.file,
    required this.onDownload,
    required this.onShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    final fileName = file.path.split('/').last;
    final fileSize = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    final lastModified = DateTime.fromMillisecondsSinceEpoch(
      file.lastModifiedSync().millisecondsSinceEpoch,
    ).toString().split(' ')[0];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onTap(file),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Thumbnail
            Hero(
              tag: file.path,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo
                    ? _buildVideoThumbnail()
                    : _buildImageThumbnail(),
              ),
            ),
            // Gradient overlay
            _buildGradientOverlay(),
            // File info
            _buildFileInfo(context, fileName, fileSize, lastModified, isVideo),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Stack(
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
    );
  }

  Widget _buildImageThumbnail() {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
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
    );
  }

  Widget _buildFileInfo(
    BuildContext context,
    String fileName,
    String fileSize,
    String lastModified,
    bool isVideo,
  ) {
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   fileName,
          //   maxLines: 1,
          //   overflow: TextOverflow.ellipsis,
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 12,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$fileSize MB • $lastModified',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
              Row(
                children: [
                  _buildIconButton(
                    icon: Icons.share,
                    onPressed: () => onShare(file),
                    tooltip: 'Share',
                  ),
                  // const SizedBox(width: 4),
                  // _buildIconButton(
                  //   icon: Icons.download,
                  //   onPressed: () {},
                  //   tooltip: 'Download',
                  // ),
                ],
              ),
            ],
          ),
        ],
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
}
