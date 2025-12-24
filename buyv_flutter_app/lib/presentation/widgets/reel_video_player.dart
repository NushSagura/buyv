import 'package:flutter/material.dart';
import 'package:cached_video_player/cached_video_player.dart';
import '../../domain/models/reel_model.dart';

class ReelVideoPlayer extends StatefulWidget {
  final ReelModel reel;
  final bool isCurrentReel;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;

  const ReelVideoPlayer({
    super.key,
    required this.reel,
    required this.isCurrentReel,
    required this.isPlaying,
    this.onTogglePlay,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer>
    with WidgetsBindingObserver {
  CachedVideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle play/pause state changes
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && _isInitialized) {
        _controller?.play();
        _showPlayPauseIndicator(true);
      } else {
        _controller?.pause();
        _showPlayPauseIndicator(false);
      }
    }

    // Handle current reel changes
    if (widget.isCurrentReel != oldWidget.isCurrentReel) {
      if (!widget.isCurrentReel) {
        _controller?.pause();
      } else if (widget.isPlaying && _isInitialized) {
        _controller?.play();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_controller != null && _isInitialized) {
      switch (state) {
        case AppLifecycleState.paused:
          _controller!.pause();
          break;
        case AppLifecycleState.resumed:
          if (widget.isCurrentReel && widget.isPlaying) {
            _controller!.play();
          }
          break;
        default:
          break;
      }
    }
  }

  void _initializeVideo() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Try to use the actual video URL first
      if (widget.reel.videoUrl.isNotEmpty &&
          (widget.reel.videoUrl.startsWith('http') ||
              widget.reel.videoUrl.startsWith('https'))) {
        _controller = CachedVideoPlayerController.network(widget.reel.videoUrl);
      } else {
        // Fallback to sample video asset
        _controller = CachedVideoPlayerController.asset(
          'assets/videos/sample_reel.mp4',
        );
      }

      _controller!
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });

              _controller!.setLooping(true);

              // Auto-play if this is the current reel and should be playing
              if (widget.isCurrentReel && widget.isPlaying) {
                _controller!.play();
              }
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.toString();
              });
            }
            debugPrint('Error initializing video: $error');
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showPlayPauseIndicator(bool isPlaying) {
    setState(() {
      _showPlayPauseIcon = true;
    });

    // Hide the icon after 1 second
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _onVideoTap() {
    if (_isInitialized && _controller != null) {
      if (widget.onTogglePlay != null) {
        widget.onTogglePlay!();
      } else {
        // Fallback behavior
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _showPlayPauseIndicator(false);
        } else {
          _controller!.play();
          _showPlayPauseIndicator(true);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onVideoTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video or thumbnail
            if (_hasError)
              _buildErrorState()
            else if (!_isInitialized)
              _buildLoadingState()
            else
              _buildVideoPlayer(),

            // Play/Pause indicator
            if (_showPlayPauseIcon)
              Center(
                child: AnimatedOpacity(
                  opacity: _showPlayPauseIcon ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isPlaying ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Video progress indicator (optional)
            if (_isInitialized && _controller != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: false,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    backgroundColor: Colors.white24,
                    bufferedColor: Colors.white38,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CachedVideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        // Show thumbnail if available
        if (widget.reel.thumbnailUrl?.isNotEmpty == true)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.reel.thumbnailUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),

        // Loading indicator
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Stack(
      children: [
        // Show thumbnail if available
        if (widget.reel.thumbnailUrl?.isNotEmpty == true)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.reel.thumbnailUrl!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          // Nice gradient background for placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C3E50), Color(0xFF000000)],
              ),
            ),
          ),

        // Aesthetic Error/Placeholder Overlay
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_filter_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Demo Video',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(Content unavailable in test mode)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Retry button (kept small and subtle)
                TextButton.icon(
                  onPressed: () {
                    _controller?.dispose();
                    _controller = null;
                    _isInitialized = false;
                    _initializeVideo();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reload'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
