import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class StatusItem extends StatelessWidget {
  final File file;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const StatusItem({
    super.key,
    required this.file,
    required this.onTap,
    required this.onDelete,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    final fileName = path.basename(file.path);
    // final fileSize = _formatFileSize(file.lengthSync());
    // final lastModified = _formatDate(File(file.path).lastModifiedSync());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail and video indicator
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Thumbnail
                  isVideo
                      ? const Icon(Icons.videocam, size: 50, color: Colors.grey)
                      : Image.file(
                          file,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 50),
                        ),
                  // Video play icon overlay
                  if (isVideo)
                    const Icon(
                      Icons.play_circle_fill,
                      size: 50,
                      color: Colors.white70,
                    ),
                ],
              ),
            ),
            // File info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       fileSize,
                  //       style: const TextStyle(fontSize: 12, color: Colors.grey),
                  //     ),
                  //     Text(
                  //       lastModified,
                  //       style: const TextStyle(fontSize: 12, color: Colors.grey),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
            // Action buttons
            OverflowBar(
              overflowDirection: VerticalDirection.down,
              alignment: MainAxisAlignment.spaceEvenly,
              overflowSpacing: 12,
              children: [
                InkWell(
                  onTap: onSave,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: const Icon(Icons.save_alt, size: 20),
                  ),
                ),

                InkWell(
                  onTap: onShare,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: const Icon(Icons.share, size: 20),
                  ),
                ),

                // const SizedBox(width: 8),

                // InkWell(
                //   child: const Icon(Icons.delete, size: 20),
                //   onTap: onDelete,
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y HH:mm').format(date);
  }
}
