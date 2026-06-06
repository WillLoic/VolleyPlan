from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
#from app.services.auth import register_coach, login_coach, get_coach_by_id
from app.services.auth import AuthService
from app.services.password_reset import PasswordReset

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    required = ["nom", "telephone", "nom_equipe", "password", "email"]
    if not all(k in data for k in required):
        return jsonify({"error": "Champs manquants."}), 400

    result, error = AuthService.register(
        data["nom"], data["telephone"], data["nom_equipe"], data["password"], data["email"]
    )
    if error:
        return jsonify({"error": error}), 409
    return jsonify(result), 200


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    if not data.get("email") or not data.get("password"):
        return jsonify({"error": "Email et mot de passe requis."}), 400

    result, error = AuthService.login(data["email"], data["password"])
    if error:
        return jsonify({"error": error}), 401
    return jsonify(result), 200


@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    coach_id = int(get_jwt_identity())
    coach = AuthService.get_coach_by_id(coach_id)
    if not coach:
        return jsonify({"error": "Coach introuvable."}), 404
    return jsonify(coach.to_dict()), 200

@auth_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    data = request.get_json()
    email = data.get("email")
    if not email:
        return jsonify({"error": "Email requis"}), 400
    
    success, message = PasswordReset.request_reset(email)
    if not success:
        return jsonify({"error": message}), 500
    return jsonify({"message": message}), 200

@auth_bp.route("/reset-password", methods=["POST"])
def reset_password():
    data = request.get_json()
    token = data.get("token")
    new_password = data.get("password")
    if not token or not new_password:
        return jsonify({"error": "Données manquantes"}), 400
    
    success, error = PasswordReset.reset_password(token, new_password)
    if not success:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Mot de passe réinitialisé avec succès"}), 200