import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
