#!/usr/bin/env python3
"""
Before/after slide viewer with live profile switching, HDR/sharpen toggles,
and an in-browser compare grid (replaces compare.py).

python viewer.py              # http://localhost:8000, opens browser
python viewer.py --port 8080
python viewer.py --no-browser
"""

import argparse
import json
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from io import BytesIO
from pathlib import Path
from socketserver import ThreadingMixIn
from urllib.parse import parse_qs, unquote, urlparse

import numpy as np
from PIL import Image

import slidelib as sl

# ─── Caches ──────────────────────────────────────────────────────────────────
_thumb_cache: dict = {}    # stem -> bytes (carousel thumbnails)
_prev_cache:  dict = {}    # (stem, profile, hdr, sharpen) -> bytes (live previews)

PREVIEW_WIDTH = 800        # px — preview scale for responsiveness


def make_thumb(stem: str) -> bytes:
    if stem in _thumb_cache:
        return _thumb_cache[stem]
    src = sl.RESTORED / f'{stem}_restored.jpg'
    if not src.exists():
        return b''
    img = Image.open(src).convert('RGB')
    img.thumbnail((200, 200), Image.LANCZOS)
    buf = BytesIO()
    img.save(buf, format='JPEG', quality=75)
    data = buf.getvalue()
    _thumb_cache[stem] = data
    return data


def process_preview(stem: str, profile: str, hdr: float, sharpen: bool,
                    raw: bool = False, ev: float = 0, anneal: bool = False) -> bytes:
    """Produce a PREVIEW_WIDTH-wide JPEG with the given correction applied.

    raw=True  — skips per-image r/g/b overrides (compare grid).
    ev        — final EV brightness shift applied after all corrections.
    anneal    — replace blue emulsion damage spots with nearby pixel colour.
    """
    key = (stem, profile, hdr, sharpen, raw, ev, anneal)
    if key in _prev_cache:
        return _prev_cache[key]

    src = sl.DEFAULT_SOURCE / f'{stem}.JPG'
    if not src.exists():
        return b''

    cfg = sl.load_configs()
    ic  = cfg['images'].get(stem, {})

    arr = np.array(Image.open(src).convert('RGB'), dtype=np.uint8)
    arr = sl.prepare(arr,
                     rotate=ic.get('rotate', cfg['defaults'].get('rotate', 0)),
                     trim=ic.get('trim',   cfg['defaults'].get('trim',   0)),
                     crop_box=ic.get('crop_box'))

    img = Image.fromarray(arr)
    img.thumbnail((PREVIEW_WIDTH, PREVIEW_WIDTH), Image.LANCZOS)
    arr = np.array(img, dtype=np.uint8)

    if profile == '_original':
        out = arr.astype(np.float32)
        if hdr > 0:
            out = sl.shadow_lift(out, hdr)
        if ev != 0:
            out = sl.ev_adjust(out, ev)
        img_out = Image.fromarray(out.clip(0, 255).astype(np.uint8))
        if sharpen:
            img_out = sl.sharpen(img_out, cfg.get('sharpen', {}))
    else:
        params = dict(cfg['profiles'].get(profile, {}))
        if not raw:
            for ch in ('r', 'g', 'b'):   # per-image channel overrides
                if ch in ic:
                    params[ch] = ic[ch]
        if hdr > 0:
            params['hdr'] = hdr
        else:
            params.pop('hdr', None)
        result = sl.apply_correction(arr, params)
        if ev != 0:
            result = sl.ev_adjust(result, ev)
        img_out = Image.fromarray(result.clip(0, 255).astype(np.uint8))
        if sharpen:
            img_out = sl.sharpen(img_out, cfg.get('sharpen', {}))

    if anneal:
        img_out = sl.anneal_blue_spots(img_out)

    buf = BytesIO()
    img_out.save(buf, format='JPEG', quality=88)
    data = buf.getvalue()
    _prev_cache[key] = data
    return data


