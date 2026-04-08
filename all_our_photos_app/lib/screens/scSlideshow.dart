import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:aopmodel/aop_classes.dart';
import 'package:aopcommon/aopcommon.dart';
import '../utils/Config.dart';

class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen(
      {super.key, required this.snaps, this.startIndex = 0});
  final List<AopSnap> snaps;
  final int startIndex;

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPlaying = true;
  bool _controlsVisible = true;
  bool _captionVisible = true;

  Timer? _advanceTimer;
  Timer? _hideControlsTimer;
  VideoPlayerController? _videoController;
  int _intervalSeconds = 5;
  Future<void>? _nextImageReady;

  // ─── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _intervalSeconds =
        int.tryParse(config['slideshow_interval'] ?? '5') ?? 5;
    _initVideoIfNeeded();
    _startAdvanceTimer();
    _scheduleHideControls();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _advanceTimer?.cancel();
    _hideControlsTimer?.cancel();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  AopSnap get _currentSnap => widget.snaps[_currentIndex];

  void _initVideoIfNeeded() {
    _videoController?.dispose();
    _videoController = null;
    if (!_currentSnap.isVideo) return;
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(_currentSnap.fullSizeURL),
      httpHeaders: {'Preserve': WebFile.preserve},
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (_isPlaying) _videoController?.play();
        _videoController?.addListener(_videoListener);
      });
  }

  void _videoListener() {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos >= dur - const Duration(milliseconds: 300)) {
      ctrl.removeListener(_videoListener);
      _advanceToNext(waitForImage: false);
    }
  }

  void _startAdvanceTimer() {
    _advanceTimer?.cancel();
    _nextImageReady = null;
    if (_currentSnap.isVideo) return; // video advances via _videoListener
    // Start pre-caching the next image immediately so it's ready when the timer fires.
    final nextIndex = _currentIndex + 1;
    if (nextIndex < widget.snaps.length) {
      final nextSnap = widget.snaps[nextIndex];
      if (!nextSnap.isVideo) {
        _nextImageReady = precacheImage(
          NetworkImage(nextSnap.fullSizeURL,
              headers: {'Preserve': WebFile.preserve}),
          context,
        ).catchError((_) {}); // advance anyway on error
      }
    }
    _advanceTimer = Timer(Duration(seconds: _intervalSeconds), () {
      if (_isPlaying && mounted) _advanceToNext();
    });
  }

  Future<void> _advanceToNext({bool waitForImage = true}) async {
    if (_currentIndex < widget.snaps.length - 1) {
      if (waitForImage) {
        // Wait for the pre-cached image (up to 10 s extra), then transition.
        await _nextImageReady?.timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
      }
      if (!mounted) return;
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  // ─── event handlers ────────────────────────────────────────────────────────

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _initVideoIfNeeded();
    if (_isPlaying) _startAdvanceTimer();
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final bottomZone = constraints.maxHeight * 0.22;
    if (details.localPosition.dy >= constraints.maxHeight - bottomZone) {
      setState(() => _captionVisible = !_captionVisible);
    } else {
      setState(() => _controlsVisible = !_controlsVisible);
      if (_controlsVisible) _scheduleHideControls();
    }
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      if (_currentSnap.isVideo) {
        _videoController?.play();
      } else {
        _startAdvanceTimer();
      }
    } else {
      _advanceTimer?.cancel();
      _videoController?.pause();
    }
    _scheduleHideControls();
  }

  void _goToPrev() {
    _advanceTimer?.cancel();
    setState(() => _isPlaying = false);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _scheduleHideControls();
  }

  void _goToNext() {
    _advanceTimer?.cancel();
    setState(() => _isPlaying = false);
    _advanceToNext(waitForImage: false);
    _scheduleHideControls();
  }

  Future<void> _showIntervalDialog() async {
    double tempInterval = _intervalSeconds.toDouble();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Slide interval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tempInterval.round()} seconds'),
              Slider(
                value: tempInterval,
                min: 2,
                max: 30,
                divisions: 28,
                onChanged: (v) => setDlg(() => tempInterval = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                setState(() => _intervalSeconds = tempInterval.round());
                config['slideshow_interval'] = '$_intervalSeconds';
                config.save();
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints),
          child: Stack(
            children: [
              _buildPageView(),
              AnimatedOpacity(
                opacity: _captionVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildCaptionOverlay(),
                ),
              ),
              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.snaps.length,
      itemBuilder: (context, index) {
        final snap = widget.snaps[index];
        if (snap.isVideo && index == _currentIndex) {
          return _buildVideoPage();
        }
        // Show thumbnail for off-screen video pages; full image for photos
        final url = snap.isVideo ? snap.thumbnailURL : snap.fullSizeURL;
        return Image.network(url,
            fit: BoxFit.contain,
            headers: {'Preserve': WebFile.preserve});
      },
    );
  }

  Widget _buildVideoPage() {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: ctrl.value.aspectRatio,
        child: VideoPlayer(ctrl),
      ),
    );
  }

  Widget _buildCaptionOverlay() {
    final snap = _currentSnap;
    final parts = <String>[
      if (snap.caption != null && snap.caption!.isNotEmpty) snap.caption!,
      if (snap.location != null && snap.location!.isNotEmpty) snap.location!,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      child: Text(
        parts.join('\n'),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        // Top bar
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  '${_currentIndex + 1} / ${widget.snaps.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _showIntervalDialog,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom controls bar
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous,
                    color: Colors.white, size: 36),
                onPressed: _currentIndex > 0 ? _goToPrev : null,
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 56,
                ),
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 24),
              IconButton(
                icon:
                    const Icon(Icons.skip_next, color: Colors.white, size: 36),
                onPressed: _currentIndex < widget.snaps.length - 1
                    ? _goToNext
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
