// attempt to build a clipping widget
// created by chris R. 21st June 2024

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/fingers.dart';
import 'package:provider/provider.dart';

class Clipper extends StatefulWidget {
  final String imageUrl;
  final ValueSetter<bool> canCropCallBack;
  final ValueSetter<Rect> rectCallback;
  final ValueSetter<Map<String, String>>? show;

  const Clipper({
    super.key,
    required this.imageUrl,
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
  Uint8List? imageBytes;
  Size? _imageSize;
  double? _initialScale;
  Matrix4 _currentTransform = Matrix4.identity();
  Offset? _tapPosition;
  Size? _targetSize;
  double _xOffset = 0, _yOffset = 0;

  void _calcInitialScale() {
    if (_imageSize == null) {
      //  _dPrint('calcInitialScale too early');
      return;
    }
    _clipperRb = context.findRenderObject() as RenderBox;
    _targetSize = _clipperRb!.size;
    _initialScale ??= _minScale(_imageSize!, _targetSize!);
    _xOffset = (_imageSize!.width - _targetSize!.width / _initialScale!) / 2;
    _yOffset = (_imageSize!.height - _targetSize!.height / _initialScale!) / 2;
    Map<String, String> status = {
      'target size': '$_targetSize',
      'initial scale': _initialScale!.toStringAsFixed(3),
      'init offset': '${_xOffset.toInt()},${_yOffset.toInt()}',
    };
    context.read<MapProvider?>()?.addAll(status);
  }

  Rect _calcImageRect() {
    _currentTransform = _fingerGestureList.totalTransform();
    var imx = Matrix4.inverted(_currentTransform);
    Offset newOrigin =
        MatrixUtils.transformPoint(imx, Offset.zero) / _initialScale!;
    Offset newBottomRight =
        MatrixUtils.transformPoint(imx, _sizeToOffset(_targetSize!)) /
            _initialScale!;
    newOrigin += Offset(_xOffset, _yOffset);
    newBottomRight += Offset(_xOffset, _yOffset);
    _dPrint('calcImageRect topleft=$newOrigin bottomRight=$newBottomRight');
    return Rect.fromPoints(newOrigin, newBottomRight);
  } // of calcImageRect

  void _checkLastTransform() {
    var r = _calcImageRect();
    bool undo = false;
    undo = undo || (r.topLeft.dx < _xOffset || r.topLeft.dy < _yOffset);
    //  undo = undo || (r.bottomRight.dx > _imageSize!.width);
    //  undo = undo || (r.bottomRight.dy > _imageSize!.height);
    undo = undo || (_fingerGestureList.totalScale() > 16);
    if (undo) {
      _fingerGestureList.removeLast();
      _dPrint('undo ${_fingerGestureList.current}');
      r = _calcImageRect(); // recalc after undo
    }
    setImageRect(r);
    setState(() {});
  } // of checkLastTransform

  void _dPrint(String s) {
    // print('dprint: $s');
    context.read<MapProvider?>()?.log(s);
  } // of dPrint

  void _dPrintValue(String k, v) {
    context.read<MapProvider?>()?.value[k] = v;
  } // of dPrintValue

  void _dPrintError(String exceptionMessage) {
    _dPrintValue('__ERROR__', exceptionMessage);
  }

  void _fingerAdd(Fingered f) {
    _fingerGestureList.add(f);
    setImageRect(_calcImageRect());
    _checkLastTransform();
  } // of fingerAdd

  void _loadMemoryImage(String imageUrl) {
    http.get(Uri.parse(imageUrl)).then((response) {
      imageBytes = response.bodyBytes;
      decodeImageFromList(imageBytes!).then((yy) {
        _imageSize = Size(yy.width * 1.0, yy.height * 1.0);
        _dPrintValue('loaded image size', '$_imageSize');
        _calcInitialScale();
        setState(() {});
      });
    }).onError((ex, StackTrace st) {
      _dPrintError('_loadMemoryImage: $ex for url $imageUrl');
      throw Exception('_loadMemoryImage: $ex for url $imageUrl');
    });
  } // of loadMemoryImage

  double _min(a, b) => a > b ? b : a;

  double _minScale(Size original, Size target) =>
      _min(target.width / original.width, target.height / original.height);

  void setImageRect(Rect r) {
    Rect imRect = Rect.fromLTRB(0, 0, _imageSize!.width, _imageSize!.height);
    // make sure we have safe bounds within image
    widget.rectCallback(imRect.intersect(r));
    bool cropable = ((_initialScale! - 1).abs() > 1e-2) ||
        imRect.topLeft.dx.abs() > 20 ||
        imRect.topLeft.dy.abs() > 20;
    widget.canCropCallBack(cropable);
  } // of setImageRect

  Offset _sizeToOffset(Size x) => Offset(x.width, x.height);

/////////////////////////////
  ///    Widget lifecycle ///
/////////////////////////////
  ///
  @override
  void initState() {
    super.initState();
    _fingerGestureList.logger = _dPrint; // for debugging
    _loadMemoryImage(widget.imageUrl);
  }

  @override
  void didChangeDependencies() {
    _dPrint('didChangeDependencies');
    super.didChangeDependencies();
    _fingerGestureList.reset();
    _initialScale = null; // force a recalc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dPrint('exec postframecallback');
      _calcInitialScale();
      setState(() {}); // force repaint after first calc
    });
  }

  @override
  void didUpdateWidget(covariant Clipper oldWidget) {
    _dPrint('didupdatewidget');
    super.didUpdateWidget(oldWidget);
    _fingerGestureList.reset();
    _calcInitialScale();
  }

  @override
  Widget build(BuildContext context) {
    // _dPrint('build()');
    if (_initialScale == null) return Container();
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
              child: Image(
                image: NetworkImage(widget.imageUrl),
                width: boxConstraints.maxWidth,
                height: boxConstraints.maxHeight,
                fit: BoxFit.contain, // otherwise image holds subset of picture
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
