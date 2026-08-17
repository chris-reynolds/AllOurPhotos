// The draggable crop rectangle, kept in IMAGE pixel coordinates.
//
// Holding the selection in image coordinates (rather than screen ones) is what
// lets it survive zooming: you can zoom hard into one corner to place an edge
// exactly, zoom out, pan to the far corner and place that one, and the
// selection stays put on the same pixels throughout.
//
// Pure logic, no widgets — see crop_rect_test.dart.

import 'package:flutter/material.dart';

/// What a drag started on, and therefore what it changes.
enum CropGrip {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,

  /// Inside the rectangle: the whole selection moves.
  move,

  /// Outside it: the drag pans the view instead of touching the selection.
  none,
}

class CropRectModel {
  /// The selection, in image pixels.
  Rect rect;

  CropRectModel(this.rect);

  /// Which grip a touch at [imagePoint] lands on.
  ///
  /// [grabRadius] is in image pixels — the caller converts a finger-sized
  /// screen distance into image pixels, so the target stays the same physical
  /// size however far the view is zoomed in.
  CropGrip gripAt(Offset imagePoint, double grabRadius) {
    final corners = <CropGrip, Offset>{
      CropGrip.topLeft: rect.topLeft,
      CropGrip.topRight: rect.topRight,
      CropGrip.bottomLeft: rect.bottomLeft,
      CropGrip.bottomRight: rect.bottomRight,
    };
    CropGrip best = CropGrip.none;
    double bestDistance = grabRadius;
    for (final entry in corners.entries) {
      final d = (imagePoint - entry.value).distance;
      if (d <= bestDistance) {
        bestDistance = d;
        best = entry.key;
      }
    }
    if (best != CropGrip.none) return best;
    return rect.contains(imagePoint) ? CropGrip.move : CropGrip.none;
  }

  /// Applies a drag of [delta] image pixels to [grip], against the rectangle
  /// as it stood when the drag began ([start]).
  ///
  /// Corners may be dragged past one another; the rectangle is normalised so
  /// it never inverts, which would otherwise produce a negative-size crop.
  Rect dragged(CropGrip grip, Rect start, Offset delta) {
    switch (grip) {
      case CropGrip.topLeft:
        return _normalise(
            Rect.fromPoints(start.topLeft + delta, start.bottomRight));
      case CropGrip.topRight:
        return _normalise(
            Rect.fromPoints(start.topRight + delta, start.bottomLeft));
      case CropGrip.bottomLeft:
        return _normalise(
            Rect.fromPoints(start.bottomLeft + delta, start.topRight));
      case CropGrip.bottomRight:
        return _normalise(
            Rect.fromPoints(start.bottomRight + delta, start.topLeft));
      case CropGrip.move:
        return start.shift(delta);
      case CropGrip.none:
        return start;
    }
  }

  static Rect _normalise(Rect r) => Rect.fromLTRB(
        r.left < r.right ? r.left : r.right,
        r.top < r.bottom ? r.top : r.bottom,
        r.left < r.right ? r.right : r.left,
        r.top < r.bottom ? r.bottom : r.top,
      );

  /// Whether the selection is worth cropping to — i.e. meaningfully smaller
  /// than the whole image.  Cropping to the full frame would just copy it.
  static bool isWorthCropping(Rect selection, Rect fullImage) {
    const slack = 8.0; // image pixels
    return selection.left > fullImage.left + slack ||
        selection.top > fullImage.top + slack ||
        selection.right < fullImage.right - slack ||
        selection.bottom < fullImage.bottom - slack;
  }
}
