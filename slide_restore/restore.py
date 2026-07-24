#!/usr/bin/env python3
"""
Slide restoration. Reads per-image settings from configs.json.
For images not listed there, auto-detects the best colour profile.

Usage:
    python restore.py                               # all images in configs.json
    python restore.py --source D:\\DCIM\\100COACH  # read from scanner card
    python restore.py --all                         # also process unlisted files
    python restore.py --sharpen                     # add unsharp-mask after correction
    python restore.py PICT0002                      # one stem only
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

import slidelib as sl


def process(stem, cfg, img_cfg, source_dir, use_jpeg, do_sharpen):
    profile_name = img_cfg['profile']
    rotate       = img_cfg.get('rotate',    cfg['defaults'].get('rotate',    0))
    trim         = img_cfg.get('trim',      cfg['defaults'].get('trim',      0))
    raw_bright   = img_cfg.get('raw_bright', cfg['defaults'].get('raw_bright', 1.0))

    print(f'\n{stem}  profile={profile_name}  rotate={rotate}')

    arr, src_name = sl.load_source(stem, source_dir,
                                   raw_bright=raw_bright, use_jpeg=use_jpeg)
    if arr is None:
        print('  [error] no source file found')
        return
    print(f'  source: {src_name}')

    arr = sl.prepare(arr, rotate=rotate, trim=trim,
                     crop_box=img_cfg.get('crop_box'))
    if arr.size == 0:
        print('  [error] empty after crop/trim')
        return

    # Base profile params, with any per-image overrides (r/g/b/hdr) merged on top.
    # assess.py writes image-level overrides; manual entries in configs.json can too.
    params = {**cfg['profiles'].get(profile_name, {})}
    for key in ('r', 'g', 'b', 'hdr', 'lift'):
        if key in img_cfg:
            params[key] = img_cfg[key]
    result = sl.apply_correction(arr, params).astype('uint8')

    img = Image.fromarray(result)
    if do_sharpen or img_cfg.get('sharpen', False):
        img = sl.sharpen(img, cfg.get('sharpen', {}))
        print('  sharpened')

    sl.RESTORED.mkdir(exist_ok=True)
    out = sl.RESTORED / f'{stem}_restored.jpg'
    img.save(str(out), quality=95)
    print(f'  saved -> {out.name}  ({img.width}x{img.height}px)')


def main():
    parser = argparse.ArgumentParser(description='Restore digitised slide photos')
    parser.add_argument('--source', type=Path, default=sl.DEFAULT_SOURCE,
                        help='Directory containing source images')
    parser.add_argument('--all', action='store_true',
                        help='Process every JPEG in source dir, not just those in configs.json')
    parser.add_argument('--jpeg', action='store_true',
                        help='Force JPEG even when ORF exists')
    parser.add_argument('--sharpen', action='store_true',
                        help='Apply unsharp mask after colour correction')
    parser.add_argument('stems', nargs='*',
                        help='Stems to process (default: all in configs.json)')
    args = parser.parse_args()

    if not args.source.exists():
        print(f'Source directory not found: {args.source}')
        sys.exit(1)

    cfg = sl.load_configs()

    if args.stems:
        stems = args.stems
    elif args.all:
        stems = sorted(p.stem for p in args.source.glob('*.JPG'))
    else:
        stems = list(cfg['images'].keys())

    for stem in stems:
        if stem in cfg['images']:
            img_cfg = cfg['images'][stem]
        else:
            # Auto-detect profile for unlisted images
            arr, _ = sl.load_source(stem, args.source,
                                    raw_bright=cfg['defaults'].get('raw_bright', 1.0),
                                    use_jpeg=args.jpeg)
            if arr is None:
                print(f'\n{stem}  [error] no source file')
                continue
            # Prepare with defaults before analysing colour balance
            arr_prep = sl.prepare(arr,
                                  rotate=cfg['defaults'].get('rotate', 0),
                                  trim=cfg['defaults'].get('trim', 0))
            detected = sl.auto_profile(arr_prep)
            print(f'\n{stem}  auto-detected profile: {detected}')
            img_cfg = {**cfg['defaults'], 'profile': detected}

        process(stem, cfg, img_cfg, args.source, args.jpeg, args.sharpen)

    print('\nDone.')


if __name__ == '__main__':
    main()
