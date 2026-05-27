from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.notification import Notification
from app import db

notification_bp = Blueprint("notifications", __name__)

@notification_bp.route("/list", methods=["GET"])
@jwt_required()
def list_notifications():
    coach_id = int(get_jwt_identity())
    notifs = Notification.query.filter_by(coach_id=coach_id, is_read=False)\
                               .order_by(Notification.created_at.desc()).all()
    return jsonify({"data": [n.to_dict() for n in notifs]}), 200

@notification_bp.route("/read/<int:notif_id>", methods=["PUT"])
@jwt_required()
def mark_as_read(notif_id):
    coach_id = int(get_jwt_identity())
    notif = Notification.query.filter_by(id=notif_id, coach_id=coach_id).first()
    if notif:
        notif.is_read = True
        db.session.commit()
    return jsonify({"status": "ok"}), 200