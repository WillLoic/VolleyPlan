from functools import wraps
from datetime import datetime
from flask import jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.coach import Coach

def premium_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        coach_id = int(get_jwt_identity())
        coach = Coach.query.get(coach_id)
        if not coach:
            return jsonify({"error": "Coach introuvable"}), 404
        
        # Check if user has PREMIUM subscription and if it's not expired
        if coach.forfait != "PREMIUM":
            return jsonify({
                "error": "Fonctionnalité réservée au forfait Premium",
                "upgrade": True
            }), 403
            
        if coach.expire_forfait and coach.expire_forfait < datetime.utcnow():
            return jsonify({
                "error": "Abonnement Premium expiré",
                "upgrade": True
            }), 403
            
        return fn(*args, **kwargs)
    return wrapper


def basic_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        coach_id = int(get_jwt_identity())
        coach = Coach.query.get(coach_id)
        if not coach:
            return jsonify({"error": "Coach introuvable"}), 404
        
        # Check if user has PREMIUM subscription and if it's not expired
        if coach.forfait != "BASIC":
            return jsonify({
                "error": "Fonctionnalité réservée au forfait Basic",
                "upgrade": True
            }), 403
            
        if coach.expire_forfait and coach.expire_forfait < datetime.utcnow():
            return jsonify({
                "error": "Abonnement Basic expiré",
                "upgrade": True
            }), 403
            
        return fn(*args, **kwargs)
    return wrapper

def premium_plus_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        coach_id = int(get_jwt_identity())
        coach = Coach.query.get(coach_id)
        if not coach:
            return jsonify({"error": "Coach introuvable"}), 404
        
        # Check if user has PREMIUM subscription and if it's not expired
        if coach.forfait != "PREMIUM_PLUS":
            return jsonify({
                "error": "Fonctionnalité réservée au forfait Premium Plus",
                "upgrade": True
            }), 403
            
        if coach.expire_forfait and coach.expire_forfait < datetime.utcnow():
            return jsonify({
                "error": "Abonnement Premium Plus expiré",
                "upgrade": True
            }), 403
            
        return fn(*args, **kwargs)
    return wrapper

