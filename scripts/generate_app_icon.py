#!/usr/bin/env python3
"""Generate the Birthday Reminder app icon set.

Produces:
  assets/branding/app_icon.png       (1024x1024 master)
  assets/branding/app_icon_foreground.png (transparent foreground, 1024x1024)
  android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png
  android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher_round.png

Palette:
  navy  #123B5D
  teal  #087F75
  coral #FF6B6B
  gold  #FFC857
  white #FFFFFF
"""
from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND_DIR = os.path.join(ROOT, "assets", "branding")
RES_DIR = os.path.join(
    ROOT, "android", "app", "src", "main", "res"
)

NAVY = (0x12, 0x3B, 0x5D, 255)
TEAL = (0x08, 0x7F, 0x75, 255)
CORAL = (0xFF, 0x6B, 0x6B, 255)
GOLD = (0xFF, 0xC8, 0x57, 255)
WHITE = (0xFF, 0xFF, 0xFF, 255)
SOFT_GRAY = (0xE2, 0xE8, 0xF0, 255)
RING_GRAY = (0xC9, 0xD3, 0xDE, 255)


def vertical_gradient(size: int, top: tuple, bottom: tuple) -> Image.Image:
    base = Image.new("RGBA", (size, size), top)
    draw = ImageDraw.Draw(base)
    step = 1.0 / size
    for y in range(size):
        t = y * step
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    return base


