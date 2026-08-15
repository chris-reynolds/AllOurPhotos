// Created by chris R. 19th June 2024
// Trying to encapsulate the cropping mathemetics
// oneFingered used for panning and TwoFingered used for zooming

import 'package:flutter/material.dart';

class Fingered {
  Matrix4? _matrix;

  void calcMatrix() {}

  Matrix4 get matrix {
    if (_matrix == null) calcMatrix();
    return _matrix!;
  }

  bool get isValid => true;

  Offset reverse(Offset point) =>
      MatrixUtils.transformPoint(Matrix4.inverted(matrix), point);

  @override
  String toString() => 'Not implemented';

  Offset transform(Offset point) => MatrixUtils.transformPoint(matrix, point);
} // of Fingered

class OneFingered extends Fingered {
  Offset startPoint;
  Offset endPoint = Offset.zero;

  /// A pan from [startPoint] to [endPoint].  When [endPoint] is omitted the
  /// gesture starts as the identity (no movement yet) — it must NOT default to
  /// the origin, or simply touching the screen would jump the image by the
  /// touch position before the finger has moved at all.
  OneFingered(this.startPoint, {Offset? endPoint}) {
    this.endPoint = endPoint ?? startPoint;
  }
  double get dx => endPoint.dx - startPoint.dx;
  double get dy => endPoint.dy - startPoint.dy;

  @override
  String toString() => '--Pan $dx,  $dy';

  @override
  void calcMatrix() {
    _matrix = Matrix4.identity();
    _matrix!.setEntry(0, 3, dx);
    _matrix!.setEntry(1, 3, dy);
  }

  void updateEndPoint(Offset endPoint) {
    // used to change pan without new gesture
    this.endPoint = endPoint;
    calcMatrix();
  }
} // of OneFingered

class TwoFingered extends Fingered {
  double scale;

  /// The point the zoom pivots about, expressed in the coordinate space this
  /// gesture operates in (see [FingerGestureList.totalTransform]).
  final Offset focus;

  /// How far the pinch centre has drifted from [focus] since the gesture
  /// started, so the image follows the fingers while they are still down.
  Offset pan = Offset.zero;

  TwoFingered(this.scale, this.focus);

  @override
  String toString() =>
      '--Scale $scale about ${focus.dx},  ${focus.dy} pan $pan \n $matrix \n';

  @override
  void calcMatrix() {
    // Scale about [focus], then translate by the focal drift [pan]:
    //   T(focus + pan) . S(scale) . T(-focus)
    // These post-multiply, so this reads left to right.
    _matrix = Matrix4.identity()
      ..translateByDouble(focus.dx + pan.dx, focus.dy + pan.dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1);
  }

  void updateScale(double scale) {
    // used to change zoom without new gesture
    if (!scale.isFinite || scale <= 0) return; // e.g. span collapses to zero
    this.scale = scale;
    calcMatrix();
  }

  /// Moves the pinch centre to [current] (same coordinate space as [focus])
  /// without disturbing the zoom factor.
  void updateFocus(Offset current) {
    pan = current - focus;
    calcMatrix();
  }
} // of TwoFingered

class FingerGestureList {
  var _list = <Fingered>[];
  ValueSetter<String>? logger;
  FingerGestureList();

  void add(Fingered f) {
    _list.add(f);
    showStatus();
  }

  Fingered? get current => (_list.isNotEmpty) ? _list.last : null;

  void removeLast() {
    _list.removeLast();
    showStatus();
  }

  void reset() => _list = <Fingered>[];

  Offset scaledOffset(Offset o) {
    double scale = totalScale();
    return Offset(o.dx / scale, o.dy / scale);
  }

  void showStatus() {
    if (logger != null) {
      logger!('$this');
    }
  }

  @override
  String toString() {
    var result = '****************\n';
    for (var item in _list) {
      result += '$item \n';
    }
    result += '******************\n';
    return result;
  }

  double totalScale() {
    var result = 1.0;
    for (var item in _list) {
      result = result * item.matrix.entry(0, 0);
    }
    if (result == 0) throw Exception('zero scale');
    return result;
  } // of totalScale

  /// The combined transform, composed as `M1 . M2 . ... . Mn`.
  ///
  /// Each gesture is appended on the RIGHT, so the newest one is applied
  /// FIRST — it operates in the untransformed child (image) space, not in
  /// screen space.  Callers must therefore convert a screen-space focal point
  /// into child space (via the inverse of the transform as it stood when the
  /// gesture began) before handing it to [OneFingered] or [TwoFingered].
  Matrix4 totalTransform() {
    var result = Matrix4.identity();
    for (var item in _list) {
      result = result.multiplied(item.matrix);
    }
    return result;
  } // of totalTransform

  void updateEndPoint(Offset p) {
    if (current is OneFingered) {
      (current as OneFingered).updateEndPoint(p);
      // showStatus();
    } else {
      throw Exception('Current gesture is not one fingered');
    }
  } // of updateEndPoint

  void updateFocus(Offset p) {
    if (current is TwoFingered) {
      (current as TwoFingered).updateFocus(p);
    } else {
      throw Exception('Current gesture is not two fingered');
    }
  } // of updateFocus

  void updateScale(double scale) {
    if (current is TwoFingered) {
      (current as TwoFingered).updateScale(scale);
      //  showStatus();
    } else {
      throw Exception('Current gesture is not two fingered');
    }
  } // of updateScale

  void validate() {
    if (current is Fingered && !current!.isValid) {
      _list.removeLast();
      showStatus();
    }
  } // validate
} // of class FingerGestureList
