from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.coach import CoachService

coach_bp = Blueprint('coach', __name__)

@coach_bp.route('/me', methods=['PUT'])
@jwt_required()
def update_profile():
    current_user_id = get_jwt_identity()
    data = request.get_json()
    coach, error = CoachService.update_profil(current_user_id, data)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(coach.to_dict()), 200