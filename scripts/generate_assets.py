#!/usr/bin/env python3
"""
Money or Honey - Pixel Art Asset Generator
Generates consistent pixel art assets for the game
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random
import math
import sys

# Asset directories - use script location as reference
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
ASSETS_DIR = os.path.join(PROJECT_DIR, "assets/sprites")
CURRENCIES_DIR = f"{ASSETS_DIR}/currencies"
NPCS_DIR = f"{ASSETS_DIR}/npcs"
UI_DIR = f"{ASSETS_DIR}/ui"
TOOLS_DIR = f"{ASSETS_DIR}/tools"
DOCUMENTS_DIR = f"{ASSETS_DIR}/documents"
BACKGROUNDS_DIR = f"{ASSETS_DIR}/backgrounds"

# Create directories
for dir_path in [CURRENCIES_DIR, NPCS_DIR, UI_DIR, TOOLS_DIR, DOCUMENTS_DIR, BACKGROUNDS_DIR]:
    os.makedirs(dir_path, exist_ok=True)

# Create currency subdirectories
for currency in ["usd", "eur", "gbp"]:
    os.makedirs(f"{CURRENCIES_DIR}/{currency}", exist_ok=True)

# Denomination-specific color schemes (base colors like real banknotes)
DENOM_COLORS = {
    "usd": {
        1:   (167, 184, 154),
        5:   (180, 160, 170),
        10:  (210, 175, 130),
        20:  (160, 180, 140),
        50:  (150, 155, 175),
        100: (140, 150, 170),
    },
    "eur": {
        5:   (180, 180, 180),
        10:  (190, 130, 120),
        20:  (120, 150, 180),
        50:  (200, 160, 110),
        100: (130, 170, 130),
        200: (200, 190, 120),
        500: (160, 130, 170),
    },
    "gbp": {
        5:   (120, 180, 180),
        10:  (180, 150, 110),
        20:  (160, 130, 180),
        50:  (190, 120, 120),
    },
}

CURRENCY_LABELS = {
    "usd": ["FEDERAL RESERVE NOTE", "THE UNITED STATES"],
    "eur": ["EURO", "EUROPEAN CENTRAL BANK"],
    "gbp": ["BANK OF ENGLAND", "PROMISE TO PAY"],
}

CURRENCY_SYMBOLS = {"usd": "$", "eur": "\u20ac", "gbp": "\u00a3"}

# 3x5 pixel font for text rendering (each glyph is a list of "0/1" rows)
PIXEL_FONT = {
    'A': ["010", "101", "111", "101", "101"],
    'B': ["110", "101", "110", "101", "110"],
    'C': ["011", "100", "100", "100", "011"],
    'D': ["110", "101", "101", "101", "110"],
    'E': ["111", "100", "110", "100", "111"],
    'F': ["111", "100", "110", "100", "100"],
    'G': ["011", "100", "101", "101", "011"],
    'H': ["101", "101", "111", "101", "101"],
    'I': ["111", "010", "010", "010", "111"],
    'J': ["001", "001", "001", "101", "010"],
    'K': ["101", "110", "100", "110", "101"],
    'L': ["100", "100", "100", "100", "111"],
    'M': ["101", "111", "111", "101", "101"],
    'N': ["101", "111", "111", "111", "101"],
    'O': ["010", "101", "101", "101", "010"],
    'P': ["110", "101", "110", "100", "100"],
    'R': ["110", "101", "110", "101", "101"],
    'S': ["011", "100", "010", "001", "110"],
    'T': ["111", "010", "010", "010", "010"],
    'U': ["101", "101", "101", "101", "011"],
    'V': ["101", "101", "101", "101", "010"],
    'W': ["101", "101", "111", "111", "101"],
    'Y': ["101", "101", "010", "010", "010"],
    '0': ["010", "101", "101", "101", "010"],
    '1': ["010", "110", "010", "010", "111"],
    '2': ["110", "001", "010", "100", "111"],
    '3': ["110", "001", "010", "001", "110"],
    '4': ["101", "101", "111", "001", "001"],
    '5': ["111", "100", "110", "001", "110"],
    '6': ["011", "100", "110", "101", "010"],
    '7': ["111", "001", "010", "010", "010"],
    '8': ["010", "101", "010", "101", "010"],
    '9': ["010", "101", "011", "001", "110"],
    ' ': ["000", "000", "000", "000", "000"],
    '$': ["010", "111", "010", "111", "010"],
}


def _draw_pixel_char(img, x, y, char, color, scale=1):
    """Draw a single character from PIXEL_FONT onto img."""
    glyph = PIXEL_FONT.get(char)
    if not glyph:
        glyph = PIXEL_FONT[' ']
    pixels = img.load()
    w, h = img.size
    for row_i, row in enumerate(glyph):
        for col_i, c in enumerate(row):
            if c == '1':
                for dy in range(scale):
                    for dx in range(scale):
                        px, py = x + col_i * scale + dx, y + row_i * scale + dy
                        if 0 <= px < w and 0 <= py < h:
                            pixels[px, py] = color


def _draw_pixel_string(img, x, y, text, color, scale=1, spacing=1):
    """Draw a string of pixel-font text onto img."""
    cx = x
    for ch in text.upper():
        _draw_pixel_char(img, cx, y, ch, color, scale)
        cx += (3 + spacing) * scale


def _blend_color(c1, c2, alpha):
    """Blend two RGB colors. alpha=0 -> c1, alpha=1 -> c2."""
    return tuple(int(a + (b - a) * alpha) for a, b in zip(c1, c2))


def _lighten(color, amount=30):
    return tuple(min(255, c + amount) for c in color)


def _darken(color, amount=30):
    return tuple(max(0, c - amount) for c in color)


def draw_guilloche_pattern(img, x1, y1, x2, y2, color, is_fake=False):
    """Draw fine wavy/intersecting line patterns in the background."""
    pixels = img.load()
    w, h = img.size
    bg_pixels = {(px, py): pixels[px, py]
                 for px in range(max(0, x1), min(w, x2))
                 for py in range(max(0, y1), min(h, y2))}
    light = _lighten(color, 20)
    dark = _darken(color, 15)
    num_waves = 10 if not is_fake else 6
    for i in range(num_waves):
        phase = i * 0.7
        amplitude = 3 + (i % 4) * 1.5
        frequency = 0.05 + (i % 3) * 0.02
        base_y = y1 + (y2 - y1) * (i + 1) / (num_waves + 1)
        for px in range(max(0, x1), min(w, x2)):
            py = int(base_y + amplitude * math.sin(frequency * px + phase))
            if y1 <= py < y2 and 0 <= py < h:
                c = light if i % 2 == 0 else dark
                old = bg_pixels.get((px, py), pixels[px, py])
                pixels[px, py] = _blend_color(old, c, 0.3)
    if not is_fake:
        for i in range(6):
            phase2 = i * 1.1
            amp2 = 4 + i * 1.2
            freq2 = 0.04 + (i % 3) * 0.015
            base_x = x1 + (x2 - x1) * (i + 1) / 7
            for py in range(max(0, y1), min(h, y2)):
                px = int(base_x + amp2 * math.sin(freq2 * py + phase2))
                if x1 <= px < x2 and 0 <= px < w:
                    c = dark if i % 2 == 0 else light
                    old = bg_pixels.get((px, py), pixels[px, py])
                    pixels[px, py] = _blend_color(old, c, 0.2)


def draw_decorative_border(img, x1, y1, x2, y2, accent, secondary, is_fake=False):
    """Draw multiple nested borders with decorative corner elements."""
    draw = ImageDraw.Draw(img)
    off = 1 if is_fake else 0
    draw.rectangle([x1, y1, x2, y2], outline=accent)
    draw.rectangle([x1 + 2, y1 + 2, x2 - 2, y2 - 2], outline=accent)
    draw.rectangle([x1 + 4, y1 + 4, x2 - 4, y2 - 4], outline=secondary)
    draw.rectangle([x1 + 6 + off, y1 + 6, x2 - 6, y2 - 6], outline=secondary)
    corner_size = 6
    for cx, cy in [(x1 + 1, y1 + 1), (x2 - 1, y1 + 1),
                   (x1 + 1, y2 - 1), (x2 - 1, y2 - 1)]:
        draw.rectangle([cx, cy, cx + corner_size, cy + corner_size], outline=accent)
        draw.rectangle([cx + 1, cy + 1, cx + corner_size - 1, cy + corner_size - 1],
                        outline=secondary)
        draw.point((cx + 3, cy + 3), fill=accent)
    for px in range(x1 + 10, x2 - 10, 4):
        for edge_y in [y1 + 3, y2 - 3]:
            draw.point((px, edge_y), fill=accent)
            draw.point((px + 1, edge_y), fill=accent)
    for py in range(y1 + 10, y2 - 10, 4):
        for edge_x in [x1 + 3, x2 - 3]:
            draw.point((edge_x, py), fill=accent)
            draw.point((edge_x, py + 1), fill=accent)


def draw_portrait_oval(img, cx, cy, rx, ry, base_color, is_fake=False):
    """Draw a detailed oval frame with a silhouette portrait inside."""
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    w, h = img.size
    dark = _darken(base_color, 60)
    medium = _darken(base_color, 30)
    light = _lighten(base_color, 25)
    for t_offset in range(-2, 3):
        c = dark if abs(t_offset) > 1 else medium
        for angle_deg in range(360):
            a = math.radians(angle_deg)
            px = int(cx + (rx + t_offset) * math.cos(a))
            py = int(cy + (ry + t_offset) * math.sin(a))
            if 0 <= px < w and 0 <= py < h:
                pixels[px, py] = c
    for angle_deg in range(360):
        a = math.radians(angle_deg)
        for r_off in range(-4, -2):
            px = int(cx + (rx + r_off) * math.cos(a))
            py = int(cy + (ry + r_off) * math.sin(a))
            if 0 <= px < w and 0 <= py < h:
                pixels[px, py] = light
    interior = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    idraw = ImageDraw.Draw(interior)
    idraw.ellipse([cx - rx + 5, cy - ry + 5, cx + rx - 5, cy + ry - 5],
                  fill=_lighten(base_color, 35) + (255,))
    sil_color = _darken(base_color, 70)
    head_cx, head_cy = cx - 2, cy - ry // 3
    head_r = min(rx, ry) // 3
    idraw.ellipse([head_cx - head_r, head_cy - head_r,
                   head_cx + head_r, head_cy + head_r], fill=sil_color + (255,))
    idraw.rectangle([head_cx - head_r - 1, head_cy + head_r - 2,
                     head_cx + head_r // 2 + 3, head_cy + head_r + 4],
                    fill=sil_color + (255,))
    nose_x = head_cx + head_r + 2
    idraw.polygon([(nose_x, head_cy - 1), (nose_x + 3, head_cy + 2),
                   (nose_x, head_cy + 3)], fill=sil_color + (255,))
    shoulder_y = head_cy + head_r + 4
    idraw.ellipse([cx - rx + 8, shoulder_y, cx + rx - 8, cy + ry - 6],
                  fill=sil_color + (255,))
    img.paste(Image.alpha_composite(
        img.convert('RGBA'), interior).convert('RGB'))


def draw_denomination_corner(img, x, y, number, bg_color, accent, scale=2, is_fake=False):
    """Draw a framed denomination number in a corner."""
    draw = ImageDraw.Draw(img)
    digits = str(number)
    cw = 3 * scale
    spacing = scale
    text_w = len(digits) * (cw + spacing) - spacing
    bw = max(text_w + 8, 20)
    bh = 5 * scale + 8
    draw.rectangle([x, y, x + bw, y + bh], fill=accent)
    draw.rectangle([x + 1, y + 1, x + bw - 1, y + bh - 1], fill=bg_color)
    draw.rectangle([x + 2, y + 2, x + bw - 2, y + bh - 2], outline=accent)
    tx = x + (bw - text_w) // 2
    ty = y + (bh - 5 * scale) // 2
    text_color = accent
    if is_fake:
        tx += random.choice([-1, 0, 1])
        ty += random.choice([-1, 0, 1])
        text_color = _darken(accent, random.randint(5, 15))
    _draw_pixel_string(img, tx, ty, digits, text_color, scale=scale)


def draw_serial_number(img, x, y, serial, color, scale=1):
    """Draw a serial number string in monospace pixel text."""
    _draw_pixel_string(img, x, y, serial, color, scale=scale, spacing=1)


def draw_security_thread(img, x, y1, y2, base_color, is_fake=False):
    """Draw a vertical metallic-looking security strip."""
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    w, h = img.size
    tw = 3
    if is_fake:
        cy = y1
        while cy < y2:
            seg = random.randint(3, 8)
            for py in range(cy, min(cy + seg, y2)):
                for dx in range(tw):
                    px = x + dx
                    if 0 <= px < w and 0 <= py < h:
                        pixels[px, py] = _blend_color(pixels[px, py], base_color, 0.35)
            cy += seg + random.randint(3, 8)
    else:
        for py in range(y1, y2):
            shimmer = int(15 * math.sin(py * 0.25))
            tc = tuple(max(0, min(255, c + shimmer + 25)) for c in base_color)
            for dx in range(tw):
                px = x + dx
                if 0 <= px < w:
                    pixels[px, py] = _blend_color(pixels[px, py], tc, 0.5)
        for py in range(y1, y2, 4):
            for dx in range(tw):
                px = x + dx
                if 0 <= px < w and 0 <= py < h:
                    pixels[px, py] = _blend_color(pixels[px, py], (255, 255, 255), 0.15)


def draw_watermark(img, cx, cy, rx, ry, base_color, is_fake=False):
    """Draw a lighter oval watermark area on the right side."""
    if is_fake:
        return
    w, h = img.size
    overlay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    wm_color = _lighten(base_color, 40)
    odraw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=wm_color + (50,))
    for r in range(min(rx, ry) - 3, 2, -4):
        odraw.ellipse([cx - r, cy - r, cx + r, cy + r],
                      outline=_lighten(base_color, 25) + (30,))
    img.paste(Image.alpha_composite(
        img.convert('RGBA'), overlay).convert('RGB'))


def draw_seal(img, cx, cy, radius, base_color, currency):
    """Draw a circular seal/emblem."""
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    w, h = img.size
    dark = _darken(base_color, 50)
    medium = _darken(base_color, 25)
    light = _lighten(base_color, 15)
    for r in range(radius, radius - 3, -1):
        for a_deg in range(360):
            a = math.radians(a_deg)
            px = int(cx + r * math.cos(a))
            py = int(cy + r * math.sin(a))
            if 0 <= px < w and 0 <= py < h:
                pixels[px, py] = dark
    for a_deg in range(0, 360, 15):
        a = math.radians(a_deg)
        for r in range(radius - 4, radius - 1):
            px = int(cx + r * math.cos(a))
            py = int(cy + r * math.sin(a))
            if 0 <= px < w and 0 <= py < h:
                pixels[px, py] = light
    inner_r = radius - 5
    for a_deg in range(360):
        a = math.radians(a_deg)
        px = int(cx + inner_r * math.cos(a))
        py = int(cy + inner_r * math.sin(a))
        if 0 <= px < w and 0 <= py < h:
            pixels[px, py] = medium
    for a_deg in range(0, 360, 30):
        a = math.radians(a_deg)
        sr = 2
        sx = int(cx + (inner_r - 3) * math.cos(a))
        sy = int(cy + (inner_r - 3) * math.sin(a))
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=light)
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=dark)
    _draw_pixel_char(img, cx - 1, cy - 7, currency[0].upper(), dark, scale=1)


def draw_micro_printing(img, x1, x2, y, base_color, is_fake=False):
    """Draw very fine horizontal lines that look like text from a distance."""
    pixels = img.load()
    w, h = img.size
    line_color = _darken(base_color, 20)
    num_lines = 3 if not is_fake else 2
    for li in range(num_lines):
        ly = y + li * 2
        if ly >= h:
            break
        px = x1
        while px < x2:
            dash = random.randint(2, 5)
            for dx in range(dash):
                if 0 <= px + dx < w and 0 <= ly < h:
                    pixels[px + dx, ly] = _blend_color(pixels[px + dx, ly], line_color, 0.35)
            px += dash + random.randint(1, 3)


def _make_serial(currency, denomination, is_fake=False):
    """Generate a serial number string."""
    prefix = f"{random.choice('ABCDEFGH')}{random.choice('ABCDEFGH')}"
    num = f"{random.randint(0, 99999999):08d}"
    suffix = random.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    serial = f"{prefix}{num}{suffix}"
    if is_fake:
        serial = f"{random.choice('XYZ')}{random.choice('0123456789')}{num}{suffix}"
    return serial


def generate_banknote(currency, denomination, is_fake=False, size=(256, 128)):
    """Generate a realistic-looking pixel art banknote."""
    base_color = DENOM_COLORS[currency][denomination]
    if is_fake:
        ch = random.choice([0, 1, 2])
        shift = random.randint(-18, 18)
        base_color = tuple(
            max(0, min(255, v + (shift if i == ch else 0)))
            for i, v in enumerate(base_color)
        )

    bg_color = _lighten(base_color, 45)
    accent = _darken(base_color, 65)
    secondary = _darken(base_color, 35)
    text_color = _darken(base_color, 80)
    light_text = _darken(base_color, 50)

    img = Image.new('RGB', size, bg_color)
    draw = ImageDraw.Draw(img)
    pixels = img.load()
    w, h = size

    for py in range(h):
        for px in range(w):
            n = random.randint(-4, 4)
            r, g, b = pixels[px, py]
            pixels[px, py] = (max(0, min(255, r + n)),
                              max(0, min(255, g + n)),
                              max(0, min(255, b + n)))

    draw_guilloche_pattern(img, 12, 12, w - 12, h - 12, base_color, is_fake)

    draw_decorative_border(img, 3, 3, w - 4, h - 4, accent, secondary, is_fake)

    portrait_cx, portrait_cy = w // 2, h // 2
    portrait_rx, portrait_ry = 27, 32
    draw_portrait_oval(img, portrait_cx, portrait_cy,
                       portrait_rx, portrait_ry, base_color, is_fake)

    seal_cx, seal_cy = 55, h // 2
    seal_r = 18
    draw_seal(img, seal_cx, seal_cy, seal_r, base_color, currency)

    thread_x = 170
    draw_security_thread(img, thread_x, 10, h - 10, base_color, is_fake)

    watermark_cx, watermark_cy = 200, h // 2
    draw_watermark(img, watermark_cx, watermark_cy, 16, 22, base_color, is_fake)

    corner_scale = 2
    draw_denomination_corner(img, 10, 8, denomination, bg_color, accent,
                             corner_scale, is_fake)
    draw_denomination_corner(img, w - 37, 8, denomination, bg_color, accent,
                             corner_scale, is_fake)
    draw_denomination_corner(img, 10, h - 30, denomination, bg_color, accent,
                             corner_scale, is_fake)
    draw_denomination_corner(img, w - 37, h - 30, denomination, bg_color, accent,
                             corner_scale, is_fake)

    labels = CURRENCY_LABELS[currency]
    _draw_pixel_string(img, 42, 33, labels[0], text_color, scale=1, spacing=1)
    _draw_pixel_string(img, 42, 41, labels[1], light_text, scale=1, spacing=1)

    serial = _make_serial(currency, denomination, is_fake)
    serial_x = 70
    serial_y = h - 19
    _draw_pixel_string(img, serial_x, serial_y, serial, text_color, scale=1, spacing=1)

    draw_micro_printing(img, 14, w - 14, h - 38, base_color, is_fake)
    draw_micro_printing(img, 14, w - 14, h - 32, base_color, is_fake)

    sym = CURRENCY_SYMBOLS[currency]
    if sym in PIXEL_FONT:
        _draw_pixel_char(img, portrait_cx - 1, portrait_cy + portrait_ry + 3,
                         sym, accent, scale=1)

    return img

def generate_npc_sprite(npc_type="normal", size=(64, 64)):
    """Generate NPC character sprite"""
    img = Image.new('RGB', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Color schemes for different NPC types
    color_schemes = {
        "normal": {"skin": (220, 180, 150), "shirt": (100, 120, 140), "hair": (60, 40, 30)},
        "careless": {"skin": (210, 170, 140), "shirt": (140, 100, 120), "hair": (80, 60, 40)},
        "suspicious": {"skin": (200, 160, 130), "shirt": (80, 80, 80), "hair": (40, 40, 40)},
        "professional": {"skin": (230, 190, 160), "shirt": (60, 60, 80), "hair": (50, 30, 20)},
    }
    
    colors = color_schemes.get(npc_type, color_schemes["normal"])
    
    # Head
    head_x, head_y = size[0]//2, 20
    head_radius = 12
    draw.ellipse([head_x-head_radius, head_y-head_radius,
                  head_x+head_radius, head_y+head_radius],
                 fill=colors["skin"])
    
    # Hair
    draw.arc([head_x-head_radius, head_y-head_radius-4,
              head_x+head_radius, head_y+head_radius-4],
             180, 360, fill=colors["hair"], width=4)
    
    # Body
    body_x, body_y = size[0]//2, 45
    draw.rectangle([body_x-15, body_y, body_x+15, body_y+15],
                   fill=colors["shirt"])
    
    # Arms
    draw.rectangle([body_x-20, body_y+2, body_x-15, body_y+12],
                   fill=colors["shirt"])
    draw.rectangle([body_x+15, body_y+2, body_x+20, body_y+12],
                   fill=colors["shirt"])
    
    # Legs
    draw.rectangle([body_x-10, body_y+15, body_x-3, body_y+28],
                   fill=(60, 60, 80))
    draw.rectangle([body_x+3, body_y+15, body_x+10, body_y+28],
                   fill=(60, 60, 80))
    
    # Face details
    # Eyes
    draw.rectangle([head_x-5, head_y-2, head_x-3, head_y], fill=(40, 40, 40))
    draw.rectangle([head_x+3, head_y-2, head_x+5, head_y], fill=(40, 40, 40))
    
    # Mouth (different for different types)
    if npc_type == "suspicious":
        draw.line([head_x-3, head_y+5, head_x+3, head_y+5], fill=(40, 40, 40), width=1)
    elif npc_type == "professional":
        draw.arc([head_x-4, head_y+3, head_x+4, head_y+7], 0, 180, fill=(40, 40, 40), width=1)
    else:
        draw.line([head_x-2, head_y+5, head_x+2, head_y+5], fill=(40, 40, 40), width=1)
    
    return img

def generate_tool_icon(tool_name, size=(32, 32)):
    """Generate tool icons"""
    img = Image.new('RGB', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if tool_name == "magnifier":
        # Magnifying glass
        draw.ellipse([4, 4, 20, 20], outline=(200, 200, 200), width=2)
        draw.ellipse([6, 6, 18, 18], outline=(150, 200, 255), width=1)
        draw.line([18, 18, 28, 28], fill=(150, 100, 50), width=3)
    
    elif tool_name == "uv_lamp":
        # UV lamp
        draw.rectangle([8, 8, 24, 20], fill=(100, 50, 150))
        draw.rectangle([10, 10, 22, 18], fill=(150, 100, 200))
        draw.rectangle([12, 20, 20, 26], fill=(80, 80, 80))
        # UV rays
        for i in range(3):
            draw.line([12+i*4, 8, 12+i*4, 4], fill=(200, 150, 255), width=1)
    
    elif tool_name == "scale":
        # Scale/balance
        draw.rectangle([14, 8, 18, 24], fill=(150, 150, 150))
        draw.polygon([(8, 12), (16, 8), (24, 12)], fill=(180, 180, 180))
        draw.ellipse([4, 12, 12, 20], outline=(120, 120, 120), width=2)
        draw.ellipse([20, 12, 28, 20], outline=(120, 120, 120), width=2)
    
    elif tool_name == "microscope":
        # Microscope
        draw.rectangle([12, 20, 20, 28], fill=(100, 100, 100))
        draw.rectangle([14, 8, 18, 20], fill=(150, 150, 150))
        draw.ellipse([10, 4, 22, 10], fill=(180, 180, 180))
        draw.rectangle([8, 28, 24, 30], fill=(80, 80, 80))
    
    return img

def generate_document_icon(doc_type, size=(64, 80)):
    """Generate document icons"""
    img = Image.new('RGB', size, (240, 240, 230))
    draw = ImageDraw.Draw(img)
    
    # Paper background
    draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(240, 240, 230))
    draw.rectangle([0, 0, size[0]-1, size[1]-1], outline=(180, 180, 170), width=1)
    
    # Header
    draw.rectangle([4, 4, size[0]-4, 12], fill=(100, 100, 120))
    
    # Text lines
    for i in range(6):
        y = 20 + i * 8
        width = random.randint(30, size[0]-16)
        draw.rectangle([8, y, 8+width, y+4], fill=(150, 150, 160))
    
    # Document type specific elements
    if doc_type == "invoice":
        # Dollar sign
        draw.rectangle([size[0]-20, 4, size[0]-8, 12], fill=(80, 120, 80))
    elif doc_type == "receipt":
        # Barcode
        for i in range(8):
            x = 8 + i * 6
            draw.rectangle([x, size[1]-16, x+4, size[1]-8], fill=(80, 80, 80))
    elif doc_type == "id":
        # Photo placeholder
        draw.rectangle([8, 20, 28, 40], fill=(180, 180, 190))
        draw.ellipse([12, 24, 24, 36], fill=(200, 180, 160))
    
    return img

def generate_ui_element(element_name, size=(32, 32)):
    """Generate UI elements"""
    img = Image.new('RGB', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if element_name == "button_accept":
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(80, 160, 80))
        draw.rectangle([2, 2, size[0]-3, size[1]-3], outline=(100, 200, 100), width=1)
    elif element_name == "button_reject":
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(160, 80, 80))
        draw.rectangle([2, 2, size[0]-3, size[1]-3], outline=(200, 100, 100), width=1)
    elif element_name == "coin":
        draw.ellipse([4, 4, size[0]-4, size[1]-4], fill=(220, 180, 50))
        draw.ellipse([8, 8, size[0]-8, size[1]-8], outline=(180, 140, 30), width=2)
    elif element_name == "panel":
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(60, 70, 80))
        draw.rectangle([0, 0, size[0]-1, size[1]-1], outline=(100, 110, 120), width=2)
    
    return img

def generate_background(name, size=(1280, 720)):
    """Generate background images"""
    img = Image.new('RGB', size, (40, 50, 60))
    draw = ImageDraw.Draw(img)
    
    if name == "bank_interior":
        # Bank interior - walls and floor
        draw.rectangle([0, 0, size[0]-1, size[1]//2], fill=(70, 80, 90))
        draw.rectangle([0, size[1]//2, size[0]-1, size[1]-1], fill=(50, 60, 70))
        # Counter
        draw.rectangle([0, size[1]//2 - 20, size[0]-1, size[1]//2 + 40], fill=(100, 80, 60))
        draw.rectangle([0, size[1]//2 + 40, size[0]-1, size[1]//2 + 45], fill=(80, 60, 40))
        # Window
        draw.rectangle([size[0]//2 - 100, 40, size[0]//2 + 100, 200], fill=(120, 150, 180))
        draw.rectangle([size[0]//2 - 100, 40, size[0]//2 + 100, 200], outline=(60, 70, 80), width=3)
        draw.line([size[0]//2, 40, size[0]//2, 200], fill=(60, 70, 80), width=2)
        draw.line([size[0]//2 - 100, 120, size[0]//2 + 100, 120], fill=(60, 70, 80), width=2)
    elif name == "bank_counter":
        # Teller counter close-up
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(60, 70, 80))
        draw.rectangle([0, size[1]//3, size[0]-1, size[1]-1], fill=(100, 80, 60))
        draw.rectangle([0, size[1]//3, size[0]-1, size[1]//3 + 5], fill=(120, 100, 80))
        # Glass partition hint
        draw.rectangle([size[0]//4, 20, 3*size[0]//4, size[1]//3], fill=(80, 100, 120))
        draw.rectangle([size[0]//4, 20, 3*size[0]//4, size[1]//3], outline=(60, 70, 80), width=2)
    elif name == "bank_exterior":
        # Outside view through window
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(50, 60, 70))
        # Sky
        draw.rectangle([100, 50, size[0]-100, size[1]//2], fill=(100, 140, 180))
        # Buildings
        draw.rectangle([150, 150, 300, size[1]//2], fill=(80, 80, 90))
        draw.rectangle([350, 120, 500, size[1]//2], fill=(90, 85, 80))
        # Ground
        draw.rectangle([100, size[1]//2, size[0]-100, size[1]-50], fill=(70, 75, 65))
    
    return img

def main():
    print("Generating Money or Honey assets...")
    
    # Generate banknotes
    currencies = ["usd", "eur", "gbp"]
    denominations = {
        "usd": [1, 5, 10, 20, 50, 100],
        "eur": [5, 10, 20, 50, 100, 200, 500],
        "gbp": [5, 10, 20, 50]
    }
    
    for currency in currencies:
        for denom in denominations[currency]:
            # Real note
            img = generate_banknote(currency, denom, is_fake=False)
            img.save(f"{CURRENCIES_DIR}/{currency}/{currency}_{denom}_real.png")
            
            # Fake note
            img = generate_banknote(currency, denom, is_fake=True)
            img.save(f"{CURRENCIES_DIR}/{currency}/{currency}_{denom}_fake.png")
            
            print(f"Generated {currency} {denom} banknotes")
    
    # Generate NPCs
    npc_types = ["normal", "careless", "suspicious", "professional"]
    for npc_type in npc_types:
        for i in range(3):  # 3 variants per type
            img = generate_npc_sprite(npc_type)
            img.save(f"{NPCS_DIR}/npc_{npc_type}_{i}.png")
        print(f"Generated {npc_type} NPCs")
    
    # Generate tools
    tools = ["magnifier", "uv_lamp", "scale", "microscope"]
    for tool in tools:
        img = generate_tool_icon(tool)
        img.save(f"{TOOLS_DIR}/{tool}.png")
        print(f"Generated {tool} icon")
    
    # Generate documents
    doc_types = ["invoice", "receipt", "id"]
    for doc_type in doc_types:
        for i in range(3):
            img = generate_document_icon(doc_type)
            img.save(f"{DOCUMENTS_DIR}/{doc_type}_{i}.png")
        print(f"Generated {doc_type} documents")
    
    # Generate UI elements
    ui_elements = ["button_accept", "button_reject", "coin", "panel"]
    for element in ui_elements:
        img = generate_ui_element(element)
        img.save(f"{UI_DIR}/{element}.png")
        print(f"Generated {element} UI element")
    
    # Generate backgrounds
    backgrounds = ["bank_interior", "bank_counter", "bank_exterior"]
    for bg_name in backgrounds:
        img = generate_background(bg_name)
        img.save(f"{BACKGROUNDS_DIR}/{bg_name}.png")
        print(f"Generated {bg_name} background")
    
    print("\nAsset generation complete!")
    print(f"Total assets generated:")
    print(f"- Banknotes: {sum(len(d) for d in denominations.values()) * 2} (real + fake)")
    print(f"- NPCs: {len(npc_types) * 3}")
    print(f"- Tools: {len(tools)}")
    print(f"- Documents: {len(doc_types) * 3}")
    print(f"- UI elements: {len(ui_elements)}")
    print(f"- Backgrounds: {len(backgrounds)}")

if __name__ == "__main__":
    main()
