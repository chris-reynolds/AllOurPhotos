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
  OneFingered(this.startPoint, {Offset? endPoint}) {
    this.endPoint = (endPoint != null) ? endPoint : Offset.zero;
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
  final Offset focus;
  TwoFingered(this.scale, this.focus);

  @override
  String toString() =>
      '--Scale $scale about ${focus.dx},  ${focus.dy} \n $matrix \n';

  @override
  void calcMatrix() {
    Matrix4 m3 = OneFingered(focus).matrix;
    Matrix4 m2 = Matrix4.identity()..scale(scale);
    Matrix4 m1 = OneFingered(-focus).matrix;
    Matrix4 result = m1.multiplied(m2);
    result = result.multiplied(m3);
    _matrix = result;
  }

  void updateScale(scale) {
    // used to change zoom without new gesture
    this.scale = scale;
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

  Matrix4 totalTransform() {
    var result = TwoFingered(1, Offset.zero).matrix;
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

  void updateScale(double scale) {
    // if (current == null) {
    //   add(TwoFingered(scale, Offset(0, 0)));
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
