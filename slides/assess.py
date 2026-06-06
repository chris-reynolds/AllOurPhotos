#!/usr/bin/env python3
"""
Locally assess slide scans and populate configs.json.

Uses channel-ratio analysis (slidelib.auto_profile) to select a colour
correction profile.  No API key or network access required.

Usage:
    python assess.py --source D:\\DCIM\\100COACH --all     # all unassessed images
    python assess.py --all                                  # from original/
    python assess.py --force --all                          # re-assess everything
    python assess.py --dry-run PICT0004                     # preview without saving
    python assess.py PICT0004 PICT0005                      # specific stems
"""

import argparse
import sys
from pathlib import Path

from PIL import Image
import numpy as np

import slidelib as sl


def resolve_path(image_arg: str, source_dir: Path) -> Path:
    p = Path(image_arg)
    if p.suffix.upper() in ('.JPG', '.JPEG') and p.exists():
        return p
    stem  = p.stem if p.suffix else image_arg
    p_jpg = source_dir / f'{stem}.JPG'
    if p_jpg.exists():
        return p_jpg
    print(f'Image not found: {image_arg}')
    sys.exit(1)


def assess_local(img_path: Path, defaults: dict) -> dict:
    """Assess an image using local channel-ratio analysis only."""
    arr  = np.array(Image.open(img_path).convert('RGB'), dtype=np.uint8)
    arr  = sl.prepare(arr,
                      rotate=defaults.get('rotate', 0),
                      trim=defaults.get('trim', 0))
    profile = sl.auto_profile(arr)
    return {
        'profile': profile,
        'rotate':  defaults.get('rotate', 0),
        'trim':    defaults.get('trim', 8),
        '_notes':  f'Auto-detected locally: {profile}',
    }


def process_one(img_path: Path, cfg: dict, dry_run: bool,
                force: bool = False) -> None:
    stem = img_path.stem
    print(f'\n{stem}  ({img_path.name})')

    entry = assess_local(img_path, cfg.get('defaults', {}))

    # When re-assessing an existing entry, keep fields the user set manually:
    # rotation (may have been hand-corrected) and user notes.
    existing = cfg['images'].get(stem, {})
    if force and existing:
        if 'rotate' in existing:
            entry['rotate'] = existing['rotate']
        if '_user_notes' in existing:
            entry['_user_notes'] = existing['_user_notes']
        if '_description' in existing:
            entry['_description'] = existing['_description']

    print(f'  profile: {entry["profile"]}')
    if entry.get('rotate'):
        print(f'  rotate:  {entry["rotate"]}  (preserved from existing config)')

    if dry_run:
        print('  [dry-run] not saved')
        return

    cfg['images'][stem] = entry
    sl.save_configs(cfg)
    print(f'  saved to configs.json')


def main():
    parser = argparse.ArgumentParser(
        description='Locally assess slides and populate configs.json')
    parser.add_argument('images', nargs='*',
                        help='Stem names or full JPEG paths to assess')
    parser.add_argument('--source', type=Path, default=sl.DEFAULT_SOURCE,
                        help='Directory containing source JPEGs')
    parser.add_argument('--all', action='store_true',
                        help='Assess every JPEG in source dir not already in configs.json')
    parser.add_argument('--force', action='store_true',
                        help='Re-assess even images already in configs.json')
    parser.add_argument('--dry-run', action='store_true',
                        help='Print assessment without writing to configs.json')
    args = parser.parse_args()

    cfg = sl.load_configs()

    if args.images:
        paths = [resolve_path(img, args.source) for img in args.images]
    elif args.all:
        if not args.source.exists():
            print(f'Source directory not found: {args.source}')
            sys.exit(1)
        paths = sorted(args.source.glob('*.JPG'))
        if not args.force:
            paths = [p for p in paths if p.stem not in cfg['images']]
        if not paths:
            print('No new images to assess.')
            return
    else:
        parser.print_help()
        sys.exit(0)

    print(f'{len(paths)} image(s)  [local analysis]')

    for img_path in paths:
        if not args.force and img_path.stem in cfg['images']:
            print(f'\n{img_path.stem}  already in configs.json (use --force to re-assess)')
            continue
        process_one(img_path, cfg, args.dry_run, force=args.force)
        if not args.dry_run:
            cfg = sl.load_configs()

    print('\nDone.')


if __name__ == '__main__':
    main()
