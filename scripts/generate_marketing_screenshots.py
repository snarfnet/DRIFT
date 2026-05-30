from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import shutil

ROOT = Path(__file__).resolve().parents[1]
BG = ROOT / "Design" / "drift-techno-engine-backdrop-imagegen.png"
OUT = ROOT / "AppStoreAssets" / "screenshots"
MARKETING = ROOT / "MarketingAssets" / "Screenshots"

COLORS = {
    "oil": (8, 9, 10),
    "panel": (28, 29, 30),
    "steel": (63, 63, 59),
    "bone": (218, 210, 184),
    "amber": (245, 159, 45),
    "cyan": (48, 214, 235),
    "rust": (168, 64, 32),
    "red": (255, 52, 36),
    "white": (255, 255, 255),
}


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/CascadiaMono.ttf",
        "C:/Windows/Fonts/CascadiaMonoPL.ttf",
        "C:/Windows/Fonts/consolab.ttf" if bold else "C:/Windows/Fonts/consola.ttf",
        "C:/Windows/Fonts/seguisb.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def rgba(color, alpha=255):
    return (*color, alpha)


def chipped(points):
    x, y, w, h = points
    cut = max(8, min(w, h) * 0.025)
    return [
        (x + cut, y), (x + w - cut * 1.4, y), (x + w, y + cut),
        (x + w - cut * 0.7, y + h - cut * 0.7), (x + w - cut * 2.2, y + h),
        (x + cut * 1.2, y + h), (x, y + h - cut * 1.4), (x + cut * 0.6, y + cut * 0.7),
    ]


def draw_text(draw, xy, text, size, fill, bold=False, anchor=None):
    draw.text(xy, text, fill=fill, font=font(size, bold), anchor=anchor)


