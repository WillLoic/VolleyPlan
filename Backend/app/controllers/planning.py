from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.planning import PlanningService
from app.services.excel_export import generer_excel_planning
from app.utils.decorators import premium_plus_required, premium_required
from app.services.partage_planning import PartagePublicService

planning_bp = Blueprint("plannings", __name__)


@planning_bp.route("/list", methods=["GET"])
@jwt_required()
def list_plannings():
    coach_id = int(get_jwt_identity())
    plannings = PlanningService.get_all(coach_id)
    return jsonify([p.to_dict(include_seances=False) for p in plannings]), 200


@planning_bp.route("/<int:planning_id>", methods=["GET"])
@jwt_required()
def get_one(planning_id):
    coach_id = int(get_jwt_identity())
    planning, error = PlanningService.get_by_id(planning_id, coach_id)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(planning.to_dict(include_seances=True)), 200


@planning_bp.route("/view_invite/<int:planning_id>/<token>", methods=["GET"])
def view_invite_get(planning_id, token):
    planning, error = PlanningService.get_by_id(planning_id, None, invitation_token=token)
    if error:
        return jsonify({"error": error}), 400
    data = planning.to_dict(include_seances=True)
    from app.models.joueurs import Joueur
    roster = Joueur.query.filter_by(coach_id=planning.coach_id, actif=True).all()
    data["owner_roster"] = [j.to_dict() for j in roster]
    return jsonify(data), 200
    


@planning_bp.route("/add_planning", methods=["POST"])
@jwt_required()
def create():
    coach_id = int(get_jwt_identity())
    data = request.get_json()
    required = ["titre", "mode", "duree", "nb_seances"]
    if not all(k in data for k in required):
        return jsonify({"error": "Champs manquants."}), 400

    planning, error = PlanningService.create(coach_id, data)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(planning.to_dict(include_seances=True)), 200


@planning_bp.route("/update_planning/<int:planning_id>", methods=["PUT"])
@jwt_required()
def update(planning_id):
    coach_id = get_jwt_identity()
    data = request.get_json()
    planning, error = PlanningService.update(planning_id, data, coach_id)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(planning.to_dict(include_seances=True)), 200


@planning_bp.route("/update_invite/<int:planning_id>/<token>", methods=["PUT"])
def update_invite(planning_id, token):
    data = request.get_json()
    # On passe coach_id=None car l'identification se fait via le token
    planning, error = PlanningService.update(planning_id, data, None, invitation_token=token)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(planning.to_dict(include_seances=True)), 200


@planning_bp.route("/delete_planning/<int:planning_id>", methods=["DELETE"])
@jwt_required()
def delete(planning_id):
    coach_id = int(get_jwt_identity())
    ok, error = PlanningService.delete(planning_id, coach_id)
    if not ok:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Planning supprimé."}), 200

@planning_bp.route("/check_overlap", methods=["POST"])
@jwt_required()
def check_overlap():
    coach_id = int(get_jwt_identity())
    data = request.get_json()
    overlap = PlanningService.find_overlap(
        coach_id,
        data.get("date_seance"),
        data.get("heure_debut"),
        data.get("planning_id")
    )
    if overlap:
        return jsonify({
            "overlap": True,
            "message": f"Une séance ('{overlap.titre}') est déjà prévue à cette date et heure dans le planning '{overlap.planning.titre}'."
        }), 200
    return jsonify({"overlap": False}), 200





@planning_bp.route("/<int:planning_id>/export/excel", methods=["GET"])
@jwt_required()
#@premium_required
def export_excel(planning_id):
    coach_id = int(get_jwt_identity())
    buffer, error = generer_excel_planning(planning_id, coach_id)
    if error:
        return jsonify({"error": error}), 400

    return send_file(
        buffer,
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        as_attachment=True,
        download_name=f"planning_{planning_id}.xlsx",
    )



@planning_bp.route("/<int:planning_id>/partage", methods=["POST"])
@jwt_required()
#@premium_required
def generer_partage(planning_id):
    coach_id = int(get_jwt_identity())
    partage, error = PartagePublicService.generer_ou_regenerer_lien(coach_id, planning_id)
    if error:
        return jsonify({"error": error}), 400

    from flask import current_app
    frontend_url = current_app.config.get("FRONTEND_URL", "http://localhost:50736/#")

    return jsonify({
        **partage.to_dict(),
        "url": f"{frontend_url}/public/planning/{partage.token}",
    }), 200


@planning_bp.route("/<int:planning_id>/partage", methods=["GET"])
@jwt_required()
#@premium_plus_required
def get_partage_actuel(planning_id):
    coach_id = int(get_jwt_identity())
    partage, error = PartagePublicService.get_lien_actuel(coach_id, planning_id)
    if error:
        return jsonify({"error": error}), 400
    if not partage:
        return jsonify({"partage": None}), 200

    from flask import current_app
    frontend_url = current_app.config.get("FRONTEND_URL", "https://volleyplan.app")

    return jsonify({
        **partage.to_dict(),
        "url": f"{frontend_url}/public/planning/{partage.token}",
    }), 200