def draw_icon(size: int, *, foreground_only: bool = False) -> Image.Image:
    """Render the icon at the requested size.

    When ``foreground_only`` is True we draw a transparent background
    with the calendar + cake + accents centred, ready to be composited
    over the adaptive-icon background drawable. The foreground is
    sized so its critical content fits inside the central ~65% — the
    Android adaptive-icon spec masks up to 33% of each edge.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if not foreground_only:
        bg = vertical_gradient(size, NAVY, TEAL)
        img = bg
        draw = ImageDraw.Draw(img)

    # Mask safe area: outer ~33% may be clipped by Android.
    # Place the calendar centred, ~62% of the canvas.
    if foreground_only:
        cx = cy = size / 2
        cal_w = size * 0.62
        cal_h = size * 0.7
    else:
        cx = cy = size / 2
        cal_w = size * 0.6
        cal_h = size * 0.68

    cal_x0 = cx - cal_w / 2
    cal_y0 = cy - cal_h / 2 + size * 0.02
    cal_x1 = cal_x0 + cal_w
    cal_y1 = cal_y0 + cal_h
    radius = size * 0.06

    # Calendar shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [cal_x0 + 4, cal_y0 + 8, cal_x1 + 4, cal_y1 + 8],
        radius=radius,
        fill=(0, 0, 0, 90),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=size * 0.01))
    img.alpha_composite(shadow)

    # Calendar body
    draw.rounded_rectangle(
        [cal_x0, cal_y0, cal_x1, cal_y1],
        radius=radius,
        fill=WHITE,
    )
    # Header bar
    header_h = cal_h * 0.18
    draw.rounded_rectangle(
        [cal_x0, cal_y0, cal_x1, cal_y0 + header_h],
        radius=radius,
        fill=SOFT_GRAY,
    )
    draw.rectangle(
        [cal_x0, cal_y0 + header_h * 0.5, cal_x1, cal_y0 + header_h],
        fill=SOFT_GRAY,
    )

    # Binder rings
    ring_w = size * 0.012
    ring_h = size * 0.06
    ring_y0 = cal_y0 - ring_h * 0.4
    ring_y1 = ring_y0 + ring_h
    for rx_frac in (0.22, 0.78):
        rx = cal_x0 + cal_w * rx_frac
        draw.rounded_rectangle(
            [rx - ring_w, ring_y0, rx + ring_w, ring_y1],
            radius=ring_w,
            fill=RING_GRAY,
        )

    # ---- Cake ----
    cake_cx = cx
    cake_bottom = cal_y1 - cal_h * 0.08
    layer_w_top = cal_w * 0.30
    layer_w_mid = cal_w * 0.42
    layer_w_bot = cal_w * 0.54
    layer_h = cal_h * 0.085

    # Base layer
    bot_x0 = cake_cx - layer_w_bot / 2
    bot_x1 = cake_cx + layer_w_bot / 2
    bot_y0 = cake_bottom - layer_h
    draw.rounded_rectangle(
        [bot_x0, bot_y0, bot_x1, cake_bottom],
        radius=size * 0.012,
        fill=CORAL,
    )
    # Drip pattern
    drip_w = layer_w_bot / 7
    for i in range(7):
        dx = bot_x0 + drip_w * i + drip_w * 0.5
        draw.ellipse(
            [dx - drip_w * 0.25, bot_y0 - drip_w * 0.25,
             dx + drip_w * 0.25, bot_y0 + drip_w * 0.25],
            fill=CORAL,
        )

    # Middle layer (white)
    mid_y0 = bot_y0 - layer_h * 0.85
    mid_x0 = cake_cx - layer_w_mid / 2
    mid_x1 = cake_cx + layer_w_mid / 2
    draw.rounded_rectangle(
        [mid_x0, mid_y0, mid_x1, bot_y0 + layer_h * 0.15],
        radius=size * 0.012,
        fill=WHITE,
    )
    # Coral drip on white
    for i in range(5):
        dx = mid_x0 + (mid_x1 - mid_x0) * (i + 0.5) / 5
        draw.ellipse(
            [dx - drip_w * 0.2, mid_y0 - drip_w * 0.18,
             dx + drip_w * 0.2, mid_y0 + drip_w * 0.2],
            fill=CORAL,
        )

    # Top layer (coral)
    top_y0 = mid_y0 - layer_h * 0.85
    top_x0 = cake_cx - layer_w_top / 2
    top_x1 = cake_cx + layer_w_top / 2
    draw.rounded_rectangle(
        [top_x0, top_y0, top_x1, mid_y0 + layer_h * 0.15],
        radius=size * 0.012,
        fill=CORAL,
    )

    # Candle
    candle_w = size * 0.018
    candle_h = size * 0.09
    candle_x0 = cake_cx - candle_w / 2
    candle_x1 = cake_cx + candle_w / 2
    candle_y1 = top_y0 + size * 0.005
    candle_y0 = candle_y1 - candle_h
    draw.rounded_rectangle(
        [candle_x0, candle_y0, candle_x1, candle_y1],
        radius=candle_w / 2,
        fill=WHITE,
    )

    # Flame
    flame_cx = cake_cx
    flame_cy = candle_y0 - size * 0.025
    flame_r = size * 0.025
    flame = [
        (flame_cx, flame_cy - flame_r),
        (flame_cx + flame_r * 0.7, flame_cy + flame_r * 0.2),
        (flame_cx, flame_cy + flame_r * 0.7),
        (flame_cx - flame_r * 0.7, flame_cy + flame_r * 0.2),
    ]
    draw.polygon(flame, fill=GOLD)

    # Coral heart (top-right of cake)
    heart_cx = top_x1 + size * 0.04
    heart_cy = top_y0 + size * 0.025
    heart_r = size * 0.022
    draw.ellipse(
        [heart_cx - heart_r, heart_cy - heart_r * 0.7,
         heart_cx, heart_cy + heart_r * 0.5],
        fill=CORAL,
    )
    draw.ellipse(
        [heart_cx, heart_cy - heart_r * 0.7,
         heart_cx + heart_r, heart_cy + heart_r * 0.5],
        fill=CORAL,
    )
    draw.polygon(
        [
            (heart_cx - heart_r * 0.95, heart_cy + heart_r * 0.3),
            (heart_cx + heart_r * 0.95, heart_cy + heart_r * 0.3),
            (heart_cx, heart_cy + heart_r * 1.2),
        ],
        fill=CORAL,
    )

    # Sparkle near flame
    spk_cx = flame_cx + size * 0.025
    spk_cy = flame_cy - size * 0.018
    spk_r = size * 0.018
    draw.polygon(
        [
            (spk_cx, spk_cy - spk_r),
            (spk_cx + spk_r * 0.25, spk_cy - spk_r * 0.25),
            (spk_cx + spk_r, spk_cy),
            (spk_cx + spk_r * 0.25, spk_cy + spk_r * 0.25),
            (spk_cx, spk_cy + spk_r),
            (spk_cx - spk_r * 0.25, spk_cy + spk_r * 0.25),
            (spk_cx - spk_r, spk_cy),
            (spk_cx - spk_r * 0.25, spk_cy - spk_r * 0.25),
        ],
        fill=GOLD,
    )

    return img


def round_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([0, 0, size, size], fill=255)
    return mask


def main() -> int:
    os.makedirs(BRAND_DIR, exist_ok=True)

    master = draw_icon(1024, foreground_only=False)
    master_path = os.path.join(BRAND_DIR, "app_icon.png")
    master.save(master_path)
    print(f"wrote {master_path}")

    fg = draw_icon(1024, foreground_only=True)
    fg_path = os.path.join(BRAND_DIR, "app_icon_foreground.png")
    fg.save(fg_path)
    print(f"wrote {fg_path}")

    # Generate densities
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for sub, s in sizes.items():
        out_dir = os.path.join(RES_DIR, sub)
        os.makedirs(out_dir, exist_ok=True)
        rendered = draw_icon(512, foreground_only=False).resize(
            (s, s), Image.LANCZOS
        )
        # Square icon (legacy launcher + adaptive preview).
        rendered.save(os.path.join(out_dir, "ic_launcher.png"))
        # Round variant.
        round_icon = rendered.copy()
        round_icon.putalpha(round_mask(s))
        round_icon.save(os.path.join(out_dir, "ic_launcher_round.png"))
        print(f"wrote {sub}/ic_launcher{{,_round}}.png ({s}x{s})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
