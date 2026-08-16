// attempt to build a clipping widget
// created by chris R. 21st June 2024

import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../utils/fingers.dart';
import '../utils/clipper_math.dart';
import 'package:provider/provider.dart';

class Clipper extends StatefulWidget {
  final String imageUrl;
  final int imageWidth;
  final int imageHeight;
  final ValueSetter<bool> canCropCallBack;
  final ValueSetter<Rect> rectCallback;
  final ValueSetter<Map<String, String>>? show;

  /// Called with -1 for previous or +1 for next when the user swipes while the
  /// whole photo is showing.  Swipe navigation is only enabled when this is
  /// supplied; without it a one-finger drag always pans, as it always has.
  final ValueSetter<int>? navigateCallBack;

  const Clipper({
    super.key,
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.rectCallback,
    required this.canCropCallBack,
    this.show,
    this.navigateCallBack,
  });

  @override
  State<Clipper> createState() => _ClipperState();
}

class _ClipperState extends State<Clipper> {
  RenderBox? _clipperRb;
  final _fingerGestureList = FingerGestureList();
  Size? _imageSize;
  ClipperMath? _math;
  Matrix4 _currentTransform = Matrix4.identity();
  Offset? _tapPosition;
  Size? _targetSize;

  /// Inverse of the accumulated transform as it stood when the current gesture
  /// began.  Gestures are composed in child (image) space, so every screen
  /// focal point has to be pushed back through this before use — otherwise the
  /// zoom pivots about the wrong place, increasingly so the more you zoom and
  /// pan.  Snapshotted at gesture start so it stays fixed while the gesture is
  /// in flight.
  Matrix4 _gestureBaseInverse = Matrix4.identity();

  /// Where a navigation swipe began, or null when the current one-finger drag
  /// is a crop pan rather than a swipe.  Non-null means no gesture was pushed
  /// onto [_fingerGestureList] — the image deliberately stays put while the
  /// finger moves, so a swipe cannot disturb a crop.
  Offset? _swipeStart;
  Offset? _swipeLast;

  /// How far a finger must travel before it counts as a swipe rather than a
  /// stray drag, in logical pixels.
  static const double _swipeThreshold = 50;

  bool get _isFullImageShowing =>
      !_math!.isCropable(_math!.calcImageRect(_fingerGestureList.totalTransform()));

  /// Back to the untouched full-image view, with no gesture in flight.
  void _resetGestures() {
    _fingerGestureList.reset();
    _gestureBaseInverse = Matrix4.identity();
    _swipeStart = null;
    _swipeLast = null;
  }

  void _calcInitialScale() {
    if (_imageSize == null) return;
    _clipperRb = context.findRenderObject() as RenderBox;
    _targetSize = _clipperRb!.size;
    _math ??= ClipperMath(imageSize: _imageSize!, targetSize: _targetSize!);
    context.read<MapProvider?>()?.addAll({
      'target size': '$_targetSize',
      'initial scale': _math!.initialScale.toStringAsFixed(3),
      'init offset':
          '${_math!.xOffset.toInt()},${_math!.yOffset.toInt()}',
    });
  }

  Rect _calcImageRect() {
    _currentTransform = _fingerGestureList.totalTransform();
    final r = _math!.calcImageRect(_currentTransform);
    _dPrint('calcImageRect topleft=${r.topLeft} bottomRight=${r.bottomRight}');
    return r;
  }

  void _checkLastTransform() {
    var r = _calcImageRect();
    if (_math!.shouldUndo(r, _fingerGestureList.totalScale())) {
      _fingerGestureList.removeLast();
      _dPrint('undo ${_fingerGestureList.current}');
      r = _calcImageRect();
    }
    setImageRect(r);
    setState(() {});
  }

  void _dPrint(String s) {
    // print('dprint: $s');
    context.read<MapProvider?>()?.log(s);
  } // of dPrint

  void _fingerAdd(Fingered f) {
    _fingerGestureList.add(f);
    setImageRect(_calcImageRect());
    setState(() {});
  } // of fingerAdd

