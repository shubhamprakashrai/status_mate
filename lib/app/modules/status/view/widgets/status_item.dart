import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// Top-level function for image decoding in isolate (pure Dart - works in isolate)
Future<Uint8List> decodeImageFile(String filePath) async {
  final file = File(filePath);
  return await file.readAsBytes();
}

class StatusItem extends StatefulWidget {
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
  State<StatusItem> createState() => _StatusItemState();
}

class _StatusItemState extends State<StatusItem>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _thumbnailBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  // Global caches
  static final Map<String, Uint8List> _cache = {};

  bool get _isVideo {
    final path = widget.file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.avi') ||
        path.endsWith('.mov') ||
        path.endsWith('.3gp') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm') ||
        path.endsWith('.m4v') ||
        path.endsWith('.flv');
  }

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final filePath = widget.file.path;

    // Check cache first
    if (_cache.containsKey(filePath)) {
      if (mounted) {
        setState(() {
          _thumbnailBytes = _cache[filePath];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      Uint8List? bytes;

      if (_isVideo) {
        // Video thumbnail - MUST run on main thread (platform channel)
        bytes = await _generateVideoThumbnail(filePath);
      } else {
        // Image decoding - can run in isolate (pure Dart)
        bytes = await compute(decodeImageFile, filePath);
      }

      if (bytes != null && bytes.isNotEmpty && mounted) {
        _cache[filePath] = bytes;
        setState(() {
          _thumbnailBytes = bytes;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Thumbnail error for $filePath: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // Generate video thumbnail on main thread (platform channels required)
  Future<Uint8List?> _generateVideoThumbnail(String filePath) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: filePath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 50,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('Video thumbnail generation failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            _buildThumbnail(),

            // Gradient overlay
            const _GradientOverlay(),

            // Video badge
            if (_isVideo) const _VideoBadge(),

            // Action buttons
            _ActionButtons(onSave: widget.onSave, onShare: widget.onShare),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_isLoading) {
      return const _LoadingPlaceholder();
    }

    if (_hasError || _thumbnailBytes == null) {
      return _isVideo ? const _VideoFallback() : const _ErrorPlaceholder();
    }

    return Image.memory(
      _thumbnailBytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 300,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) =>
          _isVideo ? const _VideoFallback() : const _ErrorPlaceholder(),
    );
  }
}

// ============ EXTRACTED CONST WIDGETS FOR PERFORMANCE ============

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline_rounded, size: 52, color: Colors.white38),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Color(0xB3000000),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
            SizedBox(width: 2),
            Text(
              'VIDEO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _ActionButtons({required this.onSave, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(icon: Icons.save_alt_rounded, onTap: onSave),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.share_rounded, onTap: onShare),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[800]),
      ),
    );
  }
}
