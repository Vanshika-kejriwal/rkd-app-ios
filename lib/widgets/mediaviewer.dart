import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR SYSTEMCHROME
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

class FullScreenSwiperScreen extends StatefulWidget {
  final List<Map<String, dynamic>> mediaItems;
  final int initialIndex;

  const FullScreenSwiperScreen(
      {super.key, required this.mediaItems, required this.initialIndex});

  @override
  State<FullScreenSwiperScreen> createState() => _FullScreenSwiperScreenState();
}

class _FullScreenSwiperScreenState extends State<FullScreenSwiperScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Start with default overlays visible
    _showSystemUI();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // CRITICAL: Restore normal phone status bars when leaving the gallery screen
    _restoreSystemUI();
    super.dispose();
  }

  bool _isVideo(String url) =>
      url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');

  // Hide status bar and bottom soft keys completely (Lean Back Mode)
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Restore status bar and bottom soft keys
  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Fallback cleanup reset for app safety
  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays:
          SystemUiOverlay.values, // Brings back both status and navigation bars
    );
  }

  void _toggleAppBarVisibility() {
    setState(() {
      _isAppBarVisible = !_isAppBarVisible;
      if (_isAppBarVisible) {
        _showSystemUI();
      } else {
        _hideSystemUI();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. THE INTERACTIVE GALLERY CONTAINER LAYOUT
          GestureDetector(
            onTap: _toggleAppBarVisibility,
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.mediaItems.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                final url = widget.mediaItems[index]['url_or_path'].toString();
                final directUrl = url.replaceAll('?dl=0', '?raw=1');

                if (_isVideo(directUrl)) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: SwiperVideoItem(
                        url: directUrl, isActive: index == _currentIndex),
                    disableGestures: true,
                  );
                } else {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTap: _toggleAppBarVisibility,
                      child: PhotoView(
                        imageProvider: CachedNetworkImageProvider(directUrl),
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained * 1.0,
                        maxScale: PhotoViewComputedScale.covered * 3.0,
                        heroAttributes:
                            PhotoViewHeroAttributes(tag: 'image_$index'),
                      ),
                    ),
                  );
                }
              },
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

          // 2. ANIMATED SLIDING TOP APP BAR OVERLAY
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _isAppBarVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                color: Colors.black54,
              ),
              child: NavigationToolbar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _restoreSystemUI(); // Restore OS elements before backing out
                    Navigator.pop(context);
                  },
                ),
                centerMiddle: true,
                middle: Text(
                  '${_currentIndex + 1} / ${widget.mediaItems.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwiperVideoItem extends StatefulWidget {
  final String url;
  final bool isActive;

  const SwiperVideoItem({super.key, required this.url, required this.isActive});

  @override
  State<SwiperVideoItem> createState() => _SwiperVideoItemState();
}

class _SwiperVideoItemState extends State<SwiperVideoItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          if (widget.isActive) _controller.play();
        }
      });
  }

  @override
  void didUpdateWidget(covariant SwiperVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (!widget.isActive && oldWidget.isActive) {
        _controller.pause();
      } else if (widget.isActive && !oldWidget.isActive) {
        _controller.play();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: GestureDetector(
        onTap: () async {
          // 1. Execute the asynchronous video action outside of setState
          if (_controller.value.isPlaying) {
            await _controller.pause();
          } else {
            await _controller.play();
          }

          // 2. Synchronously refresh the UI state to update the play/pause icon overlay
          if (mounted) {
            setState(() {});
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller)),
            if (!_controller.value.isPlaying)
              const Icon(Icons.play_arrow, size: 80, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
