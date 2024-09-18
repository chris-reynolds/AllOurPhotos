// created by chris r. 18th Sept 2024
// this widget is to gently rotate a photo to allow you to adjust the horizon

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../flutter_common/WidgetSupport.dart';

class ImageRotator extends StatefulWidget {
  final String url;
  final Function(double angle) postAngle;

  const ImageRotator({required this.url, required this.postAngle});

  @override
  State<ImageRotator> createState() => _ImageRotatorState();
}

class _ImageRotatorState extends State<ImageRotator> {
  double _rotation = 0.0;
  double _twist = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Transform.rotate(
            angle: (_rotation + _twist) * math.pi / 180,
            child: Image.network(widget.url, fit: BoxFit.contain),
          ),
        ),
        Row(
          children: [
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
                  _twist -= 90;
                });
              },
            ),
            MyIconButton(
              Icons.save,
              onPressed: () async {
                setState(() {
                  widget.postAngle(_rotation + _twist);
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
