// created by chris r. 18th Sept 2024
// this widget is to gently rotate a photo to allow you to adjust the horizon

import 'package:aopmodel/aop_classes.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    _startingDegrees = widget.snap.degrees;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.snap.degrees = _startingDegrees + _twist - _rotation.toInt();
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
                    _startingDegrees + (-_rotation.round() + _twist);
                try {
                  await widget.snap.save();
                } catch (ex) {
                  showMessage(context, '$ex');
                }
                widget.closeRotator(); // save snap
              },
            ),
          ],
        ),
        Expanded(
          child: Image.network(widget.snap.thumbnailURL, fit: BoxFit.contain),
        ),
      ],
    );
  }
}
