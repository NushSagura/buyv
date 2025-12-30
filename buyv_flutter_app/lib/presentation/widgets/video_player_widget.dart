import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/utils/remote_logger.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Prevent double initialization
    if (_controller != null) {
      debugPrint('⚠️ Controller already exists, skipping initialization');
      return;
    }

    debugPrint('🎥 VideoPlayerWidget: Initializing video player');
    debugPrint('🎥 Video URL: ${widget.videoUrl}');

    // Validation upfront
    if (widget.videoUrl.isEmpty) {
      debugPrint('❌ Video URL is empty!');
      setState(() {
        _hasError = true;
        _errorMessage = 'Empty video URL';
      });
      return;
    }

    if (!widget.videoUrl.startsWith('http://') &&
        !widget.videoUrl.startsWith('https://')) {
      debugPrint('❌ Invalid video URL (not HTTP/HTTPS): ${widget.videoUrl}');
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid URL format';
      });
      return;
    }

    try {
      debugPrint('🎥 Creating VideoPlayerController...');
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      debugPrint('🎥 Initializing controller...');
      await _controller!.initialize().catchError((error) {
        debugPrint('⚠️ Error initializing video: $error');
        throw error;
      });

      debugPrint('✅ Video initialized successfully!');
      debugPrint('📺 Video dimensions: ${_controller!.value.size}');
      debugPrint('⏱️ Video duration: ${_controller!.value.duration}');

      if (widget.autoPlay) {
        debugPrint('▶️ Auto-playing video...');
        _controller!.play();
        _isPlaying = true;
      }

      if (widget.looping) {
        _controller!.setLooping(true);
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ ERROR initializing video player: $e');
      debugPrint('❌ Video URL that failed: ${widget.videoUrl}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void deactivate() {
    // Called when widget is removed from tree temporarily
    // Stop video immediately to prevent audio bleed
    RemoteLogger.videoLog('Widget deactivate() called', data: {
      'isPlaying': _controller?.value.isPlaying ?? false,
      'url': widget.videoUrl,
    });
    
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
      _controller!.setVolume(0);
      RemoteLogger.videoLog('Video stopped in deactivate()');
    }
    super.deactivate();
  }

  @override
  void dispose() {
    // Final cleanup when widget is permanently removed
    RemoteLogger.videoLog('Widget dispose() called', data: {
      'isPlaying': _controller?.value.isPlaying ?? false,
      'url': widget.videoUrl,
    });
    
    if (_controller != null) {
      // Triple-ensure no audio plays
      try {
        _controller!.pause();
        _controller!.setVolume(0);
        _controller!.seekTo(Duration.zero); // Reset position
        _controller!.dispose();
        RemoteLogger.videoLog('Video controller disposed successfully');
      } catch (e) {
        // Ignore disposal errors on some devices
        RemoteLogger.error('Error disposing video controller', error: e);
      } finally {
        _controller = null;
      }
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
        debugPrint('⏸️ Video paused by user tap');
      } else {
        _controller!.play();
        _isPlaying = true;
        debugPrint('▶️ Video playing by user tap');
      }
      _showPlayPauseIcon = true;
    });

    // Hide icon after 1 second
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!_initialized || _controller == null || !mounted) return;

    // Pauser et couper le son plus tôt pour éviter le lag audio
    if (info.visibleFraction < 0.5) {
      if (_controller!.value.isPlaying) {
        try {
          _controller!.pause();
          _controller!.setVolume(0.0); // Mute total
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        } catch (e) {
          // Ignore errors on some devices
        }
      }
    } else if (info.visibleFraction >= 0.8 && widget.autoPlay) {
      // Restore volume and play when fully visible
      if (!_controller!.value.isPlaying && mounted) {
        try {
          _controller!.setVolume(1.0);
          _controller!.play();
          if (mounted) {
            setState(() {
              _isPlaying = true;
            });
          }
        } catch (e) {
          // Ignore errors on some devices
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Video Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? 'Failed to load video',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                    _initialized = false;
                  });
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: Key('video_${widget.videoUrl}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlayPause,
        behavior: HitTestBehavior.opaque, // Intercepte le tap sans le propager au parent
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            // Play/Pause icon overlay
            if (_showPlayPauseIcon)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(
                  _isPlaying ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 50,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