  /// Converts a point in the gesture detector's local (screen) coordinates
  /// into the child coordinate space that gestures are composed in.
  Offset _toChild(Offset localPoint) =>
      MatrixUtils.transformPoint(_gestureBaseInverse, localPoint);

  void _snapshotGestureBase() {
    _gestureBaseInverse =
        Matrix4.inverted(_fingerGestureList.totalTransform());
  }

  /// Resolves a finished swipe. See [ClipperMath.swipeNavigation].
  void _endSwipe() {
    final start = _swipeStart;
    final last = _swipeLast;
    _swipeStart = null;
    _swipeLast = null;
    if (start == null || last == null) return;
    final travel = last - start;
    final delta =
        ClipperMath.swipeNavigation(travel, threshold: _swipeThreshold);
    _dPrint('swipe $travel -> $delta');
    if (delta != 0) widget.navigateCallBack!(delta);
  } // of endSwipe

  /// The scale recogniser can report a different pointer count than the one the
  /// gesture was started with — a finger lands a frame late, or lifts early.
  /// Swap the in-flight gesture for the right kind instead of throwing.
  void _switchToTwoFingered(Offset localFocalPoint) {
    if (_swipeStart != null) {
      // A second finger landed mid-swipe: it's a zoom after all.  Nothing was
      // added to the list, so the base is simply the transform as it stands.
      _swipeStart = null;
      _swipeLast = null;
      _snapshotGestureBase();
    } else if (_fingerGestureList.current is OneFingered) {
      // Drop the incidental pan from before the second finger landed; the
      // total transform is then back to what _gestureBaseInverse describes.
      _fingerGestureList.removeLast();
    } else {
      _snapshotGestureBase();
    }
    _fingerAdd(TwoFingered(1, _toChild(localFocalPoint)));
  }

  void _switchToOneFingered(Offset localFocalPoint) {
    // A finger lifted mid-pinch: keep the zoom achieved so far and start
    // panning from the transform as it now stands.
    _snapshotGestureBase();
    final start = _toChild(localFocalPoint);
    _fingerAdd(OneFingered(start, endPoint: start));
  }

  void setImageRect(Rect r) {
    final imRect =
        Rect.fromLTRB(0, 0, _imageSize!.width, _imageSize!.height);
    widget.rectCallback(imRect.intersect(r));
    widget.canCropCallBack(_math!.isCropable(r));
  }

/////////////////////////////
  ///    Widget lifecycle ///
/////////////////////////////
  ///
  @override
  void initState() {
    super.initState();
    _fingerGestureList.logger = _dPrint; // for debugging
    _imageSize = Size(widget.imageWidth.toDouble(), widget.imageHeight.toDouble());
  }

  @override
  void didChangeDependencies() {
    _dPrint('didChangeDependencies');
    super.didChangeDependencies();
    _resetGestures();
    _math = null; // force a recalc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dPrint('exec postframecallback');
      if (_math == null) {
        _calcInitialScale();
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant Clipper oldWidget) {
    _dPrint('didupdatewidget');
    super.didUpdateWidget(oldWidget);
    _resetGestures();
    _math = null;
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageSize =
          Size(widget.imageWidth.toDouble(), widget.imageHeight.toDouble());
    }
    _calcInitialScale();
  }

