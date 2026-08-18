#!/usr/bin/env python3
import csv, math
from pathlib import Path
from common import *

ROOT = Path(__file__).resolve().parents[1]
rows = list(csv.DictReader((ROOT / "data/memory_model_matrix.csv").open()))
image, draw, body = canvas("Source-derived memory model versus deprecated formula", "Memory requirement (MB, log scale)")
ypos = axis(draw, body, 100000, ticks=5, log=True)
n = len(rows); colors = {"predicted_mb": "#7F8F84", "old_formula_mb": "#B7A99A", "observed_mb": "#8A9199"}
for i, row in enumerate(rows):
    x = LEFT + i * PLOT_W / max(1, n - 1)
    points = []
    for key in ["old_formula_mb", "predicted_mb", "observed_mb"]:
        value = float(row[key]); y = ypos(value); points.append((x, y, colors[key]))
        draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=colors[key]); body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="{colors[key]}"/>')
    for (_, y1, c1), (_, y2, _) in zip(points, points[1:]):
        draw.line((x, y1, x, y2), fill=c1, width=2); body.append(f'<line x1="{x:.1f}" y1="{y1:.1f}" x2="{x:.1f}" y2="{y2:.1f}" stroke="{c1}" stroke-width="2"/>')
    if i % 2 == 0:
        label(draw, x, TOP + PLOT_H + 24, f"{i + 1:02d}", size=12); body.append(f'<text x="{x:.1f}" y="{TOP + PLOT_H + 30}" text-anchor="middle" font-family="Arial,sans-serif" font-size="12" fill="{TEXT}">{i + 1:02d}</text>')
legend = [("new / predicted", colors["predicted_mb"]), ("old formula", colors["old_formula_mb"]), ("observed", colors["observed_mb"])]
for i, (name, color) in enumerate(legend):
    x = LEFT + i * 245; draw.ellipse((x, H - 45, x + 14, H - 31), fill=color); label(draw, x + 85, H - 38, name, size=14); body.append(f'<circle cx="{x + 7}" cy="{H - 38}" r="7" fill="{color}"/><text x="{x + 24}" y="{H - 32}" font-family="Arial,sans-serif" font-size="14" fill="{TEXT}">{name}</text>')
finish(image, body, ROOT / "output/01_formula_log")

