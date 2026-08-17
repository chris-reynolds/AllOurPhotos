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
    {bool withSwipe = true,
    Size? box,
    int imgW = imageWidth,
    int imgH = imageHeight,
    bool cropMode = false}) async {
  final size = box ?? boxSize;
  final h = Harness();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<MapProvider>.value(
        value: h.log,
        child: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Clipper(
              imageUrl: 'https://example.invalid/photo.jpg',
              imageWidth: imgW,
              imageHeight: imgH,
              rectCallback: (r) => h.rect = r,
              canCropCallBack: (v) => h.canCrop = v,
              cropMode: cropMode,
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
    {Offset drift = Offset.zero, double reach = 40.0, Size? bound}) async {
  // Keep the fingers well inside the box: they must never leave the widget or
  // the gesture is cancelled and the pinch silently does nothing.
  final limit = bound ?? boxSize;
  final start1 = centre - Offset(reach, 0);
  final start2 = centre + Offset(reach, 0);
  final end1 = centre - Offset(reach * factor, 0) + drift;
  final end2 = centre + Offset(reach * factor, 0) + drift;
  for (final p in [start1, start2, end1, end2]) {
    expect(
        p.dx >= 0 &&
            p.dx <= limit.width &&
            p.dy >= 0 &&
            p.dy <= limit.height,
        isTrue,
        reason: 'pinch finger $p leaves the $limit box - bad test setup');
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
  // ------------------------------------------------------------------------
  // Crop mode: a draggable rectangle, held in image coordinates.
  // ------------------------------------------------------------------------

  group('crop mode', () {
    testWidgets('starts by selecting the whole unzoomed photo', (tester) async {
      final h = await pumpClipper(tester, cropMode: true);
      expect(h.rect, const Rect.fromLTRB(0, 0, 4000, 3000));
      expect(h.canCrop, isFalse,
          reason: 'selecting everything is not worth cropping');
    });

    testWidgets('dragging a corner shrinks the selection and enables Apply',
        (tester) async {
      final h = await pumpClipper(tester, cropMode: true);
      // The box is 800x600 for a 4000x3000 photo, so 1 screen px = 5 image px.
      // Start just inside: the GestureDetector sits behind 2px padding and a
      // 1px border, so (0,0) misses it entirely.
      await drag(tester, const Offset(6, 6), const Offset(100, 60));

      final r = h.rect!;
      expect(r.left, closeTo(500, 30), reason: '100 screen px = 500 image px');
      expect(r.top, closeTo(300, 30));
      expect(r.right, closeTo(4000, 1), reason: 'far corner must not move');
      expect(r.bottom, closeTo(3000, 1));
      expect(h.canCrop, isTrue);
    });

    testWidgets('a wide selection is possible on a tall screen', (tester) async {
      // The whole point of abandoning viewport cropping: on a 400x800 phone a
      // 4608x3456 photo could only ever yield a crop between 0.5 and 1.33.
      const pw = 400.0, ph = 800.0;
      const iw = 4608, ih = 3456;
      final h = await pumpClipper(tester,
          box: const Size(pw, ph), imgW: iw, imgH: ih, cropMode: true);

      // The photo occupies y 250..550 on screen. Pull the top edge down and
      // the bottom edge up to leave a letterbox-shaped band.
      await drag(tester, const Offset(6, 250), const Offset(0, 110));
      await drag(tester, const Offset(pw - 6, 550), const Offset(0, -110));

      final r = h.rect!;
      expect(r.width / r.height, greaterThan(1.8),
          reason: 'a 16:9-ish crop is now reachable on a portrait screen');
      expect(h.canCrop, isTrue);
    });

    testWidgets('the selection survives a zoom', (tester) async {
      final h = await pumpClipper(tester, cropMode: true);
      await drag(tester, const Offset(6, 6), const Offset(100, 60));
      final before = h.rect!;

      // Zooming is now purely navigation - it must not touch the selection.
      await pinch(tester, boxCentre, 2.0);

      expect(h.rect!.left, closeTo(before.left, 1));
      expect(h.rect!.top, closeTo(before.top, 1));
      expect(h.rect!.right, closeTo(before.right, 1));
      expect(h.rect!.bottom, closeTo(before.bottom, 1));
    });

    testWidgets('swipe navigation is suspended while cropping', (tester) async {
      final h = await pumpClipper(tester, cropMode: true);
      // A long drag that would navigate in browse mode.
      await drag(tester, boxCentre, const Offset(0, 150));
      expect(h.navigations, 0,
          reason: 'a drag must never change photo mid-crop');
    });

    testWidgets('the selection cannot be dragged outside the image',
        (tester) async {
      final h = await pumpClipper(tester, cropMode: true);
      await drag(tester, const Offset(6, 6), const Offset(-300, -300));
      final r = h.rect!;
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.top, greaterThanOrEqualTo(0));
    });
  });

  // ------------------------------------------------------------------------
  // The crop region IS the viewport, so its shape is not freely selectable.
  //
  // On a portrait phone showing a landscape photo, BoxFit.contain letterboxes
  // the photo to a fraction of the screen height.  Until the zoom is large
  // enough for the photo to overflow the viewport vertically, the visible
  // region spans the FULL image height, so every crop comes out portrait-ish
  // however the user pinches.  This is not an x/y transposition - the rect
  // faithfully describes what is on screen - but it does mean a wide crop
  // cannot be made on a tall screen.
  // ------------------------------------------------------------------------

  testWidgets('crop height stays pinned to the full image until zoomed past '
      'the letterbox', (tester) async {
    const pw = 400.0, ph = 800.0; // portrait phone
    const iw = 4608, ih = 3456; // landscape photo, as in the database

    // The photo is only 300 of the 800 logical pixels tall, so it takes a
    // zoom of 800/300 = 2.67 before the height is cropped at all.
    final h = await pumpClipper(tester,
        box: const Size(pw, ph), imgW: iw, imgH: ih);
    await pinch(tester, const Offset(pw / 2, ph / 2), 2.0,
        reach: 30, bound: const Size(pw, ph));

    expect(h.rect!.height, closeTo(ih.toDouble(), 1),
        reason: 'below the letterbox zoom the whole image height is visible, '
            'so the crop cannot be shortened');
    expect(h.rect!.width, lessThan(iw * 0.9),
        reason: 'the width does narrow with zoom');
  });

  testWidgets('a hard zoom converges on the viewport aspect ratio',
      (tester) async {
    const pw = 400.0, ph = 800.0;
    const iw = 4608, ih = 3456;

    final h = await pumpClipper(tester,
        box: const Size(pw, ph), imgW: iw, imgH: ih);
    await pinch(tester, const Offset(pw / 2, ph / 2), 4.0,
        reach: 30, bound: const Size(pw, ph));

    final r = h.rect!;
    expect(r.width / r.height, closeTo(pw / ph, 0.05),
        reason: 'once the photo overflows the viewport the crop takes the '
            'viewport shape - 0.5 here, so no wide crop is reachable');
  });

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
