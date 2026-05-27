from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.invitation import InvitationService

invitation_bp = Blueprint("invitations", __name__)

@invitation_bp.route("/send", methods=["POST"])
@jwt_required()
def send_invitation():
    coach_id = int(get_jwt_identity())
    data = request.get_json()
    planning_id = data.get("planning_id")
    email = data.get("email")
    
    if not planning_id or not email:
        return jsonify({"error": "Données manquantes"}), 400
        
    invitation, error = InvitationService.create_invitation(planning_id, coach_id, email)
    if error:
        return jsonify({"error": error}), 400
        
    return jsonify(invitation.to_dict()), 200

@invitation_bp.route("/validate/<token>", methods=["GET"])
def validate_token(token):
    invitation, error = InvitationService.validate_token(token)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(invitation.to_dict()), 200

@invitation_bp.route("/view_planning/<token>", methods=["GET"])
def view_planning_by_token(token):
    planning, error = InvitationService.get_planning_by_token(token)
    if error:
        return jsonify({"error": error}), 400
    return jsonify(planning.to_dict(include_seances=True)), 200

@invitation_bp.route("/accept", methods=["POST"])
def accept_invitation():
    data = request.get_json()
    token = data.get("token")
    coach_id = data.get("coach_id") # Optionnel : si l'invité est connecté
    
    collaborator, error = InvitationService.accept_invitation(token, coach_id)
    if error:
        return jsonify({"error": error}), 400
        
    return jsonify(collaborator.to_dict()), 200

@invitation_bp.route("/planning/<int:planning_id>/collaborators/<string:email>", methods=["DELETE"])
@jwt_required()
def remove_collaborator(planning_id, email):
    coach_id = int(get_jwt_identity())
    ok, error = InvitationService.remove_collaborator(planning_id, email, coach_id)
    if not ok:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Collaborateur retiré"}), 200