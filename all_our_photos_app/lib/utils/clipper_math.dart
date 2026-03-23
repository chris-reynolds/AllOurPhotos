// Pure math for the Clipper widget, extracted for testability.
// Created from wdgClipper.dart — no widget state, no BuildContext required.

import 'package:flutter/material.dart';

class ClipperMath {
  final Size imageSize;
  final Size targetSize;
  late final double initialScale;

  /// Image-coordinate value at the left edge of the screen (can be negative
  /// for portrait images on landscape screens, i.e. letterboxed on the sides).
  late final double xOffset;

  /// Image-coordinate value at the top edge of the screen.
  late final double yOffset;

  ClipperMath({required this.imageSize, required this.targetSize}) {
    initialScale = _minScale(imageSize, targetSize);
    xOffset = (imageSize.width - targetSize.width / initialScale) / 2;
    yOffset = (imageSize.height - targetSize.height / initialScale) / 2;
  }

  static double _minScale(Size original, Size target) {
    final ws = target.width / original.width;
    final hs = target.height / original.height;
    return ws < hs ? ws : hs;
  }

  /// Maps screen corner coordinates back to image pixel coordinates using the
  /// inverse of [transform], producing the rectangle of the image currently
  /// visible on screen.
  Rect calcImageRect(Matrix4 transform) {
    final inv = Matrix4.inverted(transform);
    Offset topLeft =
        MatrixUtils.transformPoint(inv, Offset.zero) / initialScale;
    Offset bottomRight =
        MatrixUtils.transformPoint(
                inv, Offset(targetSize.width, targetSize.height)) /
            initialScale;
    topLeft += Offset(xOffset, yOffset);
    bottomRight += Offset(xOffset, yOffset);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Whether a gesture should be rejected (undone).
  ///
  /// Original bug: compared against xOffset/yOffset rather than 0.
  /// For portrait images on landscape screens xOffset is negative, which caused
  /// any zoom-in to be immediately undone because the top-left corner naturally
  /// extends into the letterbox area.  Using 0 (the image boundary) is correct.
  bool shouldUndo(Rect r, double totalScale) {
    if (totalScale > 16) return true;
    return r.topLeft.dx < 0 || r.topLeft.dy < 0;
  }

  /// Whether the visible region is a croppable sub-region of the image.
  ///
  /// True only when the user has zoomed in or panned away from the full-image
  /// view — i.e. r.topLeft has moved significantly from the initial position
  /// (xOffset, yOffset).  When showing the whole photo, cropping would just
  /// make a straight copy, so we return false in that case.
  bool isCropable(Rect r) {
    return (r.topLeft.dx - xOffset).abs() > 20 ||
        (r.topLeft.dy - yOffset).abs() > 20;
  }
}
