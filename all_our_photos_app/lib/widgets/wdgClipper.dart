// attempt to build a clipping widget
// created by chris R. 21st June 2024

import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../utils/fingers.dart';
import '../utils/clipper_math.dart';
import '../utils/crop_rect.dart';
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

  /// A low-resolution stand-in (normally the thumbnail) painted behind the
  /// full-size photo while that loads, so changing photo is not a blank wait.
  final String? placeholderUrl;

  /// In crop mode a draggable rectangle selects the region, pinch zooms the
  /// view without changing the selection, and swipe navigation is suspended
  /// so no gesture is ambiguous.
  ///
  /// Out of crop mode the widget behaves exactly as it always has.
  final bool cropMode;

  const Clipper({
    super.key,
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.rectCallback,
    required this.canCropCallBack,
    this.show,
    this.navigateCallBack,
    this.placeholderUrl,
    this.cropMode = false,
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

  bool get _isFullImageShowing => !_math!
      .isCropable(_math!.calcImageRect(_fingerGestureList.totalTransform()));

  // ---- crop mode ----------------------------------------------------------

  /// The selection, in IMAGE pixels, so it stays on the same pixels however
  /// the view is zoomed or panned.  Null when not cropping.
  Rect? _cropImageRect;
  CropGrip _grip = CropGrip.none;
  Rect? _dragStartRect;
  Offset? _dragStartImage;

  /// Where the finger actually touched down, before the recogniser's slop.
  Offset? _pointerDownLocal;

  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  /// Measures the photo actually being displayed, rather than trusting the
  /// width/height recorded in the database.
  ///
  /// Those two disagree whenever a file has been replaced by a resized copy —
  /// the dev photo store holds 640x480 stand-ins for full-size originals — and
  /// a crop rectangle sized from stale metadata selects a region that does not
  /// exist in the file.  The server pads out of bounds with black, so the crop
  /// silently comes back blank.  Measuring the real thing keeps the selection
  /// in the same coordinates the file is in.
  void _listenForActualSize() {
    _stopListeningForSize();
    final provider =
        NetworkImage(widget.imageUrl, headers: {'Preserve': WebFile.preserve});
    _imageStream = provider.resolve(createLocalImageConfiguration(context));
    _imageListener = ImageStreamListener((info, _) {
      final actual =
          Size(info.image.width.toDouble(), info.image.height.toDouble());
      info.dispose();
      if (!mounted || actual.isEmpty || actual == _imageSize) return;
      _dPrint('actual image $actual, database said $_imageSize');
      setState(() {
        _imageSize = actual;
        _math = null; // scale and offsets depend on the image size
        _cropImageRect = null;
      });
      _calcInitialScale();
    }, onError: (_, __) {
      /* the image just will not load; nothing to measure */
    });
    _imageStream!.addListener(_imageListener!);
  }

  void _stopListeningForSize() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  /// How near a corner a finger must land to grab it, in logical pixels.
  static const double _grabScreenRadius = 28;

  bool get _cropping => widget.cropMode && _cropImageRect != null;

  /// The grab radius converted to image pixels, so the target stays the same
  /// physical size on screen however far the view is zoomed.
  double get _grabImageRadius =>
      _grabScreenRadius /
      (_math!.initialScale * _fingerGestureList.totalScale());

  Offset _toImage(Offset localPoint) =>
      _math!.screenToImage(localPoint, _fingerGestureList.totalTransform());

  void _beginCropDrag(Offset localPoint) {
    final model = CropRectModel(_cropImageRect!);
    final imagePoint = _toImage(localPoint);
    _grip = model.gripAt(imagePoint, _grabImageRadius);
    _dragStartRect = _cropImageRect;
    _dragStartImage = imagePoint;
    _dPrint('crop grip $_grip at $imagePoint');
  }

  void _updateCropDrag(Offset localPoint) {
    if (_grip == CropGrip.none || _dragStartRect == null) return;
    final delta = _toImage(localPoint) - _dragStartImage!;
    final moved =
        CropRectModel(_cropImageRect!).dragged(_grip, _dragStartRect!, delta);
    setState(() => _cropImageRect = _math!.clampCrop(moved));
    _publish();
  }

  /// How far inside the visible area the starting selection sits, in logical
  /// pixels.  Flush against the edge the corner grips are half off-screen and
  /// cannot be grabbed — the bottom ones especially, where the window edge is.
  static const double _initialInset = 44;

  /// Starts the selection from whatever is currently on screen, inset far
  /// enough that every corner can be grabbed.
  void _initCropRect() {
    if (_math == null) return;
    final visible = _math!.calcImageRect(_fingerGestureList.totalTransform());
    final start = _math!.fullImageRect.intersect(visible);
    // The inset is a screen distance, so convert it into image pixels at the
    // current zoom — the grips then sit the same distance in whatever the
    // view is doing.
    final inset = _initialInset /
        (_math!.initialScale * _fingerGestureList.totalScale());
    final insetRect = start.deflate(inset);
    _cropImageRect =
        _math!.clampCrop(insetRect.isEmpty ? start.deflate(1) : insetRect);
    _publish();
  }

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
    // Tell the parent where we now stand.  Without this the reset done by
    // didUpdateWidget/didChangeDependencies is invisible to it, so after
    // swiping to another photo it would still hold the PREVIOUS photo's rect
    // and a stale canCrop=true — and crop the wrong region.
    //
    // Crop mode is seeded here as well as on the false->true transition, so a
    // Clipper built already in crop mode still gets a selection.
    if (widget.cropMode && _cropImageRect == null) {
      _initCropRect();
    } else {
      setImageRect(_calcImageRect());
    }
    context.read<MapProvider?>()?.addAll({
      'target size': '$_targetSize',
      'initial scale': _math!.initialScale.toStringAsFixed(3),
      'init offset': '${_math!.xOffset.toInt()},${_math!.yOffset.toInt()}',
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
    _gestureBaseInverse = Matrix4.inverted(_fingerGestureList.totalTransform());
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
    // In crop mode the selection is what Crop would use, not the visible
    // region, so the view can be zoomed about freely without touching it.
    if (_cropping) {
      _publish();
      return;
    }
    final imRect = Rect.fromLTRB(0, 0, _imageSize!.width, _imageSize!.height);
    widget.rectCallback(imRect.intersect(r));
    widget.canCropCallBack(_math!.isCropable(r));
  }

  /// Tells the parent which rectangle Crop would apply, and whether applying
  /// it would achieve anything.
  void _publish() {
    if (_cropping) {
      widget.rectCallback(_cropImageRect!);
      widget.canCropCallBack(
          CropRectModel.isWorthCropping(_cropImageRect!, _math!.fullImageRect));
    } else {
      setImageRect(_calcImageRect());
    }
  }

/////////////////////////////
  ///    Widget lifecycle ///
/////////////////////////////
  ///
  @override
  void initState() {
    super.initState();
    _fingerGestureList.logger = _dPrint; // for debugging
    _imageSize =
        Size(widget.imageWidth.toDouble(), widget.imageHeight.toDouble());
  }

  @override
  void didChangeDependencies() {
    _dPrint('didChangeDependencies');
    super.didChangeDependencies();
    _resetGestures();
    _math = null; // force a recalc
    _listenForActualSize();
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
    // Only start over when the photo itself changes.  This used to reset on
    // EVERY parent rebuild, which would now throw away the zoom the user had
    // set up mid-crop each time the toolbar rebuilt.
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageWidth != widget.imageWidth ||
        oldWidget.imageHeight != widget.imageHeight) {
      _resetGestures();
      _cropImageRect = null;
      _math = null;
      _imageSize =
          Size(widget.imageWidth.toDouble(), widget.imageHeight.toDouble());
      _calcInitialScale();
      _listenForActualSize(); // the new photo may not match its metadata either
    }
    if (widget.cropMode && !oldWidget.cropMode) {
      _initCropRect(); // entering crop mode: select what is on screen
    } else if (!widget.cropMode && oldWidget.cropMode) {
      // Leaving crop mode must NOT republish.  Apply flips the mode off and
      // then crops, so republishing the visible region here overwrites the
      // parent's selection and crops the viewport instead — which is exactly
      // the "tiny bit of the picture, unrelated to the crop area" bug.
      // The parent keeps the selection until something else replaces it.
      _cropImageRect = null;
      _grip = CropGrip.none;
      _dragStartRect = null;
      _dragStartImage = null;
    }
  }

  @override
  void dispose() {
    _stopListeningForSize();
    super.dispose();
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
          // The scale recogniser only reports a drag once it has travelled the
          // touch slop (~18px), by which time the finger has left the corner it
          // grabbed.  Recording the raw pointer-down gives an exact grip test
          // and a delta measured from where the finger actually landed, so the
          // rectangle tracks it with no dead zone.
          child: Listener(
            onPointerDown: (event) => _pointerDownLocal = event.localPosition,
            child: GestureDetector(
              // The child is a RawImage, which does not absorb hits, so with the
              // default deferToChild only whatever happens to paint under the
              // finger would catch a gesture — and nothing at all while the image
              // is still loading.  Claim the whole box instead.
              behavior: HitTestBehavior.opaque,
              onScaleStart: (ScaleStartDetails details) {
                _snapshotGestureBase();
                final focus = _toChild(details.localFocalPoint);
                if (details.pointerCount < 2) {
                  if (_cropping) {
                    // Crop mode: the drag serves the rectangle.  If it grabbed
                    // nothing it falls through to panning the view below.
                    _beginCropDrag(
                        _pointerDownLocal ?? details.localFocalPoint);
                    if (_grip != CropGrip.none) return;
                  } else if (widget.navigateCallBack != null &&
                      _isFullImageShowing) {
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
                if (_grip != CropGrip.none) {
                  // A rectangle drag is in flight. A second finger landing does
                  // not turn it into a zoom - that would fight the drag.
                  if (details.pointerCount < 2) {
                    _updateCropDrag(details.localFocalPoint);
                  }
                  return;
                }
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
                if (_grip != CropGrip.none) {
                  _grip = CropGrip.none;
                  _dragStartRect = null;
                  _dragStartImage = null;
                  _publish();
                } else if (_swipeStart != null) {
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform(
                    transform: _fingerGestureList.totalTransform(),
                    child: SizedBox(
                      width: boxConstraints.maxWidth,
                      height: boxConstraints.maxHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // A full-size photo can take seconds to arrive.  The
                          // thumbnail is small and usually already cached from the
                          // grid, so painting it underneath gives something to look
                          // at immediately; the full image lands on top when ready.
                          if (widget.placeholderUrl != null)
                            Image.network(
                              widget.placeholderUrl!,
                              fit: BoxFit.contain,
                              headers: {'Preserve': WebFile.preserve},
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            headers: {'Preserve': WebFile.preserve},
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              // Keep the child in the tree so the thumbnail below
                              // stays visible, and lay the spinner over the top
                              // rather than replacing everything with it.
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  child,
                                  Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The selection is held in image pixels, so it is converted
                  // through the LIVE transform each frame - that is what keeps
                  // it on the same pixels while the view zooms and pans.
                  if (_cropping)
                    CustomPaint(
                      painter: _CropPainter(_math!.imageRectToScreen(
                          _cropImageRect!,
                          _fingerGestureList.totalTransform())),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  } // of build
} // of class _ClipperState

/// Draws the crop selection: everything outside it dimmed, a bright border,
/// corner grips and thirds guides.  Works entirely in screen coordinates —
/// the caller converts the image-space selection through the live transform.
class _CropPainter extends CustomPainter {
  final Rect screenRect;
  _CropPainter(this.screenRect);

  static const double gripLength = 22;
  static const double gripThickness = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    // Dim everything outside the selection.
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(full),
          Path()..addRect(screenRect)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    // Thirds guides, the usual composition aid.
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = screenRect.left + screenRect.width * i / 3;
      final dy = screenRect.top + screenRect.height * i / 3;
      canvas.drawLine(
          Offset(dx, screenRect.top), Offset(dx, screenRect.bottom), guide);
      canvas.drawLine(
          Offset(screenRect.left, dy), Offset(screenRect.right, dy), guide);
    }
    canvas.drawRect(
        screenRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white);
    // Corner grips, drawn as an L inside each corner so they do not obscure
    // the edge the user is trying to line up.
    final grip = Paint()
      ..color = Colors.white
      ..strokeWidth = gripThickness
      ..strokeCap = StrokeCap.square;
    void corner(Offset c, double sx, double sy) {
      canvas.drawLine(c, c + Offset(gripLength * sx, 0), grip);
      canvas.drawLine(c, c + Offset(0, gripLength * sy), grip);
    }

    corner(screenRect.topLeft, 1, 1);
    corner(screenRect.topRight, -1, 1);
    corner(screenRect.bottomLeft, 1, -1);
    corner(screenRect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.screenRect != screenRect;
}

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
