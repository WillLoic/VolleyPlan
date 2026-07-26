from flask import Blueprint, jsonify
from flask_jwt_extended import get_jwt_identity, jwt_required
from app.utils.decorators import premium_required
from app.services.stats_joueurs import StatsJoueursService

stats_bp = Blueprint("stats", __name__)

@stats_bp.route("/joueur/<int:joueur_id>/radar", methods=["GET"])
#@jwt_required()
@premium_required
def get_radar(joueur_id):
    coach_id = int(get_jwt_identity())
    resultat = StatsJoueursService.get_radar_joueur(joueur_id, coach_id)
    if not resultat.get("success"):
        return jsonify({"error": resultat.get("message")}), 400
    return jsonify(resultat), 200

@stats_bp.route("/joueur/<int:joueur_id>", methods=["GET"])
#@jwt_required()
@premium_required
def get_individual_stats(joueur_id):
    coach_id = int(get_jwt_identity())
    resultat = StatsJoueursService.get_stats_joueur(joueur_id, coach_id)
    if not resultat.get("success"):
        return jsonify({"error": resultat.get("message")}), 400
    return jsonify(resultat), 200

@stats_bp.route("/equipe/comparaison", methods=["GET"])
#@jwt_required()
@premium_required
def get_team_comparison():
    coach_id = int(get_jwt_identity())
    resultat = StatsJoueursService.get_comparaison_equipe(coach_id)
    if not resultat.get("success"):
        return jsonify({"error": resultat.get("message")}), 400
    return jsonify(resultat), 200
