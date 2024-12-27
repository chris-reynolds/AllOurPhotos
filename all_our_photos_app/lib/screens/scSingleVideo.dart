// This file contains the code for the single video screen
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SingleVideoWidget extends StatefulWidget {
  const SingleVideoWidget(this.url);
  final String url;
  @override
  State<SingleVideoWidget> createState() => _SingleVideoWidgetState();
}

class _SingleVideoWidgetState extends State<SingleVideoWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((value) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = _controller.value.isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = Theme.of(context).colorScheme.secondary;
    return Scaffold(
        body: Center(
      child: _controller.value.isInitialized
          ? SingleChildScrollView(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  Row(
                    children: [
                      IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: buttonColor,
                            size: 40,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      Spacer(),
                      if (_isPlaying)
                        IconButton(
                            icon: Icon(
                              Icons.restart_alt,
                              color: buttonColor,
                              size: 40,
                            ),
                            onPressed: () {
                              _controller.seekTo(Duration.zero);
                            }),
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
              ),
            )
          : CircularProgressIndicator(),
    ));
  }
}
