import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  final File file;
  const VideoPreviewPage(this.file, {super.key});

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  Timer? _hideTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if file exists
      if (!await widget.file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _controller = VideoPlayerController.file(widget.file);

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
        _controller!.setLooping(true);
        _startHideTimer();
        _animController.forward();
      }

      _controller!.addListener(_videoListener);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: ${e.toString()}';
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      setState(() {});
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        _startHideTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError
          ? _buildErrorView()
          : _isInitialized
              ? _buildVideoPlayer()
              : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF25D366)),
          SizedBox(height: 16),
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(),

                      // Center play button
                      Expanded(child: _buildCenterPlayButton()),

                      // Bottom controls
                      _buildBottomControls(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Video Preview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    if (_controller == null) return const SizedBox();

    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_controller == null) return const SizedBox();

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF25D366),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF25D366),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackHeight: 3,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).toInt(),
                );
                _controller!.seekTo(newPosition);
                _startHideTimer();
              },
            ),
          ),

          // Time and controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      iconSize: 28,
                      onPressed: () {
                        final newPosition = position - const Duration(seconds: 10);
                        _controller!.seekTo(newPosition);
                        _startHideTimer();
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      iconSize: 28,
                      onPressed: () {
                        final newPosition = position + const Duration(seconds: 10);
                        _controller!.seekTo(newPosition);
                        _startHideTimer();
                      },
                    ),
                  ],
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
