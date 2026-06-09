from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.feedbacks import FeedbacksService
feedbacks_bp = Blueprint('feedbacks', __name__)

@feedbacks_bp.route('/add_feedbacks', methods=['POST'])
@jwt_required()
def add_feedback():
    current_user_id = get_jwt_identity()
    data = request.get_json()
    feedback, error = FeedbacksService.add_feedback(current_user_id, data)
    if error:
        return jsonify({"error": str(error)}), 400
    return jsonify({"feedback": feedback.to_dict()}), 200


#POUR L'ADMINISTRATEUR
@feedbacks_bp.route('/get_feedbacks/<int:feedback_id>', methods=['GET'])
@jwt_required()
def get_feedback(feedback_id):
    current_user_id = get_jwt_identity()
    feedback = FeedbacksService.get_feedback(feedback_id, current_user_id)
    if not feedback:
        return jsonify({"error": "Feedback not found"}), 404
    return jsonify({"feedback": feedback.to_dict()}), 200

@feedbacks_bp.route('/get_all_feedbacks', methods=['GET'])
@jwt_required()
def get_all_feedbacks():
    feedbacks = FeedbacksService.get_all_feedbacks()
    return jsonify({"feedbacks": [feedback.to_dict() for feedback in feedbacks]}), 200