// created by chris r. 18th Sept 2024
// this widget is to gently rotate a photo to allow you to adjust the horizon

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../flutter_common/WidgetSupport.dart';

class ImageRotator extends StatefulWidget {
  final String url;
  final Function(int angle) postAngle;

  const ImageRotator({required this.url, required this.postAngle});

  @override
  State<ImageRotator> createState() => _ImageRotatorState();
}

class _ImageRotatorState extends State<ImageRotator> {
  double _rotation = 0;
  int _twist = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            MyIconButton(
              Icons.arrow_back,
              onPressed: () async {
                widget.postAngle(0);
              },
            ),
            MyIconButton(
              Icons.rotate_left,
              onPressed: () async {
                setState(() {
                  _twist -= 90;
                });
              },
            ),
            Expanded(
              child: Slider(
                value: _rotation,
                min: -6,
                max: 6,
                divisions: 6,
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
                  _twist += 90;
                });
              },
            ),
            MyIconButton(
              Icons.save,
              onPressed: () async {
                setState(() {
                  widget.postAngle(_rotation.round() + _twist);
                });
              },
            ),
          ],
        ),
        Expanded(
          child: Transform.rotate(
            angle: (_rotation + _twist) * math.pi / 180,
            child: Image.network(widget.url, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
