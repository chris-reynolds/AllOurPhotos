"""Shared utilities for slide restoration scripts."""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

try:
    import rawpy
    HAS_RAWPY = True
except ImportError:
    HAS_RAWPY = False

HERE           = Path(__file__).parent
CONFIGS_PATH   = HERE / 'configs.json'
DEFAULT_SOURCE = HERE / 'original'
RESTORED       = HERE / 'restored'

# degrees clockwise -> np.rot90 k (counter-clockwise steps)
ROTATE_MAP = {0: 0, 90: 3, 180: 2, 270: 1}


def load_configs():
    with open(CONFIGS_PATH) as f:
        return json.load(f)


def load_source(stem, source_dir, raw_bright=1.0, use_jpeg=False):
    """Return (uint8 RGB array, source filename) or (None, None)."""
    orf = source_dir / f'{stem}.ORF'
    jpg = source_dir / f'{stem}.JPG'

    if not use_jpeg and HAS_RAWPY and orf.exists():
        with rawpy.imread(str(orf)) as raw:
            arr = raw.postprocess(use_camera_wb=True, bright=raw_bright,
                                  no_auto_bright=False, output_bps=8)
        return arr, f'{orf.name} (bright={raw_bright})'

    if not use_jpeg and not HAS_RAWPY and orf.exists():
        print('  [note] rawpy not installed, using JPEG instead of ORF')

    if jpg.exists():
        return np.array(Image.open(jpg).convert('RGB'), dtype=np.uint8), jpg.name

    return None, None


def levels_stretch(f):
    """Stretch each channel so 2nd-98th percentile spans 0-255."""
    out = f.copy()
    for ch in range(3):
        lo = np.percentile(out[:, :, ch], 2)
        hi = np.percentile(out[:, :, ch], 98)
        if hi > lo:
            out[:, :, ch] = (out[:, :, ch] - lo) / (hi - lo) * 255.0
    return np.clip(out, 0, 255)


def shadow_lift(arr_f32, stops):
    """
    Lift shadow tones by `stops` EV while leaving highlights unchanged.

    Uses a shadow-weighted blend between the original and a gamma-lifted
    version.  At 1 stop, dark pixels roughly double in brightness; pixels
    above ~70% brightness are barely touched.

    Typical values:
        1.0  mild indoor flash (background 1 stop under)
        2.0  heavy indoor flash (background 2 stops under)
    """
    if stops == 0:
        return arr_f32
    f = arr_f32 / 255.0
    gamma  = 2.0 ** (-stops)          # <1 brightens; 1 stop -> gamma=0.5
    lifted = np.power(np.clip(f, 1e-6, 1.0), gamma)
    weight = (1.0 - f) ** 1.5         # 1.0 at black, 0.0 at white
    result = weight * lifted + (1.0 - weight) * f
    return np.clip(result, 0.0, 1.0) * 255.0


def apply_correction(arr, params):
    """
    Apply colour correction described by a profile params dict.

    params keys:
        lift  bool  — per-channel black-point lift before scaling
        r/g/b float — per-channel multipliers (default 1.0)
        hdr   float — shadow lift in EV stops after levels stretch (default 0)
    Always includes a levels stretch; shadow lift (if any) is applied last.
    """
    out = arr.astype(np.float32)

    if params.get('lift', False):
        for ch in range(3):
            lo = np.percentile(out[:, :, ch], 2)
            out[:, :, ch] = np.clip(out[:, :, ch] - lo, 0, 255)

    out[:, :, 0] = np.clip(out[:, :, 0] * params.get('r', 1.0), 0, 255)
    out[:, :, 1] = np.clip(out[:, :, 1] * params.get('g', 1.0), 0, 255)
    out[:, :, 2] = np.clip(out[:, :, 2] * params.get('b', 1.0), 0, 255)

    out = levels_stretch(out)

    hdr_stops = params.get('hdr', 0)
    if hdr_stops:
        out = shadow_lift(out, hdr_stops)

    return out


