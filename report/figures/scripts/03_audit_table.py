#!/usr/bin/env python3
from pathlib import Path
from common import *

ROOT = Path(__file__).resolve().parents[1]
lines = [line.strip().split("\t") for line in (ROOT / "data/audit-zero-param-full.tsv").read_text().splitlines() if line.strip() and line.startswith("pgvector_bench")]
image, draw, body = canvas("Zero-parameter catalog audit on OpenTenBase", "")
headers = ["index", "type", "rows", "dims", "lists", "rec. lists", "pred. MB", "work_mem MB", "risk"]
fields = [2, 3, 4, 5, 6, 7, 8, 9, 10]
xs = [115, 300, 410, 510, 600, 700, 810, 950, 1090]
draw.rectangle((20, 100, 1170, 170), fill="#E7E1D6");
for x, h in zip(xs, headers):
    label(draw, x, 135, h, size=14)
    body.append(f'<text x="{x}" y="140" text-anchor="middle" font-family="Arial,sans-serif" font-size="14" fill="{TEXT}">{h}</text>')
for r, row in enumerate(lines):
    y = 230 + r * 90; fill = "#F3EEE8" if r % 2 == 0 else "#FFFFFF"; draw.rectangle((20, y - 38, 1170, y + 38), fill=fill)
    vals = [row[i] or "-" for i in fields]
    for col, (x, value) in enumerate(zip(xs, vals)):
        if col == 0:
            label(draw, x - 85, y, value, size=12, anchor="lm")
            body.append(f'<text x="{x - 85}" y="{y + 4}" text-anchor="start" font-family="Arial,sans-serif" font-size="12" fill="{TEXT}">{value}</text>')
        else:
            label(draw, x, y, value, size=14)
            body.append(f'<text x="{x}" y="{y + 5}" text-anchor="middle" font-family="Arial,sans-serif" font-size="14" fill="{TEXT}">{value}</text>')
draw.text((35, 500), "HNSW leaves IVFFlat-only fields blank; predicted build memory is 1 MB for the IVFFlat row.", fill="#5F6D62", font=font(16)); body.append(f'<text x="35" y="505" font-family="Arial,sans-serif" font-size="16" fill="#5F6D62">HNSW leaves IVFFlat-only fields blank; predicted build memory is 1 MB for the IVFFlat row.</text>')
finish(image, body, ROOT / "output/03_audit_table")
