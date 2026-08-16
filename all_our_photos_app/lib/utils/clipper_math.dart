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
  /// Rejects gestures that would move the visible region's top-left corner
  /// beyond its initial position (xOffset, yOffset), which prevents the user
  /// from panning into letterbox area outside the image boundary.
  bool shouldUndo(Rect r, double totalScale) {
    if (totalScale > 16) return true;
    return r.topLeft.dx < xOffset || r.topLeft.dy < yOffset;
  }

  /// Which photo a completed swipe should move to, given how far the finger
  /// travelled: -1 for the previous photo, +1 for the next, 0 for neither.
  ///
  /// Down or right goes back, up or left goes forward.  The axis the finger
  /// travelled furthest along wins, and because both axes map the same way a
  /// single sign test covers all four directions.  Travel shorter than
  /// [threshold] logical pixels is a stray drag and navigates nowhere.
  static int swipeNavigation(Offset travel, {double threshold = 50}) {
    final delta = travel.dx.abs() > travel.dy.abs() ? travel.dx : travel.dy;
    if (delta.abs() < threshold) return 0;
    return delta > 0 ? -1 : 1;
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