def auto_profile(arr):
    """
    Analyse channel balance and return the most suitable profile name.

    Decision tree (after a quick levels normalisation so brightness
    differences don't swamp the ratios):
        b/r > 2.0                         -> ektachrome_faded
        b/r > 1.4                         -> slide_cool
        r/b > 1.5  AND low contrast       -> dixons_washed
        r/b > 1.3                         -> slide_warm
        otherwise                         -> agfachrome
    """
    f = arr.astype(np.float32)
    r = f[:, :, 0].mean()
    b = f[:, :, 2].mean()
    gray = f.mean(axis=2)
    contrast = gray.std() / (gray.mean() + 1.0)
    b_dom = b / (r + 1.0)
    r_dom = r / (b + 1.0)

    if b_dom > 2.0:
        return 'ektachrome_faded'
    if b_dom > 1.4:
        return 'slide_cool'
    if r_dom > 1.5 and contrast < 0.25:
        return 'dixons_washed'
    if r_dom > 1.3:
        return 'slide_warm'
    return 'agfachrome'


def prepare(arr, rotate=0, trim=0, crop_box=None):
    """Rotate (clockwise degrees), then trim edges or apply crop_box."""
    k = ROTATE_MAP.get(rotate, 0)
    if k:
        arr = np.rot90(arr, k=k).copy()
    if crop_box:
        r0, c0, r1, c1 = crop_box
        arr = arr[r0:r1, c0:c1]
    elif trim:
        arr = arr[trim:-trim, trim:-trim]
    return arr


def ev_adjust(arr_f32, ev):
    """Apply EV (exposure value) shift. +1 EV = 2× brighter, -1 = half."""
    if ev == 0:
        return arr_f32
    return np.clip(arr_f32 * (2.0 ** ev), 0.0, 255.0)


def anneal_blue_spots(pil_img, min_b=80, b_offset=60, blur_radius=3):
    """
    Replace blue emulsion damage spots with surrounding pixel colour.

    Detection: pixels where B > min_b AND B > R+b_offset AND B > G+b_offset.
    Using absolute offsets rather than ratios so spots on green (grass) or
    other saturated areas are still detected.
    Fill: Gaussian blur of the valid (non-blue) pixels, normalised by the
    blurred valid-pixel density, so only non-damaged pixels contribute.
    Small noise added so fills don't look artificially smooth.
    """
    arr = np.array(pil_img, dtype=np.float32)
    b, r, g = arr[:, :, 2], arr[:, :, 0], arr[:, :, 1]

    mask = (b > min_b) & ((b - r) > b_offset) & ((b - g) > b_offset)
    if not mask.any():
        return pil_img

    # Dilate mask a few pixels to catch edge fringing
    mask_pil = Image.fromarray((mask * 255).astype(np.uint8))
    mask_pil = mask_pil.filter(ImageFilter.MaxFilter(3))
    mask = np.array(mask_pil) > 128

    valid = (~mask).astype(np.float32)
    valid_blur = np.array(
        Image.fromarray((valid * 255).astype(np.uint8))
            .filter(ImageFilter.GaussianBlur(blur_radius)),
        dtype=np.float32,
    ) / 255.0

    result = arr.copy()
    rng = np.random.default_rng(0)
    for ch in range(3):
        ch_valid = arr[:, :, ch] * valid
        ch_blur = np.array(
            Image.fromarray(np.clip(ch_valid, 0, 255).astype(np.uint8))
                .filter(ImageFilter.GaussianBlur(blur_radius)),
            dtype=np.float32,
        )
        fill = np.where(valid_blur > 0.05, ch_blur / valid_blur, arr[:, :, ch])
        fill += rng.normal(0, 4, fill.shape)   # texture noise
        result[:, :, ch] = np.where(mask, fill, arr[:, :, ch])

    return Image.fromarray(result.clip(0, 255).astype(np.uint8))


def save_configs(cfg):
    """Write configs.json atomically (temp file then rename)."""
    tmp = CONFIGS_PATH.with_suffix('.tmp')
    with open(tmp, 'w') as f:
        json.dump(cfg, f, indent=4)
    tmp.replace(CONFIGS_PATH)


def sharpen(pil_img, params):
    """Unsharp mask sharpening using params from configs.json['sharpen']."""
    return pil_img.filter(ImageFilter.UnsharpMask(
        radius=params.get('radius', 1.5),
        percent=params.get('percent', 150),
        threshold=params.get('threshold', 3),
    ))
