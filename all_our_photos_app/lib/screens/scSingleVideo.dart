// This file contains the code for the single video screen
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:aopcommon/aopcommon.dart';

class SingleVideoWidget extends StatefulWidget {
  const SingleVideoWidget(this.url);
  final String url;
  @override
  State<SingleVideoWidget> createState() => _SingleVideoWidgetState();
}

class _SingleVideoWidgetState extends State<SingleVideoWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _toggling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {'Preserve': WebFile.preserve},
    )..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((e) {
        if (mounted) setState(() => _error = '$e');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_controller.value.isInitialized || _toggling) return;
    _toggling = true;
    try {
      if (_controller.value.isPlaying) {
        await _controller.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _controller.play();
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Playback error: $e');
    } finally {
      _toggling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      body: Center(
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: buttonColor, size: 40),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                ],
              )
            : _controller.value.isInitialized
                ? Stack(
                      children: [
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: buttonColor, size: 40),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            if (_isPlaying)
                              IconButton(
                                icon: Icon(Icons.restart_alt,
                                    color: buttonColor, size: 40),
                                onPressed: () =>
                                    _controller.seekTo(Duration.zero),
                              ),
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: buttonColor,
                                size: 40,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ],
                        ),
                      ],
                    )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
