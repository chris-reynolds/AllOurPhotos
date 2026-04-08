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

  const Clipper({
    super.key,
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.rectCallback,
    required this.canCropCallBack,
    this.show,
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
    _checkLastTransform();
  } // of fingerAdd

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
    _fingerGestureList.reset();
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
    _fingerGestureList.reset();
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
    var currentScale = _fingerGestureList.totalScale();
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
              if (details.pointerCount == 1) {
                _dPrint('onPanningStart: $details');
                //_dPrint('panning ${details.focalPoint} ');
                _fingerAdd(OneFingered(details.focalPoint / currentScale));
              } else {
                _dPrint('onScaleStart: $details');
                _fingerAdd(TwoFingered(1, details.focalPoint));
              }
            },
            onScaleUpdate: (ScaleUpdateDetails details) {
              if (details.pointerCount == 2) {
                // _dPrint('onScaleUpdate: $details');
                _fingerGestureList.updateScale(details.scale);
                setState(() {});
              } // of pinchzoom
              if (details.pointerCount == 1) {
                // _dPrint('onPanningUpdate: $details');
                _fingerGestureList
                    .updateEndPoint(details.focalPoint / currentScale);
                // _dPrint('repaint in pan');
                setState(() {});
              }
            },
            onScaleEnd: (ScaleEndDetails details) {
              _dPrint('onScaleEnd: $details');
              _checkLastTransform();
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
              _fingerAdd(TwoFingered(3, mypoint));
              setState(() {});
            },
            onLongPress: () {
              _fingerGestureList.reset();
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
