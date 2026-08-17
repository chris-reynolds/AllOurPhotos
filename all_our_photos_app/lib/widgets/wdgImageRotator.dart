// created by chris r. 18th Sept 2024
// this widget is to gently rotate a photo to allow you to adjust the horizon

import 'package:aopmodel/aop_classes.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'dart:math' as math;
import '../flutter_common/WidgetSupport.dart';

class ImageRotator extends StatefulWidget {
  final AopSnap snap;
  final Function() closeRotator;

  const ImageRotator({required this.snap, required this.closeRotator});

  @override
  State<ImageRotator> createState() => _ImageRotatorState();
}

class _ImageRotatorState extends State<ImageRotator> {
  double _rotation = 0;
  int _twist = 0;
  int _startingDegrees = 0;

  /// The photo as it was when the editor opened, already rotated to
  /// [_startingDegrees] by the server and — crucially — already decoded and
  /// sitting in Flutter's image cache, because the viewer was just showing it.
  ///
  /// Captured once: build() rewrites snap.degrees as the user turns the dial,
  /// which would otherwise change fullSizeURL on every frame and fetch afresh.
  late final String _baseImageUrl;

  /// How far the user has turned the photo since opening the editor.
  ///
  /// The preview turns the base image by THIS, not by the new absolute angle:
  /// the base is already at [_startingDegrees], so using the absolute angle
  /// would rotate it twice.
  int get _delta => ((_twist - _rotation.round()) % 360 + 360) % 360;

  /// Matches the server's border trim, so the preview shows what will be
  /// saved rather than a rectangle with blank corners.  See
  /// rotate_with_border_crop in aopservermain.py.
  double get _fillScale {
    final sub = _delta % 90;
    final subangle = (sub > 45 ? 90 - sub : sub).toDouble();
    var proportion = (math.tan(subangle * math.pi / 180) / 2).abs();
    if (proportion > 0.1) proportion = 0.1;
    return 1 + 2 * proportion;
  }

  @override
  void initState() {
    super.initState();
    _startingDegrees = widget.snap.degrees;
    _baseImageUrl = widget.snap.fullSizeURL;
  }

  @override
  Widget build(BuildContext context) {
    widget.snap.degrees =
        ((_startingDegrees + _twist - _rotation.round()) % 360 + 360) % 360;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            MyIconButton(
              Icons.arrow_back,
              onPressed: () async {
                widget.closeRotator();
              },
            ),
            Spacer(),
            MyIconButton(
              Icons.rotate_left,
              onPressed: () async {
                setState(() {
                  _twist += 90;
                });
              },
            ),
            Expanded(
              child: Slider(
                value: _rotation,
                min: -6,
                max: 6,
                divisions: 12,
                label: _rotation.toStringAsFixed(1),
                onChanged: (double value) {
                  setState(() {
                    _rotation = value;
                  });
                },
              ),
            ),
            MyIconButton(
              Icons.rotate_right,
              onPressed: () async {
                setState(() {
                  _twist -= 90;
                });
              },
            ),
            Spacer(),
            MyIconButton(
              Icons.save,
              onPressed: () async {
                widget.snap.degrees =
                    ((_startingDegrees + _twist - _rotation.round()) % 360 +
                            360) %
                        360;
                try {
                  await widget.snap.save();
                  await AopSnap.rotateThumbnail(widget.snap.id!);
                  widget.snap.thumbResetVersion++; // bust the grid's copy too
                } catch (ex) {
                  showMessage(context, '$ex');
                }
                widget.closeRotator(); // save snap
              },
            ),
          ],
        ),
        Expanded(
          // Rotated here rather than on the server: the image is already in
          // memory, so the preview follows the dial instantly with no request
          // per step.  Negated because PIL turns anticlockwise for a positive
          // angle and Flutter turns clockwise.
          child: ClipRect(
            child: Transform.scale(
              scale: _fillScale,
              child: Transform.rotate(
                angle: -_delta * math.pi / 180,
                child: Image.network(_baseImageUrl,
                    fit: BoxFit.contain,
                    headers: {'Preserve': WebFile.preserve}),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
