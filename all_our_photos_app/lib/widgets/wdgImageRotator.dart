// created by chris r. 18th Sept 2024
// this widget is to gently rotate a photo to allow you to adjust the horizon

import 'package:aopmodel/aop_classes.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
// import 'dart:math' as math;
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
  bool _resetting = true;

  @override
  void initState() {
    super.initState();
    _startingDegrees = widget.snap.degrees;
    _resetThumbnail();
  }

  Future<void> _resetThumbnail() async {
    try {
      await AopSnap.resetThumbnail(widget.snap.id!);
    } catch (_) {}
    if (mounted) setState(() => _resetting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_resetting) return const Center(child: CircularProgressIndicator());
    widget.snap.degrees = ((_startingDegrees + _twist - _rotation.toInt()) % 360 + 360) % 360;
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
                    ((_startingDegrees + _twist - _rotation.round()) % 360 + 360) % 360;
                try {
                  await widget.snap.save();
                  await AopSnap.rotateThumbnail(widget.snap.id!);
                } catch (ex) {
                  showMessage(context, '$ex');
                }
                widget.closeRotator(); // save snap
              },
            ),
          ],
        ),
        Expanded(
          child: Image.network(widget.snap.rotatedThumbnailURL, fit: BoxFit.contain, headers: {'Preserve': WebFile.preserve}),
        ),
      ],
    );
  }
}
