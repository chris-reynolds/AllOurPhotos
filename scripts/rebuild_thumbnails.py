#!/usr/bin/env python3
"""Rebuilds thumbnails that the old rendering code got wrong.

Two faults left bad thumbnails on disk, and neither corrects itself - the
fixes only govern thumbnails written from now on:

  - makeThumbnail applied EXIF orientation with rotate(270)/rotate(90) and no
    expand=True.  Orientations 6 and 8 flip the aspect, so portrait content
    was padded into a landscape frame: black bands down two sides with the
    ends cut off.  Orientations 2, 4, 5 and 7 were ignored outright, so those
    thumbnails are simply not mirrored or turned as they should be.
    Orientation 3 is a half turn, which preserves the aspect, and the old code
    handled it correctly - those are left alone.

  - reset_thumbnail rebuilt from the original but skipped the snap's degrees,
    so 'resetting' a rotated photo left the grid showing it upright while the
    single view showed it turned.

A thumbnail is rebuilt when any of these hold:
    * the original's EXIF orientation is one the old code mishandled
    * the snap has a rotation, so the thumbnail may predate it
    * the thumbnail is missing

A solid black edge looks like the obvious symptom, but it is not a criterion
here.  Where the orientation is 1, absent, or 3 and there is no rotation, the
old code and the new one produce byte-identical thumbnails: exif_transpose is
a no-op for the first two, the old block matched none of its branches, and a
half turn commutes with resampling.  So a black edge on those is in the
photograph - a night shot, a letterboxed scan - and rebuilding would rewrite
5206 files instead of 4119 to no effect, while changing every mtime and so
forcing the browser to re-fetch them all.  --include-dark-edges is there if
you want to sweep them anyway.

Rebuilding is a pure function of the original and the snap's degrees, so this
is idempotent and safe to interrupt and re-run.

Dry run by default.  Pass --apply to write.

  python3 rebuild_thumbnails.py                 # report only
  python3 rebuild_thumbnails.py --apply
  python3 rebuild_thumbnails.py --apply --limit 50
"""

import argparse
import os
import sys
import time

sys.path.insert(0, '/app')

from PIL import Image  # noqa: E402

from src.aopservermain import (  # noqa: E402
    ROOT_DIR,
    makeThumbnail,
    raw_sql,
    thumbnail_name,
)

# Orientations the old code mishandled.  3 is a half turn, which keeps the
# aspect, and the old block applied it correctly - so it is not here.
BAD_ORIENTATIONS = {2, 4, 5, 6, 7, 8}

STILL_IMAGE_SUFFIXES = ('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif',
                        '.tiff', '.webp')


def has_black_edge(path):
    """True when a whole edge line of the thumbnail is black.

    That is what padding a rotated picture into an unexpanded canvas leaves
    behind, and it is the one symptom visible without knowing anything about
    the original.
    """
    try:
        with Image.open(path) as im:
            im = im.convert('RGB')
            w, h = im.size
            px = im.load()
            dark = lambda p: sum(p) < 40
            return (all(dark(px[x, 0]) for x in range(w))
                    or all(dark(px[x, h - 1]) for x in range(w))
                    or all(dark(px[0, y]) for y in range(h))
                    or all(dark(px[w - 1, y]) for y in range(h)))
    except Exception:
        return False


def orientation_of(path):
    try:
        with Image.open(path) as im:
            return (im._getexif() or {}).get(274)
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--apply', action='store_true',
                    help='actually rebuild; otherwise report only')
    ap.add_argument('--limit', type=int, default=0,
                    help='stop after N rebuilds (0 = no limit)')
    ap.add_argument('--quiet', action='store_true',
                    help='only print the summary')
    ap.add_argument('--include-dark-edges', action='store_true',
                    help='also rebuild thumbnails with a solid black edge, '
                         'even where the old and new code provably agree '
                         '(mostly night shots and letterboxed scans)')
    args = ap.parse_args()

    rows = raw_sql('select id, directory, file_name, degrees from aopsnaps '
                   'order by directory, file_name')
    print(f'snaps in the database: {len(rows)}')

    reasons = {'orientation': 0, 'rotated': 0, 'missing': 0, 'black edge': 0}
    todo = []
    skipped_not_image = 0
    scanned = 0
    started = time.time()

    for row in rows:
        directory = row['directory'] or ''
        fileName = row['file_name'] or ''
        if not fileName.lower().endswith(STILL_IMAGE_SUFFIXES):
            skipped_not_image += 1
            continue

        original = os.path.join(ROOT_DIR, directory, fileName)
        if not os.path.isfile(original):
            continue

        thumb = os.path.join(ROOT_DIR, directory, 'thumbnails',
                             thumbnail_name(fileName))
        degrees = row['degrees'] or 0

        scanned += 1
        if not args.quiet and scanned % 2000 == 0:
            print(f'  scanned {scanned}...', flush=True)

        why = None
        if not os.path.isfile(thumb):
            why = 'missing'
        elif orientation_of(original) in BAD_ORIENTATIONS:
            why = 'orientation'
        elif degrees:
            why = 'rotated'
        elif args.include_dark_edges and has_black_edge(thumb):
            why = 'black edge'

        if why:
            reasons[why] += 1
            todo.append((row['id'], original, thumb, degrees, why))

    print(f'\nscanned {scanned} still images in '
          f'{time.time() - started:.0f}s  ({skipped_not_image} non-images skipped)')
    print('needing a rebuild:')
    for why, n in reasons.items():
        print(f'    {why:12} {n}')
    print(f'    {"total":12} {len(todo)}')

    if not args.apply:
        print('\nDry run - nothing written.  Re-run with --apply to rebuild.')
        return

    print(f'\nrebuilding {len(todo)}...')
    done = failed = 0
    started = time.time()
    for snap_id, original, thumb, degrees, why in todo:
        if args.limit and done >= args.limit:
            print(f'stopping at --limit {args.limit}')
            break
        try:
            os.makedirs(os.path.dirname(thumb), exist_ok=True)
            with Image.open(original) as im:
                makeThumbnail(im, im._getexif(), thumb, degrees)
            done += 1
            if not args.quiet and done % 100 == 0:
                rate = done / max(time.time() - started, 1e-6)
                left = (len(todo) - done) / max(rate, 1e-6)
                print(f'  {done}/{len(todo)}  {rate:.1f}/s  '
                      f'~{left / 60:.0f} min left', flush=True)
        except Exception as ex:
            # One bad photo must not stop a run of thousands.
            failed += 1
            print(f'  FAILED snap {snap_id} {original}: {ex!r}')

    print(f'\nrebuilt {done}, failed {failed}, '
          f'in {(time.time() - started) / 60:.1f} min')
    if done:
        print('Browsers pick these up on the next view - /photos revalidates '
              'and only changed thumbnails transfer.')


if __name__ == '__main__':
    main()
