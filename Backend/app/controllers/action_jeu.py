from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.action_jeu import ActionJeu
# pyrefly: ignore [missing-import]
from app.utils.domaines_action_config import DOMAINES_ACTION_CONFIG
from app.utils.decorators import basic_required,premium_required,premium_plus_required

action_jeu_bp = Blueprint("actions_jeu", __name__)


@action_jeu_bp.route("/config", methods=["GET"])
@jwt_required()
#@premium_required
def get_config():
    """Retourne la configuration des domaines pour que le frontend puisse la vérifier / se synchroniser."""
    return jsonify(DOMAINES_ACTION_CONFIG), 200


@action_jeu_bp.route("/seance/<int:seance_id>/exercice/<int:exercice_id>/actions", methods=["POST"])
@jwt_required()
#@premium_required
def enregistrer_batch(seance_id, exercice_id):
    coach_id = int(get_jwt_identity())
    data = request.get_json() or {}
    actions = data.get("actions", [])

    if not actions:
        return jsonify({"error": "Aucune action à enregistrer"}), 400

    ids, error = ActionJeu.enregistrer_actions_exercice(coach_id, seance_id, exercice_id, actions)
    if error:
        return jsonify({"error": error}), 400

    return jsonify({"success": True, "ids": ids, "count": len(ids)}), 200


@action_jeu_bp.route("/exercice/<int:exercice_id>/joueur/<int:joueur_id>/stats", methods=["GET"])
@jwt_required()
#@premium_required
def stats_joueur_exercice(exercice_id, joueur_id):
    stats = ActionJeu.get_stats_exercice_pour_joueur(exercice_id, joueur_id)
    return jsonify(stats), 200


@action_jeu_bp.route("/exercice/<int:exercice_id>/stats", methods=["GET"])
@jwt_required()
#@premium_required
def stats_exercice(exercice_id):
    stats = ActionJeu.get_stats_exercice_complet(exercice_id)
    return jsonify(stats), 200


@action_jeu_bp.route("/seance/<int:seance_id>/stats", methods=["GET"])
@jwt_required()
#@premium_required
def stats_seance(seance_id):
    stats = ActionJeu.get_stats_seance_complete(seance_id)
    return jsonify(stats), 200


@action_jeu_bp.route("/action/<int:action_id>", methods=["DELETE"])
@jwt_required()
#@premium_required
def supprimer(action_id):
    coach_id = int(get_jwt_identity())
    ok, error = ActionJeu.supprimer_action(coach_id, action_id)
    if not ok:
        return jsonify({"error": error}), 400
    return jsonify({"success": True}), 200
