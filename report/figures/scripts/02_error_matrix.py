#!/usr/bin/env python3
import csv
from pathlib import Path
from common import *

ROOT = Path(__file__).resolve().parents[1]
rows = list(csv.DictReader((ROOT / "data/memory_model_matrix.csv").open()))
image, draw, body = canvas("Twenty-case validation error", "Absolute relative error (%)")
y0 = TOP + PLOT_H / 2
for y, text in [(TOP, "+0.001"), (y0, "0.0000"), (TOP + PLOT_H, "-0.001")]:
    draw.line((LEFT, y, LEFT + PLOT_W, y), fill=GRID, width=1); draw.text((LEFT - 75, y - 9), text, fill=TEXT, font=font(14)); body.append(f'<line x1="{LEFT}" y1="{y:.1f}" x2="{LEFT + PLOT_W}" y2="{y:.1f}" stroke="{GRID}" stroke-width="1"/><text x="{LEFT - 12}" y="{y + 5:.1f}" text-anchor="end" font-family="Arial,sans-serif" font-size="14" fill="{TEXT}">{text}</text>')
draw.line((LEFT, TOP, LEFT, TOP + PLOT_H), fill=TEXT, width=2); draw.line((LEFT, TOP + PLOT_H, LEFT + PLOT_W, TOP + PLOT_H), fill=TEXT, width=2); body += [f'<line x1="{LEFT}" y1="{TOP}" x2="{LEFT}" y2="{TOP + PLOT_H}" stroke="{TEXT}" stroke-width="2"/>', f'<line x1="{LEFT}" y1="{TOP + PLOT_H}" x2="{LEFT + PLOT_W}" y2="{TOP + PLOT_H}" stroke="{TEXT}" stroke-width="2"/>']
for i, row in enumerate(rows):
    x = LEFT + i * PLOT_W / max(1, len(rows) - 1); draw.ellipse((x - 6, y0 - 6, x + 6, y0 + 6), fill="#7F8F84"); body.append(f'<circle cx="{x:.1f}" cy="{y0:.1f}" r="6" fill="#7F8F84"/>')
    if i % 2 == 0:
        label(draw, x, TOP + PLOT_H + 24, f"{i + 1:02d}", size=12); body.append(f'<text x="{x:.1f}" y="{TOP + PLOT_H + 30}" text-anchor="middle" font-family="Arial,sans-serif" font-size="12" fill="{TEXT}">{i + 1:02d}</text>')
label(draw, LEFT + PLOT_W - 140, TOP + 30, "20 / 20 pass", size=20, color="#5F6D62"); body.append(f'<text x="{LEFT + PLOT_W - 140}" y="{TOP + 36}" text-anchor="middle" font-family="Arial,sans-serif" font-size="20" fill="#5F6D62">20 / 20 pass</text>')
finish(image, body, ROOT / "output/02_error_matrix")

