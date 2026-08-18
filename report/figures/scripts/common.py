from pathlib import Path
from html import escape
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 620
LEFT, RIGHT, TOP, BOTTOM = 125, 55, 72, 115
PLOT_W, PLOT_H = W - LEFT - RIGHT, H - TOP - BOTTOM
BG, GRID, TEXT = "#FFFFFF", "#D8D1C7", "#27302C"

def font(size):
    for path in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def canvas(title, ylabel):
    image = Image.new("RGB", (W, H), BG); draw = ImageDraw.Draw(image)
    draw.text((LEFT, 20), title, fill=TEXT, font=font(25)); draw.text((24, TOP + PLOT_H // 2), ylabel, fill=TEXT, font=font(17))
    body = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">', '<rect width="100%" height="100%" fill="#FFFFFF"/>', f'<text x="{LEFT}" y="42" font-family="Arial,sans-serif" font-size="25" fill="{TEXT}">{escape(title)}</text>']
    return image, draw, body

def axis(draw, body, ymax, ticks=5, log=False):
    def ypos(value):
        if log:
            import math
            lo, hi = 0, math.log10(ymax)
            return TOP + PLOT_H - PLOT_H * (math.log10(max(value, 1)) - lo) / (hi - lo)
        return TOP + PLOT_H - PLOT_H * value / ymax
    for i in range(ticks + 1):
        value = 10 ** i if log else ymax * i / ticks
        y = ypos(value); draw.line((LEFT, y, LEFT + PLOT_W, y), fill=GRID, width=1); draw.text((LEFT - 85, y - 9), f"{value:g}", fill=TEXT, font=font(14))
        body += [f'<line x1="{LEFT}" y1="{y:.1f}" x2="{LEFT + PLOT_W}" y2="{y:.1f}" stroke="{GRID}" stroke-width="1"/>', f'<text x="{LEFT - 12}" y="{y + 5:.1f}" text-anchor="end" font-family="Arial,sans-serif" font-size="14" fill="{TEXT}">{value:g}</text>']
    draw.line((LEFT, TOP, LEFT, TOP + PLOT_H), fill=TEXT, width=2); draw.line((LEFT, TOP + PLOT_H, LEFT + PLOT_W, TOP + PLOT_H), fill=TEXT, width=2)
    body += [f'<line x1="{LEFT}" y1="{TOP}" x2="{LEFT}" y2="{TOP + PLOT_H}" stroke="{TEXT}" stroke-width="2"/>', f'<line x1="{LEFT}" y1="{TOP + PLOT_H}" x2="{LEFT + PLOT_W}" y2="{TOP + PLOT_H}" stroke="{TEXT}" stroke-width="2"/>']
    return ypos

def label(draw, x, y, text, size=14, color=TEXT, anchor="mm"):
    f = font(size); box = draw.textbbox((0, 0), text, font=f); tw, th = box[2] - box[0], box[3] - box[1]
    if anchor == "mm": x -= tw / 2; y -= th / 2
    elif anchor == "lm": y -= th / 2
    draw.text((x, y), text, fill=color, font=f)

def finish(image, body, stem):
    stem = Path(stem); stem.parent.mkdir(parents=True, exist_ok=True); image.save(stem.with_suffix(".png"), dpi=(180, 180)); body.append("</svg>"); stem.with_suffix(".svg").write_text("\n".join(body), encoding="utf-8")
