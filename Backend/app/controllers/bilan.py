from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.bilan import BilanService

bilan_bp = Blueprint("bilan", __name__)


@bilan_bp.route("/<int:planning_id>", methods=["GET"])
@jwt_required()
def get_bilan(planning_id):
    coach_id = int(get_jwt_identity())
    bilan, error = BilanService.compute(coach_id, planning_id, token=request.args.get('token'))
    if error:
        return jsonify({"error": error}), 404
    return jsonify(bilan), 200

@bilan_bp.route("/global", methods=["GET"])
@jwt_required()
def get_global_bilan():
    coach_id = int(get_jwt_identity())
    bilan, error = BilanService.compute_global(coach_id)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(bilan), 200

@bilan_bp.route("/token/<token>", methods=["GET"])
def get_bilan_public(token):
    bilan, error = BilanService.compute(None, 0, token=token)
    if error:
        return jsonify({"error": error}), 404
    return jsonify(bilan), 200