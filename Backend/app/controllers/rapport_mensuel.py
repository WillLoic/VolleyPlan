from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import io

from app.models.rapport_mensuel import RapportMensuel
from app.models.planning import Planning
from app.services.rapport_mensuel import generer_rapport_a_la_demande
from app.services.pdf import generer_pdf_rapport_mensuel
from app.utils.decorators import premium_required

rapport_bp = Blueprint("rapports", __name__)


@rapport_bp.route("/<int:planning_id>/rapports", methods=["GET"])
@premium_required
#@jwt_required()
def list_rapports(planning_id):
    coach_id = int(get_jwt_identity())
    planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
    if not planning:
        return jsonify({"error": "Planning introuvable ou accès refusé"}), 400

    rapports = (
        RapportMensuel.query.filter_by(planning_id=planning_id)
        .order_by(RapportMensuel.periode_debut.desc())
        .all()
    )
    return jsonify([r.to_dict() for r in rapports]), 200


@rapport_bp.route("/<int:planning_id>/rapports/<int:rapport_id>", methods=["GET"])
@premium_required
#@jwt_required()
def get_rapport(planning_id, rapport_id):
    coach_id = int(get_jwt_identity())
    planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
    if not planning:
        return jsonify({"error": "Planning introuvable ou accès refusé"}), 400

    rapport = RapportMensuel.query.filter_by(id=rapport_id, planning_id=planning_id).first()
    if not rapport:
        return jsonify({"error": "Rapport introuvable"}), 404

    return jsonify(rapport.to_dict()), 200


@rapport_bp.route("/<int:planning_id>/rapports/generer", methods=["POST"])
@premium_required
#@jwt_required()
def generer_rapport(planning_id):
    coach_id = int(get_jwt_identity())
    data = request.get_json() or {}

    try:
        periode_debut = datetime.strptime(data["periode_debut"], "%Y-%m-%d").date()
        periode_fin   = datetime.strptime(data["periode_fin"], "%Y-%m-%d").date()
    except (KeyError, ValueError):
        return jsonify({"error": "periode_debut et periode_fin requis au format YYYY-MM-DD"}), 400

    rapport, error = generer_rapport_a_la_demande(coach_id, planning_id, periode_debut, periode_fin)
    if error:
        return jsonify({"error": error}), 400

    return jsonify(rapport.to_dict()), 200


@rapport_bp.route("/<int:planning_id>/rapports/<int:rapport_id>/pdf", methods=["GET"])
@jwt_required()
def download_rapport_pdf(planning_id, rapport_id):
    coach_id = int(get_jwt_identity())
    planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
    if not planning:
        return jsonify({"error": "Planning introuvable ou accès refusé"}), 400

    rapport = RapportMensuel.query.filter_by(id=rapport_id, planning_id=planning_id).first()
    if not rapport:
        return jsonify({"error": "Rapport introuvable"}), 404

    pdf_bytes = generer_pdf_rapport_mensuel(rapport.donnees, planning)
    return send_file(
        io.BytesIO(pdf_bytes),
        mimetype="application/pdf",
        as_attachment=True,
        download_name=f"rapport_mensuel_{planning.titre}.pdf",
    )