#!/usr/bin/env python3
import html
import re
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Image, ListFlowable, ListItem

REPORT_DIR = Path(__file__).resolve().parent
ROOT = REPORT_DIR.parent
OUT = REPORT_DIR / "build" / "OpenTenBase-pgvector-index-diagnostics-report.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)
font_reg = "/System/Library/Fonts/STHeiti Light.ttc"
font_bold = "/System/Library/Fonts/STHeiti Medium.ttc"
if Path(font_reg).exists():
    pdfmetrics.registerFont(TTFont("ReportCN", font_reg, subfontIndex=0))
    pdfmetrics.registerFont(TTFont("ReportCN-Bold", font_bold, subfontIndex=0))
else:
    pdfmetrics.registerFont(TTFont("ReportCN", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"))
    pdfmetrics.registerFont(TTFont("ReportCN-Bold", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"))

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CNBody", parent=styles["BodyText"], fontName="ReportCN", fontSize=9.5, leading=15, spaceAfter=7))
styles.add(ParagraphStyle(name="CNH1", parent=styles["Heading1"], fontName="ReportCN-Bold", fontSize=18, leading=24, textColor=colors.HexColor("#31433A"), spaceAfter=14))
styles.add(ParagraphStyle(name="CNH2", parent=styles["Heading2"], fontName="ReportCN-Bold", fontSize=12.5, leading=17, textColor=colors.HexColor("#5F6D62"), spaceBefore=8, spaceAfter=7))
styles.add(ParagraphStyle(name="CNSmall", parent=styles["BodyText"], fontName="ReportCN", fontSize=8, leading=11, textColor=colors.HexColor("#5F6D62")))
styles.add(ParagraphStyle(name="CNTitle", parent=styles["Title"], fontName="ReportCN-Bold", fontSize=24, leading=31, alignment=TA_CENTER, textColor=colors.HexColor("#31433A"), spaceAfter=20))

def inline(text):
    text = html.escape(text, quote=False)
    def code(match):
        value = match.group(1)
        return f'<font name="Courier">{value}</font>' if value.isascii() else value
    return re.sub(r"`([^`]+)`", code, text).replace("**", "")

def page_decor(canvas, doc):
    canvas.saveState(); canvas.setStrokeColor(colors.HexColor("#D8D1C7")); canvas.line(1.6 * cm, 1.35 * cm, 19.4 * cm, 1.35 * cm)
    canvas.setFont("ReportCN", 8); canvas.setFillColor(colors.HexColor("#7A847E")); canvas.drawString(1.6 * cm, 0.85 * cm, "OpenTenBase pgvector 实战开发报告"); canvas.drawRightString(19.4 * cm, 0.85 * cm, f"{doc.page}"); canvas.restoreState()

def add_markdown(story, path):
    lines = path.read_text(encoding="utf-8").splitlines(); i = 0; bullets = []
    def flush():
        nonlocal bullets
        if bullets:
            story.append(ListFlowable([ListItem(Paragraph(inline(x), styles["CNBody"])) for x in bullets], bulletType="bullet", leftIndent=15)); bullets = []
    while i < len(lines):
        line = lines[i].strip()
        if not line: flush(); i += 1; continue
        if line.startswith("# "): flush(); story.append(Paragraph(inline(line[2:]), styles["CNH1"])); i += 1; continue
        if line.startswith("## "): flush(); story.append(Paragraph(inline(line[3:]), styles["CNH2"])); i += 1; continue
        if line.startswith("- "): bullets.append(line[2:]); i += 1; continue
        if line.startswith("|"):
            flush(); table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(set(c) <= set("-:") for c in cells): table_lines.append(cells)
                i += 1
            if table_lines:
                width = 17.8 * cm / max(len(table_lines[0]), 1)
                table = Table([[Paragraph(inline(c), styles["CNSmall"]) for c in row] for row in table_lines], colWidths=[width] * len(table_lines[0]), repeatRows=1)
                table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E7E1D6")), ("GRID", (0, 0), (-1, -1), 0.3, colors.HexColor("#D8D1C7")), ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5)])); story.append(table); story.append(Spacer(1, 8)); continue
        flush(); story.append(Paragraph(inline(line), styles["CNBody"])); i += 1
    flush()

story = [Spacer(1, 4 * cm), Paragraph("OpenTenBase pgvector 索引诊断增强", styles["CNTitle"]), Paragraph("技术报告与可复现证据包", styles["CNH2"]), Spacer(1, 2 * cm), Paragraph("报告版本：2026-08-18 | G4 + G10 evidence line", styles["CNBody"]), PageBreak()]
chapters = sorted(ROOT.glob("report/[0-9][0-9]-*.md"))
for n, chapter in enumerate(chapters):
    add_markdown(story, chapter)
    if chapter.name.startswith("07-"):
        story.append(Spacer(1, 8)); story.append(Paragraph("正文图表", styles["CNH2"]))
        for name in ["01_formula_log", "02_error_matrix", "03_audit_table"]:
            story.append(Image(str(ROOT / "report/figures/output" / f"{name}.png"), width=17.2 * cm, height=8.75 * cm)); story.append(Spacer(1, 8))
    if n < len(chapters) - 1: story.append(PageBreak())
doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=1.6 * cm, leftMargin=1.6 * cm, topMargin=1.5 * cm, bottomMargin=1.65 * cm, title="OpenTenBase pgvector index diagnostics report", author="OpenTenBase project")
doc.build(story, onFirstPage=page_decor, onLaterPages=page_decor)
print(OUT)
