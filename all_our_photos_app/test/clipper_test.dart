// Tests for fingers.dart and clipper_math.dart
//
// Run with: flutter test test/clipper_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_our_photos_app/utils/fingers.dart';
import 'package:all_our_photos_app/utils/clipper_math.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const double eps = 0.01;

Offset transformPoint(Matrix4 m, Offset p) =>
    MatrixUtils.transformPoint(m, p);

void expectOffset(Offset actual, Offset expected, {double tolerance = eps}) {
  expect(actual.dx, closeTo(expected.dx, tolerance),
      reason: 'dx: expected ${expected.dx}, got ${actual.dx}');
  expect(actual.dy, closeTo(expected.dy, tolerance),
      reason: 'dy: expected ${expected.dy}, got ${actual.dy}');
}

// ---------------------------------------------------------------------------
// OneFingered
// ---------------------------------------------------------------------------

void main() {
  group('OneFingered', () {
    test('identity when start == end', () {
      final f = OneFingered(const Offset(100, 200));
      f.updateEndPoint(const Offset(100, 200));
      expectOffset(transformPoint(f.matrix, const Offset(50, 60)),
          const Offset(50, 60));
    });

    test('translates by (dx, dy)', () {
      final f = OneFingered(const Offset(0, 0));
      f.updateEndPoint(const Offset(30, -20));
      // dx = 30-0 = 30, dy = -20-0 = -20
      expectOffset(
          transformPoint(f.matrix, const Offset(100, 100)),
          const Offset(130, 80));
    });

    test('matrix entry(0,0) == 1 (no scaling)', () {
      final f = OneFingered(const Offset(10, 10));
      f.updateEndPoint(const Offset(50, 50));
      expect(f.matrix.entry(0, 0), closeTo(1.0, eps));
    });

    test('constructor with startPoint only gives T(-startPoint)', () {
      // OneFingered(p) with default endPoint=zero → dx = 0-p.dx = -p.dx
      final f = OneFingered(const Offset(40, 60));
      expectOffset(transformPoint(f.matrix, const Offset(100, 100)),
          const Offset(60, 40));
    });
  });

  // ---------------------------------------------------------------------------
  // TwoFingered
  // ---------------------------------------------------------------------------

  group('TwoFingered', () {
    test('scale=1 is identity', () {
      final f = TwoFingered(1, const Offset(400, 300));
      expectOffset(transformPoint(f.matrix, const Offset(200, 150)),
          const Offset(200, 150));
    });

    test('focus point is fixed under scaling', () {
      const focus = Offset(400, 300);
      final f = TwoFingered(3, focus);
      // The focal point itself must remain unchanged by scale-about-point.
      expectOffset(transformPoint(f.matrix, focus), focus);
    });

    test('scale=2 about origin doubles coordinates', () {
      final f = TwoFingered(2, Offset.zero);
      expectOffset(
          transformPoint(f.matrix, const Offset(100, 50)),
          const Offset(200, 100));
    });

    test('scale=2 about (400,300) — point away from focus', () {
      // Scale 2x about (400,300): (x,y) → 2*(x-400)+400, 2*(y-300)+300
      const focus = Offset(400, 300);
      final f = TwoFingered(2, focus);
      // (0,0) → (-400, -300)
      expectOffset(
          transformPoint(f.matrix, Offset.zero),
          const Offset(-400, -300));
      // (800,600) → (1200,900)
      expectOffset(
          transformPoint(f.matrix, const Offset(800, 600)),
          const Offset(1200, 900));
    });

    test('matrix entry(0,0) equals scale factor', () {
      final f = TwoFingered(2.5, const Offset(100, 100));
      expect(f.matrix.entry(0, 0), closeTo(2.5, eps));
    });

    test('updateScale changes the transform', () {
      final f = TwoFingered(1, const Offset(400, 300));
      f.updateScale(2.0);
      const focus = Offset(400, 300);
      expectOffset(transformPoint(f.matrix, focus), focus);
      expectOffset(
          transformPoint(f.matrix, Offset.zero),
          const Offset(-400, -300));
    });
  });

  // ---------------------------------------------------------------------------
  // FingerGestureList
  // ---------------------------------------------------------------------------

  group('FingerGestureList', () {
    test('empty list — totalScale is 1', () {
      final g = FingerGestureList();
      expect(g.totalScale(), closeTo(1.0, eps));
    });

    test('empty list — totalTransform is identity', () {
      final g = FingerGestureList();
      expectOffset(
          transformPoint(g.totalTransform(), const Offset(50, 80)),
          const Offset(50, 80));
    });

    test('single pan does not change totalScale', () {
      final g = FingerGestureList();
      g.add(OneFingered(const Offset(0, 0))..updateEndPoint(const Offset(50, 0)));
      expect(g.totalScale(), closeTo(1.0, eps));
    });

    test('single zoom gives correct totalScale', () {
      final g = FingerGestureList();
      g.add(TwoFingered(3, Offset.zero));
      expect(g.totalScale(), closeTo(3.0, eps));
    });

    test('composed zooms multiply scales', () {
      final g = FingerGestureList();
      g.add(TwoFingered(2, Offset.zero));
      g.add(TwoFingered(3, Offset.zero));
      expect(g.totalScale(), closeTo(6.0, eps));
    });

    test('pan then zoom — totalTransform applies both', () {
      final g = FingerGestureList();
      // Pan right 100 pixels: T(100,0)
      g.add(OneFingered(const Offset(0, 0))
        ..updateEndPoint(const Offset(100, 0)));
      // Zoom 2x about origin: S(2)
      g.add(TwoFingered(2, Offset.zero));

      // totalTransform = T(100,0) * S(2)
      // point (0,0)  → S(2)→(0,0)   → T(100,0)→(100,0)
      // point (50,0) → S(2)→(100,0) → T(100,0)→(200,0)
      expectOffset(
          transformPoint(g.totalTransform(), Offset.zero),
          const Offset(100, 0));
      expectOffset(
          transformPoint(g.totalTransform(), const Offset(50, 0)),
          const Offset(200, 0));
    });

    test('reset clears all gestures', () {
      final g = FingerGestureList();
      g.add(TwoFingered(5, Offset.zero));
      g.reset();
      expect(g.totalScale(), closeTo(1.0, eps));
    });

    test('removeLast undoes the last gesture', () {
      final g = FingerGestureList();
      g.add(TwoFingered(2, Offset.zero));
      g.add(TwoFingered(3, Offset.zero)); // total scale=6
      g.removeLast();
      expect(g.totalScale(), closeTo(2.0, eps)); // back to 2
    });
  });

  // ---------------------------------------------------------------------------
  // ClipperMath — initial scale / offsets
  // ---------------------------------------------------------------------------

  group('ClipperMath — initialScale and offsets', () {
    test('landscape image filling landscape screen exactly', () {
      // 4000×3000 image, 800×600 screen → scale=0.2, offsets=0
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      expect(m.initialScale, closeTo(0.2, eps));
      expect(m.xOffset, closeTo(0, eps));
      expect(m.yOffset, closeTo(0, eps));
    });

    test('portrait image on landscape screen — xOffset is negative', () {
      // 3000×4000 image, 800×600 screen → height constrains, scale=0.15
      // xOffset = (3000 - 800/0.15)/2 = (3000-5333)/2 = -1167
      final m = ClipperMath(
          imageSize: const Size(3000, 4000),
          targetSize: const Size(800, 600));
      expect(m.initialScale, closeTo(0.15, eps));
      expect(m.xOffset, closeTo(-1166.67, 1.0)); // negative — letterboxed
      expect(m.yOffset, closeTo(0, eps));
    });

    test('wide image on square screen — yOffset is negative', () {
      // 4000×1000 image, 500×500 screen → width constrains, scale=0.125
      // yOffset = (1000 - 500/0.125)/2 = (1000-4000)/2 = -1500
      final m = ClipperMath(
          imageSize: const Size(4000, 1000),
          targetSize: const Size(500, 500));
      expect(m.initialScale, closeTo(0.125, eps));
      expect(m.xOffset, closeTo(0, eps));
      expect(m.yOffset, closeTo(-1500, eps));
    });

    test('image smaller than screen — scale > 1', () {
      final m = ClipperMath(
          imageSize: const Size(100, 100), targetSize: const Size(800, 600));
      expect(m.initialScale, closeTo(6.0, eps)); // min(8,6)
    });
  });

  // ---------------------------------------------------------------------------
  // ClipperMath — calcImageRect
  // ---------------------------------------------------------------------------

  group('ClipperMath — calcImageRect', () {
    // Landscape image, screen exactly filled.
    late ClipperMath m;
    setUp(() {
      m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
    });

    test('identity transform shows full image', () {
      final r = m.calcImageRect(Matrix4.identity());
      expect(r.left, closeTo(0, eps));
      expect(r.top, closeTo(0, eps));
      expect(r.right, closeTo(4000, eps));
      expect(r.bottom, closeTo(3000, eps));
    });

    test('zoom 2x at center shows centre quarter of image', () {
      const center = Offset(400, 300);
      final zoom = TwoFingered(2, center);
      final r = m.calcImageRect(zoom.matrix);
      // At 2x zoom about screen centre the visible region should be
      // centred on the image centre and half the full size.
      expect(r.center.dx, closeTo(2000, 1));
      expect(r.center.dy, closeTo(1500, 1));
      expect(r.width, closeTo(2000, 1));
      expect(r.height, closeTo(1500, 1));
    });

    test('pan right by half screen width shifts visible region left', () {
      // Pan: finger moves from (0,0) to (400,0) — image shifts right
      // so we see the LEFT half of the image.
      final pan = OneFingered(const Offset(0, 0))
        ..updateEndPoint(const Offset(400, 0));
      final r = m.calcImageRect(pan.matrix);
      // Left edge should be negative (off-image), right edge ~2000
      expect(r.right, closeTo(2000, 1));
    });

    test('top-left image pixel maps to screen origin at identity', () {
      // At identity transform, screen (0,0) should show image (0,0).
      final r = m.calcImageRect(Matrix4.identity());
      expect(r.topLeft, equals(const Offset(0, 0)));
    });
  });

  // ---------------------------------------------------------------------------
  // ClipperMath — shouldUndo (bug regression)
  // ---------------------------------------------------------------------------

  group('ClipperMath — shouldUndo', () {
    test('identity transform should not undo', () {
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      final r = m.calcImageRect(Matrix4.identity());
      expect(m.shouldUndo(r, 1.0), isFalse);
    });

    test('zoom > 16x should undo', () {
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      final r = m.calcImageRect(Matrix4.identity());
      expect(m.shouldUndo(r, 20.0), isTrue);
    });

    test('extreme pan right (past left edge) should undo', () {
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      // Pan image far right so the image's left edge is past the screen left edge
      final pan = OneFingered(const Offset(0, 0))
        ..updateEndPoint(const Offset(4000, 0));
      final r = m.calcImageRect(pan.matrix);
      expect(m.shouldUndo(r, 1.0), isTrue);
    });

    // Regression: portrait image on landscape screen — zoom should be ALLOWED.
    // Before the fix (using xOffset instead of 0) this test would fail because
    // xOffset=-1167, and zoom makes r.topLeft.dx go more negative → undo triggered.
    test('portrait image on landscape screen — zoom-in should NOT undo', () {
      final m = ClipperMath(
          imageSize: const Size(3000, 4000),
          targetSize: const Size(800, 600));
      // xOffset is about -1167 here.
      const center = Offset(400, 300);
      final zoom = TwoFingered(2, center);
      final r = m.calcImageRect(zoom.matrix);
      expect(m.shouldUndo(r, 2.0), isFalse,
          reason:
              'zoom-in on portrait image was incorrectly undone when comparing '
              'against xOffset instead of 0');
    });

    test('portrait image — modest right pan should undo', () {
      final m = ClipperMath(
          imageSize: const Size(3000, 4000),
          targetSize: const Size(800, 600));
      // Pan image very far right so left image boundary is off screen
      final pan = OneFingered(const Offset(0, 0))
        ..updateEndPoint(const Offset(5000, 0));
      final r = m.calcImageRect(pan.matrix);
      expect(m.shouldUndo(r, 1.0), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ClipperMath — isCropable
  // ---------------------------------------------------------------------------

  group('ClipperMath — isCropable', () {
    test('full-image view (no zoom/pan) is NOT cropable', () {
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      final r = m.calcImageRect(Matrix4.identity());
      expect(m.isCropable(r), isFalse);
    });

    test('zoomed-in view is cropable', () {
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      final zoom = TwoFingered(2, const Offset(400, 300));
      final r = m.calcImageRect(zoom.matrix);
      expect(m.isCropable(r), isTrue);
    });

    test('panned view is cropable', () {
      final m = ClipperMath(
          imageSize: const Size(4000, 3000),
          targetSize: const Size(800, 600));
      final pan = OneFingered(const Offset(0, 0))
        ..updateEndPoint(const Offset(200, 0));
      final r = m.calcImageRect(pan.matrix);
      expect(m.isCropable(r), isTrue);
    });

    test('portrait image full-image view is NOT cropable', () {
      // xOffset is negative for portrait on landscape screen — full-image view
      // should still not be cropable regardless of xOffset value.
      final m = ClipperMath(
          imageSize: const Size(3000, 4000),
          targetSize: const Size(800, 600));
      final r = m.calcImageRect(Matrix4.identity());
      expect(m.isCropable(r), isFalse);
    });

    test('portrait image zoomed-in is cropable', () {
      final m = ClipperMath(
          imageSize: const Size(3000, 4000),
          targetSize: const Size(800, 600));
      final zoom = TwoFingered(2, const Offset(400, 300));
      final r = m.calcImageRect(zoom.matrix);
      expect(m.isCropable(r), isTrue);
    });
  });
}
