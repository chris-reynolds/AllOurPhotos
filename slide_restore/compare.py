#!/usr/bin/env python3
"""
Apply every colour profile to one slide scan and output a contact sheet.
Useful for choosing the right profile before committing to restore.py.

Usage:
    python compare.py PICT0002                              # stem in original/
    python compare.py D:\\DCIM\\100COACH\\PICT0002.JPG     # full path
    python compare.py PICT0001 --source D:\\DCIM\\100COACH
    python compare.py PICT0001 --rotate 90 --trim 8

    # HDR comparison: shows auto-detected profile at 0, 1 and 2 stops of
    # shadow lift, side by side.  Use this when you know the photo is an
    # indoor flash shot and want to decide how much lift it needs.
    python compare.py PICT0003 --hdr

Output:
    restored/<stem>_compare.jpg      one panel per profile
    restored/<stem>_hdr_compare.jpg  three-panel shadow lift comparison (--hdr)
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import slidelib as sl

CELL_WIDTH   = 700
LABEL_HEIGHT = 40
COLS         = 3


def make_contact_sheet(panels, output_path):
    """
    panels: list of (label_str, PIL.Image)
    All cells are scaled to CELL_WIDTH wide, preserving aspect ratio.
    """
    w0, h0 = panels[0][1].size
    cell_h = int(h0 * CELL_WIDTH / w0)

    rows    = (len(panels) + COLS - 1) // COLS
    sheet_w = COLS * CELL_WIDTH
    sheet_h = rows * (cell_h + LABEL_HEIGHT)
    sheet   = Image.new('RGB', (sheet_w, sheet_h), (24, 24, 24))

    try:
        font = ImageFont.load_default(size=22)
    except TypeError:
        font = ImageFont.load_default()

    draw = ImageDraw.Draw(sheet)

    for i, (label, img) in enumerate(panels):
        col = i % COLS
        row = i // COLS
        x   = col * CELL_WIDTH
        y   = row * (cell_h + LABEL_HEIGHT)

        sheet.paste(img.resize((CELL_WIDTH, cell_h), Image.LANCZOS), (x, y))

        bar_y = y + cell_h
        draw.rectangle([x, bar_y, x + CELL_WIDTH - 1, bar_y + LABEL_HEIGHT - 1],
                       fill=(24, 24, 24))
        draw.text((x + 10, bar_y + 9), label, fill=(210, 210, 210), font=font)

    sheet.save(str(output_path), quality=92)
    return sheet_w, sheet_h


def resolve_image(image_arg, source_dir):
    """Return (Path to JPEG, stem string)."""
    p = Path(image_arg)
    if p.suffix.upper() in ('.JPG', '.JPEG') and p.exists():
        return p, p.stem
    stem  = p.stem if p.suffix else image_arg
    p_jpg = source_dir / f'{stem}.JPG'
    if not p_jpg.exists():
        # Also try original/ as a last resort
        p_jpg = sl.DEFAULT_SOURCE / f'{stem}.JPG'
    if not p_jpg.exists():
        print(f'Image not found: {image_arg}')
        sys.exit(1)
    return p_jpg, stem


def main():
    parser = argparse.ArgumentParser(description='Compare profiles or HDR levels on one slide')
    parser.add_argument('image',
                        help='Stem name (e.g. PICT0003) or full path to JPEG')
    parser.add_argument('--source', type=Path, default=sl.DEFAULT_SOURCE,
                        help='Directory to look in when only a stem is given')
    parser.add_argument('--rotate', type=int, default=None,
                        help='Override rotation in degrees clockwise')
    parser.add_argument('--trim',   type=int, default=None,
                        help='Override edge trim in pixels')
    parser.add_argument('--hdr', action='store_true',
                        help='HDR mode: show auto-detected profile at 0, 1 and 2 stops of shadow lift')
    args = parser.parse_args()

    cfg      = sl.load_configs()
    defaults = cfg.get('defaults', {})

    img_path, stem = resolve_image(args.image, args.source if args.source.exists() else sl.DEFAULT_SOURCE)
    arr = np.array(Image.open(img_path).convert('RGB'), dtype=np.uint8)

    # Rotation / trim: CLI arg > configs.json entry > defaults
    img_cfg = cfg['images'].get(stem, {})
    rotate  = args.rotate if args.rotate is not None else img_cfg.get('rotate', defaults.get('rotate', 0))
    trim    = args.trim   if args.trim   is not None else img_cfg.get('trim',   defaults.get('trim', 0))
    arr     = sl.prepare(arr, rotate=rotate, trim=trim)

    detected = sl.auto_profile(arr)
    print(f'Auto-detected profile: {detected}')

    sl.RESTORED.mkdir(exist_ok=True)

    if args.hdr:
        # ── HDR comparison ────────────────────────────────────────────────────
        # Show the auto-detected profile at 0, 1, and 2 stops of shadow lift.
        base_params = dict(cfg['profiles'].get(detected, {}))
        panels = []
        for stops in (0, 1, 2):
            p = {**base_params, 'hdr': stops}
            result = sl.apply_correction(arr, p).astype('uint8')
            label  = f'{detected}  +{stops} stop{"s" if stops != 1 else ""} HDR'
            if stops == 0:
                label = f'{detected}  (no HDR)'
            panels.append((label, Image.fromarray(result)))

        out = sl.RESTORED / f'{stem}_hdr_compare.jpg'
        w, h = make_contact_sheet(panels, out)
        print(f'HDR contact sheet -> {out.name}  ({w}x{h}px)')
        print(f'To apply: add "hdr": 1.0 or "hdr": 2.0 to the image entry in configs.json')

    else:
        # ── Profile comparison ─────────────────────────────────────────────────
        panels = [('original (no correction)', Image.fromarray(arr))]
        for name, params in cfg['profiles'].items():
            result = sl.apply_correction(arr, params).astype('uint8')
            label  = f'{name}  <-- auto' if name == detected else name
            panels.append((label, Image.fromarray(result)))

        out = sl.RESTORED / f'{stem}_compare.jpg'
        w, h = make_contact_sheet(panels, out)
        print(f'Profile contact sheet -> {out.name}  ({w}x{h}px, {len(panels)} panels)')


if __name__ == '__main__':
    main()
