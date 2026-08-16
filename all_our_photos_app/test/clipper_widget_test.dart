// Widget-level tests for the Clipper gesture handling.
//
// These drive real pointer events through the ScaleGestureRecognizer, which is
// the part clipper_test.dart cannot reach — it only exercises the pure maths.
// What matters here is WHEN the rect/crop callbacks fire, not just the algebra.
//
// Run with: flutter test test/clipper_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:all_our_photos_app/widgets/wdgClipper.dart';

const imageWidth = 4000;
const imageHeight = 3000;

// The Clipper is given an 800x600 box, so initialScale = 0.2 and the whole
// 4000x3000 image exactly fills it (xOffset = yOffset = 0).
const boxSize = Size(800, 600);

/// Captures everything the Clipper reports back to its parent.
class Harness {
  Rect? rect;
  bool? canCrop;
  int navigations = 0;
  int lastDelta = 0;
  final log = MapProvider();

  /// The widget's own debug trace, handy when a gesture does nothing.
  String get trace => log.value['zmessage'] ?? '(no log)';
}

Future<Harness> pumpClipper(WidgetTester tester,
    {bool withSwipe = true}) async {
  final h = Harness();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<MapProvider>.value(
        value: h.log,
        child: Center(
          child: SizedBox(
            width: boxSize.width,
            height: boxSize.height,
            child: Clipper(
              imageUrl: 'https://example.invalid/photo.jpg',
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              rectCallback: (r) => h.rect = r,
              canCropCallBack: (v) => h.canCrop = v,
              navigateCallBack: withSwipe
                  ? (d) {
                      h.navigations++;
                      h.lastDelta = d;
                    }
                  : null,
            ),
          ),
        ),
      ),
    ),
  ));
  // The image will fail to load in a test; that is irrelevant to gestures.
  tester.takeException();
  // _calcInitialScale runs in a post-frame callback, then setState rebuilds.
  await tester.pump();
  await tester.pump();
  tester.takeException();
  return h;
}

/// Centre of the Clipper box in global coordinates.
Offset get boxCentre => const Offset(400, 300) + _boxOrigin;
Offset get _boxOrigin {
  // Centred in the default 800x600 test window, so the box fills it exactly.
  return Offset.zero;
}

/// A two-finger pinch that scales about [centre] by [factor].
Future<void> pinch(WidgetTester tester, Offset centre, double factor,
    {Offset drift = Offset.zero}) async {
  // Keep the fingers well inside the box: they must never leave the widget or
  // the gesture is cancelled and the pinch silently does nothing.
  const reach = 40.0;
  final start1 = centre - const Offset(reach, 0);
  final start2 = centre + const Offset(reach, 0);
  final end1 = centre - Offset(reach * factor, 0) + drift;
  final end2 = centre + Offset(reach * factor, 0) + drift;
  for (final p in [start1, start2, end1, end2]) {
    expect(
        p.dx >= 0 &&
            p.dx <= boxSize.width &&
            p.dy >= 0 &&
            p.dy <= boxSize.height,
        isTrue,
        reason: 'pinch finger $p leaves the $boxSize box - bad test setup');
  }

  final g1 = await tester.startGesture(start1);
  final g2 = await tester.startGesture(start2);
  await tester.pump();
  // Move in a few steps so the recogniser sees a real pinch.
  for (var i = 1; i <= 4; i++) {
    final t = i / 4;
    await g1.moveTo(Offset.lerp(start1, end1, t)!);
    await g2.moveTo(Offset.lerp(start2, end2, t)!);
    await tester.pump();
  }
  await g1.up();
  await g2.up();
  await settle(tester);
}

/// Lets the GestureDetector's double-tap timer expire, so the test does not
/// end with a pending timer.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// A one-finger drag from [from] by [travel], in several steps.
Future<void> drag(WidgetTester tester, Offset from, Offset travel) async {
  final g = await tester.startGesture(from);
  await tester.pump();
  for (var i = 1; i <= 4; i++) {
    await g.moveTo(from + travel * (i / 4));
    await tester.pump();
  }
  await g.up();
  await settle(tester);
}

