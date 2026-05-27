from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table,
    TableStyle, HRFlowable, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT
import io
from datetime import datetime

# Palette
RED    = colors.HexColor("#D72638")
YELLOW = colors.HexColor("#F2B705")
DARK   = colors.HexColor("#1A1A2E")
GRAY   = colors.HexColor("#6B7280")
LIGHT  = colors.HexColor("#F3F4F6")
WHITE  = colors.white

DOMAIN_LABELS = {
    "service":   "Service",
    "reception": "Réception",
    "passe":     "Passe",
    "attaque":   "Attaque",
    "block":     "Block",
    "defense":   "Défense",
    "physique":  "Physique",
    "general":   "Général",
}

def fmt_min(minutes):
    if not minutes:
        return "0min"
    h, m = divmod(int(minutes), 60)
    return f"{h}h{m:02d}" if h else f"{m}min"

def generate_planning_pdf(planning, bilan: dict) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4,
        topMargin=1.5*cm, bottomMargin=1.5*cm,
        leftMargin=1.8*cm, rightMargin=1.8*cm,
    )

    styles = getSampleStyleSheet()
    story  = []

    # ── En-tête ───────────────────────────────────────────────────
    title_style = ParagraphStyle("title", fontSize=22, fontName="Helvetica-Bold",
                                 textColor=RED, spaceAfter=4, alignment=TA_CENTER)
    sub_style   = ParagraphStyle("sub",   fontSize=11, fontName="Helvetica",
                                 textColor=GRAY, spaceAfter=2, alignment=TA_CENTER)
    story.append(Paragraph("🏐 VolleyPlan", title_style))
    story.append(Paragraph(planning.titre, ParagraphStyle("ptitle", fontSize=14,
        fontName="Helvetica-Bold", textColor=DARK, alignment=TA_CENTER, spaceAfter=4)))

    mode_label = "Groupe" if planning.mode == "groupe" else f"Individuel — {planning.poste or ''}"
    story.append(Paragraph(f"{mode_label}  ·  {planning.duree.capitalize()}  ·  {planning.nb_seances} séances", sub_style))
    
    if planning.date_debut:
        fin_str = planning.date_fin.strftime('%d/%m/%Y') if planning.date_fin else "..."
        story.append(Paragraph(f"Période : du {planning.date_debut.strftime('%d/%m/%Y')} au {fin_str}", sub_style))
    story.append(Paragraph(f"Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M')}", sub_style))
    story.append(HRFlowable(width="100%", thickness=2, color=RED, spaceAfter=12))

    # ── Résumé global ─────────────────────────────────────────────
    section_style = ParagraphStyle("section", fontSize=13, fontName="Helvetica-Bold",
                                   textColor=DARK, spaceBefore=10, spaceAfter=6)
    story.append(Paragraph("Résumé", section_style))

    summary_data = [
        ["Joueurs concernés", ", ".join(j.nom for j in planning.joueurs) or "—"],
        ["Nombre de séances",  str(bilan["nb_seances"])],
        ["Volume total",       fmt_min(bilan["total_minutes"])],
        ["Durée moy./séance",  fmt_min(bilan["avg_seance_minutes"])],
    ]
    summary_table = Table(summary_data, colWidths=[5*cm, 12*cm])
    summary_table.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (0,-1), LIGHT),
        ("FONTNAME",   (0,0), (0,-1), "Helvetica-Bold"),
        ("FONTSIZE",   (0,0), (-1,-1), 10),
        ("TEXTCOLOR",  (0,0), (0,-1), DARK),
        ("TEXTCOLOR",  (1,0), (1,-1), GRAY),
        ("ROWBACKGROUNDS", (0,0), (-1,-1), [WHITE, LIGHT]),
        ("BOX",        (0,0), (-1,-1), 0.5, GRAY),
        ("INNERGRID",  (0,0), (-1,-1), 0.3, GRAY),
        ("TOPPADDING", (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
        ("LEFTPADDING",   (0,0), (-1,-1), 8),
    ]))
    story.append(summary_table)
    story.append(Spacer(1, 0.4*cm))

    # ── Répartition par domaine ───────────────────────────────────
    story.append(Paragraph("Répartition par domaine", section_style))
    domain_header = [["Domaine", "Volume", "Proportion"]]
    domain_rows   = []
    for d in bilan["domain_stats"]:
        if d["minutes"] > 0:
            bar = "█" * (d["pct"] // 5) + "░" * (20 - d["pct"] // 5)
            domain_rows.append([
                DOMAIN_LABELS.get(d["id"], d["id"]),
                fmt_min(d["minutes"]),
                f"{d['pct']}%  {bar}",
            ])
    if domain_rows:
        dt = Table(domain_header + domain_rows, colWidths=[4*cm, 3*cm, 10*cm])
        dt.setStyle(TableStyle([
            ("BACKGROUND",    (0,0), (-1,0), DARK),
            ("TEXTCOLOR",     (0,0), (-1,0), WHITE),
            ("FONTNAME",      (0,0), (-1,0), "Helvetica-Bold"),
            ("FONTSIZE",      (0,0), (-1,-1), 9),
            ("ROWBACKGROUNDS",(0,1), (-1,-1), [WHITE, LIGHT]),
            ("BOX",           (0,0), (-1,-1), 0.5, GRAY),
            ("INNERGRID",     (0,0), (-1,-1), 0.3, GRAY),
            ("TOPPADDING",    (0,0), (-1,-1), 5),
            ("BOTTOMPADDING", (0,0), (-1,-1), 5),
            ("LEFTPADDING",   (0,0), (-1,-1), 8),
        ]))
        story.append(dt)
    story.append(Spacer(1, 0.4*cm))

    # ── Détail des séances ────────────────────────────────────────
    story.append(Paragraph("Programme des séances", section_style))

    label_style = ParagraphStyle("label", fontSize=9, fontName="Helvetica",
                                 textColor=GRAY, spaceAfter=2)
    ex_style    = ParagraphStyle("ex", fontSize=9, fontName="Helvetica",
                                 textColor=DARK, leftIndent=10, spaceAfter=1)

    for i, seance in enumerate(planning.seances):
        seance_dur = sum(e.duree for e in (seance.exercices or []))

        bloc = []
        # Titre séance
        titre_s = ParagraphStyle(f"st{i}", fontSize=11, fontName="Helvetica-Bold",
                                  textColor=WHITE, backColor=RED,
                                  leftIndent=6, rightIndent=6,
                                  spaceBefore=8, spaceAfter=4, borderPadding=4)
        date_str = ""
        if seance.date_seance:
            date_str = f"  —  {seance.date_seance.strftime('%d/%m/%Y')}"
            if seance.heure_debut:
                date_str += f" à {seance.heure_debut}"
        lieu_str = f"  —  {seance.lieu}" if seance.lieu else ""
        bloc.append(Paragraph(
            f"Séance {i+1} : {seance.titre}{date_str}{lieu_str}  ({fmt_min(seance_dur)})",
            titre_s
        ))

        # Domaines
        domaines_str = "  ·  ".join(DOMAIN_LABELS.get(d, d) for d in (seance.domaines or []))
        if domaines_str:
            bloc.append(Paragraph(f"Domaines : {domaines_str}", label_style))

        # Exercices
        if seance.exercices:
            ex_data = [["#", "Exercice", "Domaine", "Durée"]]
            for j, ex in enumerate(seance.exercices):
                ex_data.append([
                    str(j+1),
                    ex.nom,
                    DOMAIN_LABELS.get(ex.domaine, ex.domaine),
                    f"{ex.duree}min",
                ])
            ex_table = Table(ex_data, colWidths=[0.8*cm, 9*cm, 3.5*cm, 2.2*cm])
            ex_table.setStyle(TableStyle([
                ("BACKGROUND",    (0,0), (-1,0), LIGHT),
                ("FONTNAME",      (0,0), (-1,0), "Helvetica-Bold"),
                ("FONTSIZE",      (0,0), (-1,-1), 9),
                ("ROWBACKGROUNDS",(0,1), (-1,-1), [WHITE, "#F9F9F9"]),
                ("BOX",           (0,0), (-1,-1), 0.3, GRAY),
                ("INNERGRID",     (0,0), (-1,-1), 0.2, GRAY),
                ("TOPPADDING",    (0,0), (-1,-1), 4),
                ("BOTTOMPADDING", (0,0), (-1,-1), 4),
                ("LEFTPADDING",   (0,0), (-1,-1), 6),
                ("ALIGN",         (3,0), (3,-1), "CENTER"),
            ]))
            bloc.append(ex_table)
        else:
            bloc.append(Paragraph("Aucun exercice défini.", label_style))

        story.append(KeepTogether(bloc))
        story.append(Spacer(1, 0.3*cm))

    # ── Recommandations ───────────────────────────────────────────
    if bilan.get("recommandations"):
        story.append(HRFlowable(width="100%", thickness=1, color=YELLOW, spaceAfter=8))
        story.append(Paragraph("Recommandations du coach", section_style))
        for rec in bilan["recommandations"]:
            story.append(Paragraph(f"• {rec}", ParagraphStyle("rec", fontSize=9,
                fontName="Helvetica", textColor=DARK, leftIndent=10, spaceAfter=4)))

    # ── Footer ────────────────────────────────────────────────────
    story.append(Spacer(1, 0.5*cm))
    story.append(HRFlowable(width="100%", thickness=1, color=LIGHT))
    story.append(Paragraph(
        "Document généré par VolleyPlan Coach Edition",
        ParagraphStyle("footer", fontSize=8, textColor=GRAY, alignment=TA_CENTER, spaceBefore=4)
    ))

    doc.build(story)
    buffer.seek(0)
    return buffer.read()