from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.seances import Seance
from app.models.planning import Planning

seance_bp = Blueprint("seances", __name__)


@seance_bp.route("/<int:seance_id>", methods=["GET"])
@jwt_required()
def get_seance(seance_id):
    coach_id = int(get_jwt_identity())
    seance = Seance.query.get(seance_id)
    if not seance:
        return jsonify({"error": "Séance introuvable."}), 400

    # Vérifier que la séance appartient au coach
    planning = Planning.query.filter_by(id=seance.planning_id, coach_id=coach_id).first()
    if not planning:
        return jsonify({"error": "Accès refusé."}), 403

    return jsonify(seance.to_dict(include_exercices=True)), 200