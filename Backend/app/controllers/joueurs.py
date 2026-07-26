from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.joueurs import JoueurService
from app.utils.decorators import premium_required
from app.services.presence import PresenceService

joueur_bp = Blueprint("joueurs", __name__)


@joueur_bp.route("/list_joueurs", methods=["GET"])
@jwt_required()
def list_joueurs():
    coach_id = int(get_jwt_identity())
    include_inactifs = request.args.get("inactifs", "false").lower() == "true"
    joueurs = JoueurService.get_all(coach_id, include_inactifs=include_inactifs)
    return jsonify([j.to_dict() for j in joueurs]), 200


@joueur_bp.route("/add_joueurs", methods=["POST"])
@jwt_required()
def add_joueur():
    coach_id = int(get_jwt_identity())
    data = request.get_json()
    if not data.get("nom"):
        return jsonify({"error": "Le nom est requis."}), 400

    joueur, error = JoueurService.create(coach_id, data)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(joueur.to_dict()), 200


@joueur_bp.route("/update/<int:joueur_id>", methods=["PUT"])
@jwt_required()
def update(joueur_id):
    coach_id = int(get_jwt_identity())
    data = request.get_json()
    joueur, error = JoueurService.update(joueur_id, data, coach_id)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(joueur.to_dict()), 200


@joueur_bp.route("/delete/<int:joueur_id>", methods=["DELETE"])
@jwt_required()
def remove(joueur_id):
    coach_id = int(get_jwt_identity())
    ok, error = JoueurService.delete(joueur_id, coach_id)
    if not ok:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Joueur désactivé."}), 200

@joueur_bp.route("/hard_delete/<int:joueur_id>",methods=["DELETE"])
@jwt_required()
def hard_delete(joueur_id):
    coach_id = int(get_jwt_identity())
    ok, error = JoueurService.hard_delete(joueur_id, coach_id)
    if not ok:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Joueur completement supprimé."}), 200


@joueur_bp.route("/seance/<int:seance_id>/presences", methods=["GET"])
@jwt_required()
#@premium_required
def get_seance_presences(seance_id):
    coach_id = int(get_jwt_identity())
    resultat = PresenceService.get_presences_seance(coach_id, seance_id)
    if not resultat.get("success"):
        return jsonify({"error": resultat.get("message")}), 400
    return jsonify(resultat), 200


@joueur_bp.route("/seance/<int:seance_id>/absences", methods=["POST"])
@jwt_required()
#@premium_required
def post_seance_absences(seance_id):
    coach_id = int(get_jwt_identity())
    data = request.get_json() or {}
    absences_list = data.get("absences", [])
    
    resultat = PresenceService.marquer_absences(coach_id, seance_id, absences_list)
    if not resultat.get("success"):
        return jsonify({"error": resultat.get("message")}), 400
    return jsonify(resultat), 200

