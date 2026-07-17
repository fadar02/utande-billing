import os
from io import BytesIO
from flask import current_app
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.enums import TA_CENTER, TA_LEFT


def generate_pdf(title, headers, rows, filename=None):
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=30, bottomMargin=30)
    styles = getSampleStyleSheet()
    elements = []

    title_style = ParagraphStyle(
        'CustomTitle', parent=styles['Heading1'], alignment=TA_CENTER, spaceAfter=20
    )
    elements.append(Paragraph(title, title_style))
    elements.append(Spacer(1, 12))

    header_style = ParagraphStyle(
        'HeaderCell', parent=styles['Normal'], fontSize=8, leading=10, alignment=TA_CENTER
    )
    cell_style = ParagraphStyle(
        'DataCell', parent=styles['Normal'], fontSize=8, leading=10, alignment=TA_LEFT
    )

    formatted_headers = [Paragraph(str(h), header_style) for h in headers]
    formatted_rows = []
    for row in rows:
        formatted_rows.append([Paragraph(str(cell), cell_style) for cell in row])

    all_data = [formatted_headers] + formatted_rows
    num_cols = len(headers)
    col_width = (A4[0] - 60) / num_cols
    col_widths = [col_width] * num_cols

    table = Table(all_data, colWidths=col_widths, repeatRows=1)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
        ('BACKGROUND', (0, 1), (-1, -1), colors.white),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f2f4f7')]),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
        ('TOPPADDING', (0, 1), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 5),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))

    elements.append(table)
    doc.build(elements)
    buffer.seek(0)
    return buffer


def save_pdf_to_file(buffer, subfolder, filename):
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, 'wb') as f:
        f.write(buffer.read())
    return filepath