  @override
  Widget build(BuildContext context) {
    // _dPrint('build()');
    if (_math == null) return const Center(child: CircularProgressIndicator());
    return LayoutBuilder(builder: (context, boxConstraints) {
      return Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
            border: Border.all(
          color: Colors.red,
          width: 1,
        )),
        child: ClipRect(
          child: GestureDetector(
            onScaleStart: (ScaleStartDetails details) {
              _snapshotGestureBase();
              final focus = _toChild(details.localFocalPoint);
              if (details.pointerCount < 2) {
                if (widget.navigateCallBack != null && _isFullImageShowing) {
                  // Nothing is zoomed, so a one-finger drag navigates rather
                  // than pans.  No gesture is added — the image holds still.
                  _dPrint('onSwipeStart: $details');
                  _swipeStart = details.localFocalPoint;
                  _swipeLast = _swipeStart;
                  return;
                }
                _dPrint('onPanningStart: $details');
                _fingerAdd(OneFingered(focus, endPoint: focus));
              } else {
                _dPrint('onScaleStart: $details');
                _fingerAdd(TwoFingered(1, focus));
              }
            },
            onScaleUpdate: (ScaleUpdateDetails details) {
              if (details.pointerCount >= 2) {
                // _dPrint('onScaleUpdate: $details');
                // A swipe must switch even when the last gesture happens to be
                // a TwoFingered, or updateScale would mutate that finished one.
                if (_swipeStart != null ||
                    _fingerGestureList.current is! TwoFingered) {
                  _switchToTwoFingered(details.localFocalPoint);
                }
                // _toChild only after any switch — that re-snapshots the base.
                _fingerGestureList.updateScale(details.scale);
                _fingerGestureList
                    .updateFocus(_toChild(details.localFocalPoint));
                setState(() {});
              } else if (_swipeStart != null) {
                // Swiping: just remember where the finger got to. onScaleEnd
                // carries no position, so it cannot work this out for itself.
                _swipeLast = details.localFocalPoint;
              } else {
                // _dPrint('onPanningUpdate: $details');
                if (_fingerGestureList.current is! OneFingered) {
                  _switchToOneFingered(details.localFocalPoint);
                } else {
                  _fingerGestureList
                      .updateEndPoint(_toChild(details.localFocalPoint));
                }
                // _dPrint('repaint in pan');
                setState(() {});
              }
            },
            onScaleEnd: (ScaleEndDetails details) {
              _dPrint('onScaleEnd: $details');
              if (_swipeStart != null) {
                _endSwipe(); // nothing was transformed, so nothing to validate
              } else {
                _checkLastTransform();
              }
            },
            onTapDown: (details) {
              _dPrint(
                  'tap at ${details.localPosition} global=${details.globalPosition}');
            },
            onDoubleTapDown: (details) {
              _tapPosition = details.localPosition;
            },
            onDoubleTap: () {
              var mypoint = _tapPosition!;
              _dPrint('doubletap lp=$mypoint');
              _snapshotGestureBase();
              _fingerAdd(TwoFingered(3, _toChild(mypoint)));
              _checkLastTransform();
            },
            onLongPress: () {
              _resetGestures();
              setState(() {});
            },
            child: Transform(
              transform: _fingerGestureList.totalTransform(),
              child: Image.network(
                widget.imageUrl,
                width: boxConstraints.maxWidth,
                height: boxConstraints.maxHeight,
                fit: BoxFit.contain,
                headers: {'Preserve': WebFile.preserve},
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  } // of build
} // of class _ClipperState

class CropableProvider extends ValueNotifier<bool> {
  CropableProvider(super.value);
}

class MapProvider with ChangeNotifier {
  Map<String, String> _value = {};
  void addAll(Map<String, String> extras) {
    _value.addAll(extras);
    // notifyListeners();
  }

  void log(String message) {
    List<String> priorLines =
        _value['zmessage'] == null ? [] : _value['zmessage']!.split('\n');
    if (priorLines.length > 4) {
      priorLines = priorLines.sublist(priorLines.length - 4);
    }
    _value['zmessage'] = '${priorLines.join('\n')}\n$message';
  }

  void clear() => _value = {};
  @override
  String toString() {
    return 'aa\n$_value';
  }

  Map<String, String> get value => _value;
}

class MapViewer extends StatelessWidget {
  final TextStyle? style;
  const MapViewer({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    var mapProvider = context.watch<MapProvider?>();

    if (mapProvider == null) return Container();
    Map<String, String> values = mapProvider.value;
    var sortedValues = Map.fromEntries(
        values.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedValues.entries.map((item) {
        return Text('${item.key} = ${item.value}', style: style);
      }).toList(),
    );
  }
}
