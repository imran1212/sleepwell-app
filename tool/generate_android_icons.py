#!/usr/bin/env python3
"""Generate SleepWell Android launcher icons from the approved moon/cloud brand direction."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path("android/app/src/main/res")
BG_TOP = (11, 16, 48)
BG_BOTTOM = (108, 92, 231)
LAVENDER = (167, 139, 250)
WHITE = (248, 250, 255)

def gradient(size):
    w, h = size
    im = Image.new("RGBA", size)
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(round(BG_TOP[i] * (1-t) + BG_BOTTOM[i] * t) for i in range(3))
        for x in range(w):
            px[x, y] = (*c, 255)
    return im

def draw_mark(im, scale=1.0, offset=(0, 0)):
    w, h = im.size
    d = ImageDraw.Draw(im, "RGBA")
    ox, oy = offset
    # Crescent moon, built as a clean cut-out shape.
    moon = Image.new("RGBA", im.size, (0,0,0,0))
    md = ImageDraw.Draw(moon)
    cx, cy, r = ox + w*.43, oy + h*.40, w*.235
    md.ellipse((cx-r, cy-r, cx+r, cy+r), fill=WHITE+(255,))
    md.ellipse((cx-r*.20, cy-r*1.08, cx+r*1.30, cy+r*.42), fill=(17,20,72,255))
    im.alpha_composite(moon)
    d = ImageDraw.Draw(im, "RGBA")
    # Three soft cloud lobes across the lower crescent.
    cloud = LAVENDER+(255,)
    x, y = ox, oy
    d.ellipse((x+w*.18, y+h*.57, x+w*.54, y+h*.88), fill=cloud)
    d.ellipse((x+w*.34, y+h*.49, x+w*.72, y+h*.86), fill=(139,112,246,255))
    d.ellipse((x+w*.52, y+h*.60, x+w*.83, y+h*.86), fill=(121,96,231,255))
    d.rounded_rectangle((x+w*.22, y+h*.70, x+w*.78, y+h*.88), radius=int(w*.08), fill=(130,104,239,255))
    # Stars with small crisp four-point sparkle.
    def star(sx, sy, rr):
        d.polygon([(sx,sy-rr),(sx+rr*.22,sy-rr*.22),(sx+rr,sy),
                   (sx+rr*.22,sy+rr*.22),(sx,sy+rr),
                   (sx-rr*.22,sy+rr*.22),(sx-rr,sy),
                   (sx-rr*.22,sy-rr*.22)], fill=WHITE+(245,))
    star(x+w*.72, y+h*.24, w*.055)
    star(x+w*.84, y+h*.42, w*.025)
    star(x+w*.20, y+h*.30, w*.018)

def make_icon(size):
    im = gradient((size, size))
    # Gentle radial glow behind the moon.
    glow = Image.new("RGBA", (size,size), (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((size*.16,size*.08,size*.88,size*.82), fill=(167,139,250,35))
    glow = glow.filter(ImageFilter.GaussianBlur(max(1,size*.045)))
    im.alpha_composite(glow)
    draw_mark(im)
    return im.convert("RGB")

# Legacy launcher icons at Android density sizes.
for density, px in {"mdpi":48, "hdpi":72, "xhdpi":96, "xxhdpi":144, "xxxhdpi":192}.items():
    folder = ROOT / f"mipmap-{density}"
    folder.mkdir(parents=True, exist_ok=True)
    make_icon(px).save(folder / "ic_launcher.png", optimize=True)

# Adaptive icon foreground: transparent canvas, with content kept inside safe zone.
fg = Image.new("RGBA", (432,432), (0,0,0,0))
draw_mark(fg, offset=(0,0))
(ROOT / "drawable-nodpi").mkdir(parents=True, exist_ok=True)
fg.save(ROOT / "drawable-nodpi" / "sleepwell_launcher_foreground.png", optimize=True)

adaptive = ROOT / "mipmap-anydpi-v26"
adaptive.mkdir(parents=True, exist_ok=True)
(adaptive / "ic_launcher.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/sleepwell_launcher_background"/>
    <foreground android:drawable="@drawable/sleepwell_launcher_foreground"/>
</adaptive-icon>
''', encoding="utf-8")

colors = ROOT / "values"
colors.mkdir(parents=True, exist_ok=True)
color_file = colors / "sleepwell_launcher_colors.xml"
color_file.write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="sleepwell_launcher_background">#0B1020</color>
</resources>
''', encoding="utf-8")

# Standalone square master for Play Console / Google Cloud branding.
make_icon(512).save("sleepwell_icon_512.png", optimize=True)
print("Generated SleepWell launcher icons (48–192 px), adaptive icon, and 512 px master.")
