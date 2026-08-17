// Tests for the draggable crop rectangle model and the coordinate mapping
// it relies on.
//
// Run with: flutter test test/crop_rect_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_our_photos_app/utils/crop_rect.dart';
import 'package:all_our_photos_app/utils/clipper_math.dart';
import 'package:all_our_photos_app/utils/fingers.dart';

const eps = 0.01;

void main() {
  group('CropRectModel.gripAt', () {
    final model = CropRectModel(const Rect.fromLTRB(100, 100, 500, 400));

    test('finds each corner', () {
      expect(model.gripAt(const Offset(102, 98), 20), CropGrip.topLeft);
      expect(model.gripAt(const Offset(498, 103), 20), CropGrip.topRight);
      expect(model.gripAt(const Offset(105, 396), 20), CropGrip.bottomLeft);
      expect(model.gripAt(const Offset(503, 402), 20), CropGrip.bottomRight);
    });

    test('inside the rectangle moves it', () {
      expect(model.gripAt(const Offset(300, 250), 20), CropGrip.move);
    });

    test('well outside grabs nothing, so the drag can pan the view', () {
      expect(model.gripAt(const Offset(20, 20), 20), CropGrip.none);
      expect(model.gripAt(const Offset(700, 250), 20), CropGrip.none);
    });

    test('a corner wins over move when both are in range', () {
      // Just inside the top-left corner: could be read as "inside", but the
      // corner must take priority or resizing becomes impossible.
      expect(model.gripAt(const Offset(104, 104), 20), CropGrip.topLeft);
    });

    test('the nearest corner wins on a small rectangle', () {
      final tiny = CropRectModel(const Rect.fromLTRB(0, 0, 30, 30));
      expect(tiny.gripAt(const Offset(29, 29), 20), CropGrip.bottomRight);
      expect(tiny.gripAt(const Offset(1, 1), 20), CropGrip.topLeft);
    });
  });

  group('CropRectModel.dragged', () {
    final model = CropRectModel(Rect.zero);
    const start = Rect.fromLTRB(100, 100, 500, 400);

    test('dragging a corner moves only that corner', () {
      final r = model.dragged(CropGrip.topLeft, start, const Offset(50, 20));
      expect(r, const Rect.fromLTRB(150, 120, 500, 400));
    });

    test('dragging the opposite corner leaves the anchor alone', () {
      final r =
          model.dragged(CropGrip.bottomRight, start, const Offset(-100, -50));
      expect(r, const Rect.fromLTRB(100, 100, 400, 350));
    });

    test('top-right drag keeps left and bottom fixed', () {
      final r = model.dragged(CropGrip.topRight, start, const Offset(30, 40));
      expect(r, const Rect.fromLTRB(100, 140, 530, 400));
    });

    test('move shifts the whole rectangle, preserving size', () {
      final r = model.dragged(CropGrip.move, start, const Offset(-40, 60));
      expect(r, const Rect.fromLTRB(60, 160, 460, 460));
      expect(r.size, start.size);
    });

    test('none leaves the rectangle untouched', () {
      expect(model.dragged(CropGrip.none, start, const Offset(99, 99)), start);
    });

    test('dragging a corner past its opposite does not invert the rectangle',
        () {
      // Drag the top-left corner way beyond the bottom-right.
      final r = model.dragged(CropGrip.topLeft, start, const Offset(600, 500));
      expect(r.width, greaterThanOrEqualTo(0),
          reason: 'an inverted rect would give a negative-size crop');
      expect(r.height, greaterThanOrEqualTo(0));
      expect(r, const Rect.fromLTRB(500, 400, 700, 600));
    });
  });

  group('CropRectModel.isWorthCropping', () {
    const full = Rect.fromLTRB(0, 0, 4000, 3000);

    test('the whole image is not worth cropping', () {
      expect(CropRectModel.isWorthCropping(full, full), isFalse);
    });

    test('a sub-region is worth cropping', () {
      expect(
          CropRectModel.isWorthCropping(
              const Rect.fromLTRB(100, 100, 3000, 2000), full),
          isTrue);
    });

    test('trimming a single edge counts', () {
      expect(
          CropRectModel.isWorthCropping(
              const Rect.fromLTRB(0, 0, 3000, 3000), full),
          isTrue);
    });

    test('a hair off the full frame does not count', () {
      expect(
          CropRectModel.isWorthCropping(
              const Rect.fromLTRB(1, 1, 3999, 2999), full),
          isFalse);
    });
  });

  group('ClipperMath screen/image mapping', () {
    // Portrait phone, landscape photo — the case that made viewport cropping
    // unusable in the first place.
    final m = ClipperMath(
        imageSize: const Size(4608, 3456), targetSize: const Size(400, 800));

    test('screenToImage and imageToScreen are inverses at identity', () {
      const p = Offset(1234, 2345);
      final screen = m.imageToScreen(p, Matrix4.identity());
      final back = m.screenToImage(screen, Matrix4.identity());
      expect(back.dx, closeTo(p.dx, eps));
      expect(back.dy, closeTo(p.dy, eps));
    });

    test('and are inverses under zoom and pan too', () {
      final g = FingerGestureList();
      g.add(TwoFingered(3, const Offset(200, 400)));
      g.add(OneFingered(const Offset(0, 0), endPoint: const Offset(40, -25)));
      final t = g.totalTransform();

      for (final p in [
        const Offset(0, 0),
        const Offset(4608, 3456),
        const Offset(1500, 900),
      ]) {
        final back = m.screenToImage(m.imageToScreen(p, t), t);
        expect(back.dx, closeTo(p.dx, 0.5), reason: 'x for $p');
        expect(back.dy, closeTo(p.dy, 0.5), reason: 'y for $p');
      }
    });

    test('a crop rect holds the same image pixels across a zoom', () {
      // The whole point of keeping the selection in image coordinates.
      const selection = Rect.fromLTRB(1000, 800, 3000, 2200);
      final zoomedIn = TwoFingered(4, const Offset(200, 400)).matrix;

      final onScreenBefore =
          m.imageRectToScreen(selection, Matrix4.identity());
      final onScreenAfter = m.imageRectToScreen(selection, zoomedIn);
      expect(onScreenAfter, isNot(equals(onScreenBefore)),
          reason: 'it should move on screen when the view zooms');

      // ...but map straight back to the same image pixels.
      final back = Rect.fromPoints(
          m.screenToImage(onScreenAfter.topLeft, zoomedIn),
          m.screenToImage(onScreenAfter.bottomRight, zoomedIn));
      expect(back.left, closeTo(selection.left, 0.5));
      expect(back.top, closeTo(selection.top, 0.5));
      expect(back.right, closeTo(selection.right, 0.5));
      expect(back.bottom, closeTo(selection.bottom, 0.5));
    });

    test('a wide crop is now expressible on a tall screen', () {
      // The thing viewport cropping could not do: 16:9 from a 4:3 photo.
      final wide = m.clampCrop(const Rect.fromLTRB(300, 1200, 4300, 3450));
      expect(wide.width / wide.height, greaterThan(1.7));
      expect(m.fullImageRect.contains(wide.topLeft), isTrue);
    });
  });

  group('ClipperMath.clampCrop', () {
    final m = ClipperMath(
        imageSize: const Size(4000, 3000), targetSize: const Size(800, 600));

    test('leaves an in-bounds rect alone', () {
      const r = Rect.fromLTRB(100, 200, 3000, 2500);
      expect(m.clampCrop(r), r);
    });

    test('pulls a rect back inside the image', () {
      final r = m.clampCrop(const Rect.fromLTRB(-500, -400, 5000, 4000));
      expect(r, const Rect.fromLTRB(0, 0, 4000, 3000));
    });

    test('enforces a minimum size', () {
      final r = m.clampCrop(const Rect.fromLTRB(1000, 1000, 1001, 1001));
      expect(r.width, greaterThanOrEqualTo(16));
      expect(r.height, greaterThanOrEqualTo(16));
    });

    test('keeps the result inside the image even at the far edge', () {
      final r = m.clampCrop(const Rect.fromLTRB(3999, 2999, 4200, 3200));
      expect(r.right, lessThanOrEqualTo(4000));
      expect(r.bottom, lessThanOrEqualTo(3000));
      expect(r.width, greaterThanOrEqualTo(16));
    });
  });
}