def cover_background(size):
    bg = Image.open(BG).convert("RGB")
    scale = max(size[0] / bg.width, size[1] / bg.height)
    bg = bg.resize((int(bg.width * scale), int(bg.height * scale)), Image.Resampling.LANCZOS)
    x = (bg.width - size[0]) // 2
    y = (bg.height - size[1]) // 2
    bg = bg.crop((x, y, x + size[0], y + size[1])).convert("RGBA")

    shade = Image.new("RGBA", size, rgba(COLORS["oil"], 95))
    bg = Image.alpha_composite(bg, shade)
    vignette = Image.new("L", size, 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse((-size[0] * 0.18, -size[1] * 0.08, size[0] * 1.18, size[1] * 1.08), fill=160)
    vignette = Image.eval(vignette.filter(ImageFilter.GaussianBlur(size[0] // 8)), lambda p: 190 - p)
    bg = Image.alpha_composite(bg, Image.merge("RGBA", [Image.new("L", size, 0)] * 3 + [vignette]))
    return bg


def panel(draw, box, title):
    x, y, w, h = box
    draw.polygon(chipped(box), fill=rgba(COLORS["panel"], 218), outline=rgba(COLORS["white"], 34))
    draw.polygon(chipped((x + 5, y + 5, w - 10, h - 10)), outline=rgba(COLORS["rust"], 95))
    draw.ellipse((x + 16, y + 16, x + 34, y + 34), fill=COLORS["steel"], outline=COLORS["bone"])
    draw.ellipse((x + w - 34, y + 16, x + w - 16, y + 34), fill=COLORS["steel"], outline=COLORS["bone"])
    draw_text(draw, (x + 48, y + 16), title, max(18, int(w * 0.025)), rgba(COLORS["bone"], 160), True)


def led_scope(draw, x, y, w, h, active=False):
    bars = 30
    gap = max(3, w // 190)
    bw = (w - gap * (bars - 1)) / bars
    for i in range(bars):
        height = (h * (0.22 + ((i * (9 if active else 5)) % 28) / 38))
        color = COLORS["amber"] if i % 5 == 0 else COLORS["cyan"]
        alpha = 245 if active else 90
        bx = x + i * (bw + gap)
        draw.rounded_rectangle((bx, y + h - height, bx + bw, y + h), radius=3, fill=rgba(color, alpha))


def deck_button(draw, box, title, color):
    x, y, w, h = box
    draw.polygon(chipped(box), fill=color, outline=rgba(COLORS["white"], 72))
    draw.rectangle((x + 6, y + h * 0.72, x + w - 8, y + h * 0.85), fill=rgba(COLORS["oil"], 46))
    draw_text(draw, (x + w / 2, y + h / 2), title, int(h * 0.23), COLORS["oil"], True, "mm")


def rotor(draw, cx, cy, r, tempo="120", drive="50% DRIVE"):
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=COLORS["steel"], outline=COLORS["rust"], width=int(max(8, r // 18)))
    draw.ellipse((cx - r + 22, cy - r + 22, cx + r - 22, cy + r - 22), outline=rgba(COLORS["oil"], 210), width=int(max(10, r // 16)))
    for i in range(48):
        ang = math.radians(i * 7.5 - 90)
        length = r * (0.09 if i % 4 == 0 else 0.05)
        x1 = cx + math.cos(ang) * (r - length - 10)
        y1 = cy + math.sin(ang) * (r - length - 10)
        x2 = cx + math.cos(ang) * (r - 10)
        y2 = cy + math.sin(ang) * (r - 10)
        draw.line((x1, y1, x2, y2), fill=rgba(COLORS["white"], 80), width=int(max(2, r // 90)))
    draw.arc((cx - r + 42, cy - r + 42, cx + r - 42, cy + r - 42), 120, 420, fill=COLORS["cyan"], width=int(max(12, r // 12)))
    draw.arc((cx - r + 92, cy - r + 92, cx + r - 92, cy + r - 92), 120, 360, fill=COLORS["amber"], width=int(max(8, r // 18)))
    draw.ellipse((cx - r * 0.35, cy - r * 0.35, cx + r * 0.35, cy + r * 0.35), fill=rgba(COLORS["oil"], 170), outline=rgba(COLORS["cyan"], 140), width=3)
    draw_text(draw, (cx, cy - 18), tempo, int(r * 0.33), COLORS["bone"], True, "mm")
    draw_text(draw, (cx, cy + r * 0.18), "BPM", int(r * 0.095), COLORS["amber"], True, "mm")
    draw_text(draw, (cx, cy + r * 0.34), drive, int(r * 0.092), COLORS["cyan"], True, "mm")


def style_buttons(draw, x, y, w, h):
    labels = [("DRIFT", COLORS["cyan"]), ("DEEP", COLORS["steel"]), ("MINIMAL", COLORS["steel"])]
    gap = w * 0.025
    bw = (w - gap * 2) / 3
    for i, (label, color) in enumerate(labels):
        bx = x + i * (bw + gap)
        deck_button(draw, (bx, y, bw, h), label, color)


def sliders(draw, x, y, w, scale):
    rows = [("TEMPO", "120 BPM", COLORS["amber"], 0.5), ("DRIVE", "50%", COLORS["cyan"], 0.5)]
    for i, (label, value, color, pct) in enumerate(rows):
        ry = y + i * int(78 * scale)
        rh = int(58 * scale)
        draw.polygon(chipped((x, ry, w, rh)), fill=rgba(COLORS["oil"], 98), outline=rgba(COLORS["white"], 28))
        draw_text(draw, (x + 18 * scale, ry + 13 * scale), label, int(18 * scale), rgba(COLORS["white"], 160), True)
        draw_text(draw, (x + w - 18 * scale, ry + 13 * scale), value, int(18 * scale), color, True, "ra")
        lx = x + 18 * scale
        ly = ry + 40 * scale
        lw = w - 36 * scale
        draw.line((lx, ly, lx + lw, ly), fill=rgba(COLORS["white"], 58), width=max(4, int(4 * scale)))
        draw.line((lx, ly, lx + lw * pct, ly), fill=color, width=max(5, int(5 * scale)))
        draw.ellipse((lx + lw * pct - 9 * scale, ly - 9 * scale, lx + lw * pct + 9 * scale, ly + 9 * scale), fill=color)


def keys(draw, x, y, w, scale):
    labels = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    gap = 7 * scale
    bw = (w - gap * 5) / 6
    bh = 38 * scale
    for i, label in enumerate(labels):
        row, col = divmod(i, 6)
        bx = x + col * (bw + gap)
        by = y + row * (bh + gap)
        color = COLORS["amber"] if i == 0 else COLORS["steel"]
        text = COLORS["oil"] if i == 0 else rgba(COLORS["bone"], 190)
        draw.polygon(chipped((bx, by, bw, bh)), fill=color, outline=rgba(COLORS["white"], 38))
        draw_text(draw, (bx + bw / 2, by + bh / 2), label, int(17 * scale), text, True, "mm")


def sequencer(draw, x, y, w, scale, live=False):
    rows = [("KICK", COLORS["amber"], [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]),
            ("SNARE", COLORS["red"], [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]),
            ("HIHAT", COLORS["cyan"], [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0])]
    cell_gap = 4 * scale
    cell_w = (w - cell_gap * 15) / 16
    current = 6 if live else None
    for row_index, (label, color, pattern) in enumerate(rows):
        ry = y + row_index * 92 * scale
        draw_text(draw, (x, ry), label, int(19 * scale), color, True)
        for i, on in enumerate(pattern):
            bx = x + i * (cell_w + cell_gap)
            by = ry + 30 * scale
            active = i == current
            fill = color if active else (rgba(color, 220) if on else rgba(COLORS["white"], 24))
            draw.rounded_rectangle((bx, by, bx + cell_w, by + 34 * scale), radius=5, fill=fill, outline=rgba(COLORS["white"], 180 if active else 28), width=2 if active else 1)


def mixer(draw, x, y, w, h, scale):
    channels = [("KICK", COLORS["amber"], 0.74), ("SNARE", COLORS["red"], 0.55), ("HIHAT", COLORS["cyan"], 0.86)]
    gap = w * 0.05
    cw = (w - gap * 3) / 4
    for i, (label, color, level) in enumerate(channels):
        cx = x + i * (cw + gap)
        draw_text(draw, (cx + cw / 2, y), label, int(17 * scale), color, True, "ma")
        meter = (cx + cw / 2 - 10 * scale, y + 35 * scale, 20 * scale, 95 * scale)
        draw.polygon(chipped(meter), fill=rgba(COLORS["oil"], 130), outline=rgba(COLORS["white"], 40))
        mx, my, mw, mh = meter
        draw.polygon(chipped((mx, my + mh * (1 - level), mw, mh * level)), fill=color)
        knob_r = 27 * scale
        draw.ellipse((cx + cw / 2 - knob_r, y + 148 * scale, cx + cw / 2 + knob_r, y + 148 * scale + knob_r * 2), fill=COLORS["steel"], outline=color, width=4)
    mx = x + 3 * (cw + gap)
    draw_text(draw, (mx + cw / 2, y), "MASTER", int(17 * scale), rgba(COLORS["bone"], 190), True, "ma")
    for col in range(3):
        for row in range(8):
            color = COLORS["red"] if row > 5 else (COLORS["amber"] if row > 2 else COLORS["cyan"])
            alpha = 245 if row + col < 7 else 58
            bx = mx + cw / 2 - 22 * scale + col * 15 * scale
            by = y + 38 * scale + (7 - row) * 12 * scale
            draw.rounded_rectangle((bx, by, bx + 10 * scale, by + 7 * scale), radius=2, fill=rgba(color, alpha))


def base_ui(size, mode):
    img = cover_background(size)
    draw = ImageDraw.Draw(img, "RGBA")
    scale = size[0] / 1290
    margin = 54 * scale
    panel_w = size[0] - margin * 2
    y = 72 * scale

    if size[0] > 1500:
        scale = size[0] / 2064
        margin = 130 * scale
        panel_w = size[0] - margin * 2
        y = 112 * scale

    panel(draw, (margin, y, panel_w, 370 * scale), "SALVAGED UNIT")
    draw_text(draw, (margin + 48 * scale, y + 74 * scale), "DRIFT", int(84 * scale), COLORS["bone"], True)
    draw_text(draw, (margin + 52 * scale, y + 172 * scale), "TECHNO ENGINE", int(23 * scale), COLORS["amber"], True)
    draw_text(draw, (margin + panel_w - 56 * scale, y + 82 * scale), "READY", int(22 * scale), COLORS["cyan"], True, "ra")
    draw_text(draw, (margin + panel_w - 56 * scale, y + 124 * scale), "120 BPM", int(22 * scale), COLORS["cyan"], True, "ra")
    led_scope(draw, margin + 44 * scale, y + 245 * scale, panel_w - 88 * scale, 78 * scale, mode == "sequencer")

    y += 394 * scale
    deck_button(draw, (margin, y, panel_w / 2 - 8 * scale, 86 * scale), "GENERATE", COLORS["amber"])
    deck_button(draw, (margin + panel_w / 2 + 8 * scale, y, panel_w / 2 - 8 * scale, 86 * scale), "PLAY", COLORS["cyan"])

    if mode in ("main", "control"):
        y += 112 * scale
        h = 960 * scale if mode == "control" else 860 * scale
        panel(draw, (margin, y, panel_w, h), "PATCH BAY")
        draw_text(draw, (margin + 38 * scale, y + 70 * scale), "STYLE", int(22 * scale), rgba(COLORS["white"], 160), True)
        style_buttons(draw, margin + 38 * scale, y + 112 * scale, panel_w - 76 * scale, 78 * scale)
        rotor(draw, size[0] / 2, y + 386 * scale, 205 * scale)
        sliders(draw, margin + 38 * scale, y + 620 * scale, panel_w - 76 * scale, scale)
        draw_text(draw, (margin + 38 * scale, y + 790 * scale), "ROOT KEY", int(22 * scale), rgba(COLORS["white"], 160), True)
        keys(draw, margin + 38 * scale, y + 838 * scale, panel_w - 76 * scale, scale)

    if mode == "sequencer":
        y += 112 * scale
        panel(draw, (margin, y, panel_w, 470 * scale), "16 STEP SEQUENCER")
        sequencer(draw, margin + 38 * scale, y + 80 * scale, panel_w - 76 * scale, scale, True)
        y += 494 * scale
        panel(draw, (margin, y, panel_w, 330 * scale), "SCRAP MIXER")
        mixer(draw, margin + 38 * scale, y + 76 * scale, panel_w - 76 * scale, 230 * scale, scale)

    return img.convert("RGB")


def save_all():
    OUT.mkdir(parents=True, exist_ok=True)
    specs = [
        ("iphone-67", (1290, 2796), "iphone67"),
        ("ipad-13", (2064, 2752), "ipad13"),
    ]
    screens = [("01-main", "main"), ("02-control", "control"), ("03-sequencer", "sequencer")]
    for prefix, size, marketing_name in specs:
        marketing_dir = MARKETING / marketing_name
        marketing_dir.mkdir(parents=True, exist_ok=True)
        for index, (suffix, mode) in enumerate(screens, start=1):
            image = base_ui(size, mode)
            out_file = OUT / f"{prefix}-{suffix}.png"
            image.save(out_file, optimize=True)
            shutil.copyfile(out_file, marketing_dir / f"{marketing_name}_{index:02d}.png")


if __name__ == "__main__":
    save_all()