void main() {
  testWidgets('changing photo clears the parent\'s crop state', (tester) async {
    // After a swipe (or a crop) the Clipper resets to the full image, but the
    // parent keeps whatever rect/canCrop it was last told.  If the reset is
    // not published, the next crop uses the PREVIOUS photo's rectangle.
    final h = Harness();
    Widget build(String url) => MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<MapProvider>.value(
              value: h.log,
              child: Center(
                child: SizedBox(
                  width: boxSize.width,
                  height: boxSize.height,
                  child: Clipper(
                    imageUrl: url,
                    imageWidth: imageWidth,
                    imageHeight: imageHeight,
                    rectCallback: (r) => h.rect = r,
                    canCropCallBack: (v) => h.canCrop = v,
                    navigateCallBack: (d) {
                      h.navigations++;
                      h.lastDelta = d;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(build('https://example.invalid/one.jpg'));
    tester.takeException();
    await tester.pump();
    await tester.pump();
    tester.takeException();

    await pinch(tester, const Offset(300, 250), 3.0);
    expect(h.canCrop, isTrue, reason: 'zoomed in on the first photo');
    final zoomedRect = h.rect!;

    // Swipe moves to another photo: the parent rebuilds with a new imageUrl.
    await tester.pumpWidget(build('https://example.invalid/two.jpg'));
    tester.takeException();
    await tester.pump();
    await tester.pump();
    tester.takeException();

    expect(h.canCrop, isFalse,
        reason: 'a fresh photo is unzoomed, so it must not be croppable');
    expect(h.rect, isNot(equals(zoomedRect)),
        reason: "the parent must not keep the previous photo's crop rect");
  });

  testWidgets('publishes the full-image rect before any gesture',
      (tester) async {
    final h = await pumpClipper(tester);
    expect(h.rect, const Rect.fromLTRB(0, 0, 4000, 3000),
        reason: 'the parent should start with the whole image selected');
    expect(h.canCrop, isFalse,
        reason: 'an untouched photo is not worth cropping');
  });

  testWidgets('pinch zoom publishes a croppable sub-rect', (tester) async {
    final h = await pumpClipper(tester);
    await pinch(tester, boxCentre, 2.0);

    expect(h.canCrop, isTrue,
        reason: 'after zooming in, the crop button must be enabled');
    final r = h.rect!;
    // Zoomed 2x about the centre => roughly the middle quarter of the image.
    expect(r.width, lessThan(imageWidth * 0.75),
        reason: 'visible region should be much narrower than the full image');
    expect(r.height, lessThan(imageHeight * 0.75));
    expect(r.center.dx, closeTo(imageWidth / 2, imageWidth * 0.15));
    expect(r.center.dy, closeTo(imageHeight / 2, imageHeight * 0.15));
  });

  testWidgets('one-finger drag while zoomed pans instead of navigating',
      (tester) async {
    final h = await pumpClipper(tester);
    await pinch(tester, boxCentre, 2.0);
    final beforePan = h.rect!;

    await drag(tester, boxCentre, const Offset(-60, 0));

    expect(h.navigations, 0,
        reason: 'a drag while zoomed must not change photo');
    expect(h.rect!.left, isNot(closeTo(beforePan.left, 1)),
        reason: 'the visible region should have moved');
  });

  testWidgets('panning towards the top-left edge keeps the zoom',
      (tester) async {
    // The edge-precision workflow: zoom in, then pan to bring an edge of the
    // photo into view.  shouldUndo rejects a gesture wholesale when the
    // visible region crosses the image boundary, so a pan that overshoots
    // must not also throw away the zoom.
    final h = await pumpClipper(tester);
    await pinch(tester, const Offset(200, 150), 4.0);
    final zoomed = h.rect!;
    expect(h.canCrop, isTrue);

    // Drag down-right repeatedly, walking the view towards the top-left of
    // the image - eventually overshooting the boundary.
    for (var i = 0; i < 4; i++) {
      await drag(tester, boxCentre, const Offset(120, 120));
    }

    expect(h.navigations, 0, reason: 'panning while zoomed must not navigate');
    expect(h.canCrop, isTrue,
        reason: 'the photo should still be zoomed and croppable');
    expect(h.rect!.width, closeTo(zoomed.width, zoomed.width * 0.1),
        reason: 'the zoom level should survive panning to the edge');
  });

  testWidgets('a pinch whose fingers drift keeps the zoom', (tester) async {
    // Focal drift means a pinch now pans as well as zooms, so a drifting
    // pinch must not be rejected outright by shouldUndo.
    final h = await pumpClipper(tester);
    await pinch(tester, const Offset(250, 200), 3.0,
        drift: const Offset(60, 60));

    expect(h.canCrop, isTrue,
        reason: 'a pinch with drifting fingers must still zoom');
    expect(h.rect!.width, lessThan(imageWidth * 0.8));
  });

  testWidgets('swipe while unzoomed navigates and does not move the image',
      (tester) async {
    final h = await pumpClipper(tester);

    await drag(tester, boxCentre, const Offset(0, 120));

    expect(h.navigations, 1);
    expect(h.lastDelta, -1, reason: 'swipe down goes to the previous photo');
    expect(h.canCrop, isNot(isTrue),
        reason: 'a swipe must not make it croppable');
  });
}