def invalidate(stem: str) -> None:
    for k in [k for k in _prev_cache if k[0] == stem]:
        del _prev_cache[k]
    _thumb_cache.pop(stem, None)


# ─── Embedded HTML/CSS/JS viewer ─────────────────────────────────────────────

VIEWER_HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Slide Viewer</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: #181818; color: #ddd; font-family: system-ui,sans-serif;
       height: 100vh; display: flex; flex-direction: column; overflow: hidden; }

/* ── Header ── */
#hdr { display: flex; align-items: center; flex-wrap: wrap; gap: 8px 14px;
       padding: 7px 14px; background: #232323; border-bottom: 1px solid #333;
       flex-shrink: 0; }
#stem  { font-weight: 600; font-size: 1.05em; min-width: 80px; }
#prof-sel, #hdr-sel { padding: 4px 8px; background: #2c2c2c; border: 1px solid #464646;
            color: #ddd; border-radius: 4px; font-size: 0.82em; cursor: pointer; }
.ck-wrap { display: flex; align-items: center; gap: 5px; font-size: 0.82em;
           cursor: pointer; user-select: none; color: #bbb; }
.ck-wrap input[type="checkbox"] { accent-color: #2a7adf; width: 15px; height: 15px; cursor: pointer; }
#ev-sl  { width: 72px; accent-color: #2a7adf; cursor: pointer; }
#ev-val { min-width: 30px; color: #aaa; }
.gap   { flex: 1; }
.btn   { padding: 5px 12px; border: 1px solid #484848; background: #2c2c2c;
         color: #ccc; cursor: pointer; border-radius: 4px; font-size: 0.82em; }
.btn:hover { background: #383838; }
.btn.on    { background: #1c538e; border-color: #2d78cc; color: #fff; }
.btn.dirty { border-color: #c07820; color: #e09030; }
#hint { color: #3e3e3e; font-size: 0.74em; white-space: nowrap; }

/* ── Comparison area ── */
#comp { flex: 1; min-height: 0; position: relative; background: #111; }

/* Split */
#split { width: 100%; height: 100%; display: flex; }
.half  { flex: 1; position: relative; overflow: hidden; }
.half img { width: 100%; height: 100%; object-fit: contain; display: block; }
.lbl  { position: absolute; top: 7px; left: 7px; background: rgba(0,0,0,.62);
        padding: 3px 9px; border-radius: 3px; font-size: 0.76em; pointer-events: none; }
.gut  { width: 3px; background: #2a2a2a; flex-shrink: 0; }

/* Slider */
#slider { width: 100%; height: 100%; position: relative; overflow: hidden;
          cursor: ew-resize; user-select: none; display: none; }
#sl-a { width: 100%; height: 100%; object-fit: contain; display: block; }
#sl-b { position: absolute; inset: 0; width: 100%; height: 100%;
        object-fit: contain; clip-path: inset(0 50% 0 0); }
#slider img { pointer-events: none; }
#sl-bar { position: absolute; top: 0; bottom: 0; left: 50%; width: 2px;
          background: #fff; transform: translateX(-50%); pointer-events: none;
          box-shadow: 0 0 6px rgba(0,0,0,.7); }
#sl-knob { position: absolute; top: 50%; left: 50%;
           transform: translate(-50%,-50%); width: 32px; height: 32px;
           border-radius: 50%; background: #fff; color: #333; font-size: 10px;
           font-weight: 700; display: flex; align-items: center; justify-content: center;
           box-shadow: 0 1px 5px rgba(0,0,0,.6); }
.sl-lbl { position: absolute; bottom: 8px; background: rgba(0,0,0,.62);
          padding: 3px 9px; border-radius: 3px; font-size: 0.76em; pointer-events: none; }

/* Compare / HDR grids */
#cmp-grid, #hdr-grid { display: none; width: 100%; height: 100%; overflow-y: auto;
            padding: 10px; gap: 8px;
            grid-template-columns: repeat(3, 1fr); }
.cc { position: relative; cursor: pointer; border: 2px solid transparent;
      border-radius: 4px; overflow: hidden; background: #1c1c1c; }
.cc:hover { border-color: #555; }
.cc.on    { border-color: #1c538e; }
.cc img   { width: 100%; display: block; object-fit: contain; }
.cc-name  { position: absolute; bottom: 0; left: 0; right: 0;
             background: rgba(0,0,0,.72); padding: 4px 8px; font-size: 0.76em; }
.cc-spin  { position: absolute; inset: 0; display: flex; align-items: center;
             justify-content: center; color: #555; font-size: 0.8em; }

/* Notes */
#notes { background: #1c1c1c; border-top: 1px solid #2c2c2c;
         padding: 10px 14px; display: flex; gap: 14px;
         flex-shrink: 0; height: 144px; }
#ai    { flex: 1; min-width: 0; overflow-y: auto; }
#ai-d  { font-size: 0.86em; color: #bbb; font-weight: 500; margin-bottom: 3px; }
#ai-n  { font-size: 0.77em; color: #666; line-height: 1.45; }
#ucol  { width: 300px; flex-shrink: 0; display: flex; flex-direction: column; gap: 5px; }
#ulbl  { font-size: 0.78em; color: #777; display: flex; align-items: center; gap: 8px; }
#ndirty { color: #c07820; display: none; }
#unotes { flex: 1; background: #252525; border: 1px solid #3c3c3c; color: #d8d8d8;
          padding: 6px 8px; border-radius: 4px; resize: none; font-size: 0.82em;
          font-family: inherit; }
#unotes:focus { outline: none; border-color: #2d78cc; }
#nsave { align-self: flex-end; }

/* Carousel */
#car { background: #0f0f0f; border-top: 1px solid #252525; padding: 6px 8px;
       overflow-x: auto; display: flex; gap: 5px; height: 82px;
       align-items: center; flex-shrink: 0; }
#car::-webkit-scrollbar { height: 4px; }
#car::-webkit-scrollbar-thumb { background: #3a3a3a; border-radius: 2px; }
.th { flex-shrink: 0; width: 112px; height: 68px; position: relative;
      cursor: pointer; border: 2px solid transparent; border-radius: 3px; overflow: hidden; }
.th:hover { border-color: #555; }
.th.on    { border-color: #1c538e; }
.th img   { width: 100%; height: 100%; object-fit: cover; display: block; }
.th-n     { position: absolute; bottom: 0; left: 0; right: 0;
             background: rgba(0,0,0,.72); font-size: 9px; text-align: center;
             padding: 1px 0; color: #999; }
.th.noted::after { content:''; position: absolute; top: 3px; right: 3px;
                   width: 6px; height: 6px; border-radius: 50%; background: #3a9a4a; }
</style>
</head>
<body>

<div id="hdr">
  <span id="stem">Loading...</span>
  <select id="prof-sel" onchange="onProfileChange()"></select>
  <select id="hdr-sel" onchange="onSettingChange()">
    <option value="0">HDR: off</option>
    <option value="1">+1 stop</option>
    <option value="2">+2 stops</option>
  </select>
  <label class="ck-wrap" id="ev-wrap">
    EV
    <input type="range" id="ev-sl" min="-2" max="2" step="0.25" value="0" oninput="onEvChange()">
    <span id="ev-val">0</span>
  </label>
  <label class="ck-wrap" id="shr-wrap">
    <input type="checkbox" id="ck-shr" onchange="onSettingChange()">
    Sharpen
  </label>
  <button class="btn" id="anneal-btn" onclick="toggleAnneal()">Anneal spots</button>
  <button class="btn" id="save-btn" onclick="saveSettings()">Save settings</button>
  <span class="gap"></span>
  <button class="btn on"  id="b-split"   onclick="setMode('split')">Split</button>
  <button class="btn"     id="b-slider"  onclick="setMode('slider')">Slider</button>
  <button class="btn"     id="b-compare" onclick="setMode('compare')">Compare</button>
  <button class="btn"     id="b-hdr"     onclick="setMode('hdr')">HDR</button>
  <span id="hint">&#8592; &#8594; &nbsp; S toggle</span>
</div>

<div id="comp">
  <div id="split">
    <div class="half"><img id="sp-b" src=""><div class="lbl">Before</div></div>
    <div class="gut"></div>
    <div class="half"><img id="sp-a" src=""><div class="lbl">After</div></div>
  </div>

  <div id="slider">
    <img id="sl-a" src="">
    <img id="sl-b" src="">
    <div id="sl-bar"><div id="sl-knob">&#9664;&#9654;</div></div>
    <div class="sl-lbl" style="left:8px">Before</div>
    <div class="sl-lbl" style="right:8px">After</div>
  </div>

  <div id="cmp-grid"></div>
  <div id="hdr-grid"></div>
</div>

<div id="notes">
  <div id="ai"><div id="ai-d"></div><div id="ai-n"></div></div>
  <div id="ucol">
    <div id="ulbl">Your notes <span id="ndirty">&#9679; unsaved</span></div>
    <textarea id="unotes" placeholder="Notes for next correction pass..."></textarea>
    <button class="btn" id="nsave" onclick="saveNotes()">Save notes</button>
  </div>
</div>

<div id="car"></div>

<script>
// ── State ──────────────────────────────────────────────────────────────────
let imgs = [], profiles = {}, idx = 0;
let mode = 'split', slPct = 50, drag = false;
let cur = {profile:'', hdr:0, ev:0, sharpen:false, anneal:false};  // currently shown
let saved = {profile:'', hdr:0, ev:0, sharpen:false, anneal:false}; // last saved
let sdirty = false, ndirty = false;

// ── Init ───────────────────────────────────────────────────────────────────
async function init() {
    [imgs, profiles] = await Promise.all([
        fetch('/api/images').then(r => r.json()),
        fetch('/api/profiles').then(r => r.json()),
    ]);

    // Populate profile dropdown
    const sel = document.getElementById('prof-sel');
    const origOpt = document.createElement('option');
    origOpt.value = '_original';
    origOpt.textContent = 'original (no correction)';
    sel.appendChild(origOpt);
    Object.entries(profiles).forEach(([name, p]) => {
        const o = document.createElement('option');
        o.value = name;
        o.textContent = name;
        sel.appendChild(o);
    });

    // Build carousel
    const car = document.getElementById('car');
    imgs.forEach((img, i) => {
        const d = document.createElement('div');
        d.className = 'th' + (img.user_notes ? ' noted' : '');
        d.id = 'th' + i;
        d.onclick = () => go(i);
        d.innerHTML = `<img src="/img/thumb/${img.stem}" loading="lazy">
                       <div class="th-n">${img.stem.slice(-4)}</div>`;
        car.appendChild(d);
    });

    go(0);
}

// ── Navigation ─────────────────────────────────────────────────────────────
function go(i) {
    idx = i;
    const m = imgs[i];

    document.getElementById('stem').textContent = m.stem;
    document.getElementById('ai-d').textContent  = m.description || '';
    document.getElementById('ai-n').textContent  = m.notes || '';
    document.getElementById('unotes').value = m.user_notes || '';
    setNDirty(false);

    // Restore saved settings for this image
    saved = { profile: m.profile || Object.keys(profiles)[0],
              hdr:     Math.round(m.hdr || 0),
              ev:      m.ev || 0,
              sharpen: !!m.sharpen,
              anneal:  !!m.anneal };
    cur   = { ...saved };
    applySettingsToUI();
    setSdirty(false);

    loadBeforeImages();
    loadAfterImage();

    document.querySelectorAll('.th').forEach((t,j) => t.classList.toggle('on', j===i));
    document.getElementById('th'+i).scrollIntoView({inline:'nearest', behavior:'smooth'});

    if (mode === 'compare') renderCompareGrid();
}

// ── Image loading ──────────────────────────────────────────────────────────
function loadBeforeImages() {
    const url = previewUrl(imgs[idx].stem, '_original', 0, false);
    document.getElementById('sp-b').src = url;
    document.getElementById('sl-b').src = url;
}

function loadAfterImage() {
    const url = previewUrl(imgs[idx].stem, cur.profile, cur.hdr, cur.sharpen, false, cur.ev, cur.anneal);
    document.getElementById('sp-a').src = url;
    document.getElementById('sl-a').src = url;
}

function previewUrl(stem, profile, hdr, sharpen, raw=false, ev=0, anneal=false) {
    return `/img/preview/${stem}?profile=${encodeURIComponent(profile)}`
         + `&hdr=${hdr}&sharpen=${sharpen ? '1' : '0'}${raw ? '&raw=1' : ''}`
         + `&ev=${ev}&anneal=${anneal ? '1' : '0'}`;
}

// ── Settings controls ──────────────────────────────────────────────────────
function applySettingsToUI() {
    document.getElementById('prof-sel').value = cur.profile;
    document.getElementById('hdr-sel').value  = cur.hdr;
    document.getElementById('ev-sl').value    = cur.ev;
    document.getElementById('ev-val').textContent = fmtEv(cur.ev);
    document.getElementById('ck-shr').checked = cur.sharpen;
    document.getElementById('anneal-btn').classList.toggle('on', cur.anneal);
}

function fmtEv(v) { return v === 0 ? '0' : (v > 0 ? '+' : '') + v; }

function isDirty() {
    return cur.profile !== saved.profile ||
           cur.hdr     !== saved.hdr     ||
           cur.ev      !== saved.ev      ||
           cur.sharpen !== saved.sharpen ||
           cur.anneal  !== saved.anneal;
}

function onProfileChange() {
    cur.profile = document.getElementById('prof-sel').value;
    onSettingChange();
}

function onSettingChange() {
    cur.hdr     = parseInt(document.getElementById('hdr-sel').value, 10);
    cur.sharpen = document.getElementById('ck-shr').checked;
    if (document.getElementById('prof-sel').value !== cur.profile)
        cur.profile = document.getElementById('prof-sel').value;
    setSdirty(isDirty());
    if (mode === 'hdr') renderHdrGrid();
    else loadAfterImage();
}

function onEvChange() {
    cur.ev = parseFloat(document.getElementById('ev-sl').value);
    document.getElementById('ev-val').textContent = fmtEv(cur.ev);
    setSdirty(isDirty());
    if (mode === 'hdr') renderHdrGrid();
    else loadAfterImage();
}

function toggleAnneal() {
    cur.anneal = !cur.anneal;
    document.getElementById('anneal-btn').classList.toggle('on', cur.anneal);
    setSdirty(isDirty());
    loadAfterImage();
}

function setSdirty(v) {
    sdirty = v;
    document.getElementById('save-btn').classList.toggle('dirty', v);
    document.getElementById('save-btn').textContent = v ? 'Save settings *' : 'Save settings';
}

async function saveSettings() {
    const stem = imgs[idx].stem;
    await fetch('/api/settings/' + stem, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            profile: cur.profile,
            hdr:     cur.hdr,
            ev:      cur.ev,
            sharpen: cur.sharpen,
            anneal:  cur.anneal,
        })
    });
    saved = { ...cur };
    imgs[idx].profile = cur.profile;
    imgs[idx].hdr     = cur.hdr;
    imgs[idx].ev      = cur.ev;
    imgs[idx].sharpen = cur.sharpen;
    setSdirty(false);
    flashBtn('save-btn', 'Saved!');
}

// ── Compare grid ───────────────────────────────────────────────────────────
function renderCompareGrid() {
    const stem = imgs[idx].stem;
    const grid = document.getElementById('cmp-grid');
    grid.innerHTML = '';

    const entries = [['_original', 'original (no correction)'],
                     ...Object.entries(profiles).map(([n]) => [n, n])];

    entries.forEach(([pname, label]) => {
        const cell = document.createElement('div');
        cell.className = 'cc' + (pname === cur.profile ? ' on' : '');

        const isOrig = pname === '_original';
        const url    = previewUrl(stem, pname, 0, false, true);
        cell.innerHTML =
            `<div class="cc-spin">loading...</div>
             <img src="${url}" style="display:none"
                  onload="this.previousElementSibling.style.display='none';this.style.display='block'">
             <div class="cc-name">${label}${pname===cur.profile?' &#10003;':''}</div>`;

        if (!isOrig) {
            cell.addEventListener('click', () => {
                cur.profile = pname;
                applySettingsToUI();
                setSdirty(cur.profile !== saved.profile ||
                          cur.hdr     !== saved.hdr     ||
                          cur.sharpen !== saved.sharpen);
                setMode('split');
                loadAfterImage();
            });
        }
        grid.appendChild(cell);
    });
}

// ── HDR compare grid ───────────────────────────────────────────────────────
function renderHdrGrid() {
    const stem    = imgs[idx].stem;
    const profile = cur.profile || Object.keys(profiles)[0];
    const grid    = document.getElementById('hdr-grid');
    grid.innerHTML = '';

    [0, 1, 2].forEach(stops => {
        const cell  = document.createElement('div');
        cell.className = 'cc' + (stops === cur.hdr ? ' on' : '');
        const label = stops === 0
            ? `${profile}  (no HDR)`
            : `${profile}  +${stops} stop${stops > 1 ? 's' : ''}`;
        const url = previewUrl(stem, profile, stops, false, false, cur.ev);
        cell.innerHTML =
            `<div class="cc-spin">loading...</div>
             <img src="${url}" style="display:none"
                  onload="this.previousElementSibling.style.display='none';this.style.display='block'">
             <div class="cc-name">${label}${stops===cur.hdr?' &#10003;':''}</div>`;
        cell.addEventListener('click', () => {
            cur.hdr = stops;
            applySettingsToUI();
            setSdirty(isDirty());
            setMode('split');
            loadAfterImage();
        });
        grid.appendChild(cell);
    });
}

// ── View modes ─────────────────────────────────────────────────────────────
function setMode(m) {
    mode = m;
    document.getElementById('split').style.display    = m==='split'   ? 'flex'  : 'none';
    document.getElementById('slider').style.display   = m==='slider'  ? 'block' : 'none';
    document.getElementById('cmp-grid').style.display = m==='compare' ? 'grid'  : 'none';
    document.getElementById('hdr-grid').style.display = m==='hdr'     ? 'grid'  : 'none';
    ['split','slider','compare','hdr'].forEach(n =>
        document.getElementById('b-'+n).classList.toggle('on', n===m));
    const inGrid = m === 'compare' || m === 'hdr';
    ['prof-sel','hdr-sel','ev-wrap','shr-wrap','anneal-btn','save-btn'].forEach(id =>
        document.getElementById(id).style.display = inGrid ? 'none' : '');
    if (m === 'compare') renderCompareGrid();
    if (m === 'hdr')     renderHdrGrid();
}

// ── Slider drag ────────────────────────────────────────────────────────────
const sv = document.getElementById('slider');
function moveSl(e) {
    if (!drag) return;
    const r = sv.getBoundingClientRect();
    slPct = Math.max(2, Math.min(98, (e.clientX-r.left)/r.width*100));
    document.getElementById('sl-b').style.clipPath = `inset(0 ${100-slPct}% 0 0)`;
    document.getElementById('sl-bar').style.left   = slPct + '%';
}
sv.addEventListener('mousedown',  e => { drag=true; moveSl(e); });
window.addEventListener('mousemove', moveSl);
window.addEventListener('mouseup', () => { drag=false; });
sv.addEventListener('touchstart', e => { drag=true; moveSl(e.touches[0]); }, {passive:true});
window.addEventListener('touchmove', e => { if(drag) moveSl(e.touches[0]); }, {passive:true});
window.addEventListener('touchend', () => { drag=false; });

// ── Notes ──────────────────────────────────────────────────────────────────
document.getElementById('unotes').addEventListener('input', () => setNDirty(true));
function setNDirty(v) {
    ndirty = v;
    document.getElementById('ndirty').style.display = v ? 'inline' : 'none';
}
async function saveNotes() {
    const stem  = imgs[idx].stem;
    const notes = document.getElementById('unotes').value;
    await fetch('/api/notes/' + stem, {
        method: 'POST', headers: {'Content-Type':'application/json'},
        body: JSON.stringify({notes})
    });
    imgs[idx].user_notes = notes;
    document.getElementById('th'+idx).classList.toggle('noted', !!notes);
    setNDirty(false);
    flashBtn('nsave', 'Saved!');
}

async function autoSave() {
    if (sdirty) await saveSettings();
    if (ndirty) await saveNotes();
}

// ── Keyboard ───────────────────────────────────────────────────────────────
document.addEventListener('keydown', e => {
    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
    if (e.key==='ArrowRight' && idx<imgs.length-1) go(idx+1);
    if (e.key==='ArrowLeft'  && idx>0)             go(idx-1);
    if (e.key==='s'||e.key==='S') {
        const cycle = ['split','slider','compare','hdr'];
        setMode(cycle[(cycle.indexOf(mode)+1) % cycle.length]);
    }
});

// ── Helpers ────────────────────────────────────────────────────────────────
function flashBtn(id, text) {
    const btn = document.getElementById(id);
    const orig = btn.textContent;
    btn.textContent = text;
    setTimeout(() => { btn.textContent = orig; }, 1500);
}

init();
</script>
</body>
</html>"""


# ─── HTTP handler ─────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        parsed = urlparse(self.path)
        path   = unquote(parsed.path)
        qs     = parse_qs(parsed.query)
        try:
            if path == '/':
                self._html()
            elif path == '/api/images':
                self._api_images()
            elif path == '/api/profiles':
                self._api_profiles()
            elif path.startswith('/img/original/'):
                self._file(sl.DEFAULT_SOURCE / f'{path[14:]}.JPG')
            elif path.startswith('/img/restored/'):
                self._file(sl.RESTORED / f'{path[14:]}_restored.jpg')
            elif path.startswith('/img/thumb/'):
                self._thumb(path[11:])
            elif path.startswith('/img/preview/'):
                self._preview(path[13:], qs)
            else:
                self.send_error(404)
        except Exception as exc:
            self.send_error(500, str(exc))

    def do_POST(self):
        path = unquote(urlparse(self.path).path)
        body = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))))
        try:
            if path.startswith('/api/notes/'):
                self._save_notes(path[11:], body)
            elif path.startswith('/api/settings/'):
                self._save_settings(path[14:], body)
            else:
                self.send_error(404)
        except Exception as exc:
            self.send_error(500, str(exc))

    # ── Route implementations ───────────────────────────────────────────────

    def _html(self):
        data = VIEWER_HTML.encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', len(data))
        self.end_headers()
        self.wfile.write(data)

    def _api_images(self):
        cfg = sl.load_configs()
        result = []
        for stem in sorted(cfg['images']):
            if not (sl.DEFAULT_SOURCE / f'{stem}.JPG').exists():
                continue
            ic = cfg['images'][stem]
            result.append({
                'stem':        stem,
                'profile':     ic.get('profile', ''),
                'hdr':         ic.get('hdr', 0),
                'ev':          ic.get('ev', 0),
                'sharpen':     ic.get('sharpen', False),
                'anneal':      ic.get('anneal', False),
                'description': ic.get('_description', ''),
                'notes':       ic.get('_notes', ''),
                'user_notes':  ic.get('_user_notes', ''),
            })
        self._json(result)

    def _api_profiles(self):
        cfg = sl.load_configs()
        self._json(cfg.get('profiles', {}))

    def _file(self, path: Path):
        if not path.exists():
            self.send_error(404)
            return
        data = path.read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', 'image/jpeg')
        self.send_header('Content-Length', len(data))
        self.send_header('Cache-Control', 'max-age=3600')
        self.end_headers()
        self.wfile.write(data)

    def _thumb(self, stem: str):
        data = make_thumb(stem)
        if not data:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header('Content-Type', 'image/jpeg')
        self.send_header('Content-Length', len(data))
        self.send_header('Cache-Control', 'max-age=3600')
        self.end_headers()
        self.wfile.write(data)

    def _preview(self, stem: str, qs: dict):
        profile = qs.get('profile', ['agfachrome'])[0]
        hdr     = float(qs.get('hdr',     ['0'])[0])
        sharpen = qs.get('sharpen', ['0'])[0] == '1'
        raw     = qs.get('raw',     ['0'])[0] == '1'
        ev      = float(qs.get('ev',      ['0'])[0])
        anneal  = qs.get('anneal',  ['0'])[0] == '1'
        data    = process_preview(stem, profile, hdr, sharpen, raw, ev, anneal)
        if not data:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header('Content-Type', 'image/jpeg')
        self.send_header('Content-Length', len(data))
        # No long cache — settings may change
        self.send_header('Cache-Control', 'max-age=60')
        self.end_headers()
        self.wfile.write(data)

    def _save_notes(self, stem: str, body: dict):
        cfg = sl.load_configs()
        if stem in cfg['images']:
            cfg['images'][stem]['_user_notes'] = body.get('notes', '')
            sl.save_configs(cfg)
        self._json({'ok': True})

    def _save_settings(self, stem: str, body: dict):
        cfg = sl.load_configs()
        if stem not in cfg['images']:
            cfg['images'][stem] = {
                'trim':   cfg['defaults'].get('trim', 8),
                'rotate': cfg['defaults'].get('rotate', 0),
            }
        ic = cfg['images'][stem]
        if 'profile' in body:
            ic['profile'] = body['profile']
        hdr = float(body.get('hdr', 0))
        if hdr > 0:
            ic['hdr'] = hdr
        else:
            ic.pop('hdr', None)
        ev = float(body.get('ev', 0))
        if ev != 0:
            ic['ev'] = ev
        else:
            ic.pop('ev', None)
        if body.get('sharpen'):
            ic['sharpen'] = True
        else:
            ic.pop('sharpen', None)
        if body.get('anneal'):
            ic['anneal'] = True
        else:
            ic.pop('anneal', None)
        sl.save_configs(cfg)
        invalidate(stem)
        self._json({'ok': True})

    def _json(self, obj):
        data = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(data))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        # Suppress image GET noise; keep API ops and errors visible
        if args and isinstance(args[0], str) and '/img/' in args[0]:
            return
        super().log_message(fmt, *args)


# ─── Threaded server (parallel preview requests for compare grid) ─────────────

class ThreadedServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


# ─── Entry point ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='Slide before/after viewer')
    parser.add_argument('--port',       type=int, default=8000)
    parser.add_argument('--no-browser', action='store_true')
    args = parser.parse_args()

    url = f'http://localhost:{args.port}'
    server = ThreadedServer(('127.0.0.1', args.port), Handler)
    print(f'Viewer at {url}  (Ctrl+C to stop)')
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nStopped.')


if __name__ == '__main__':
    main()
