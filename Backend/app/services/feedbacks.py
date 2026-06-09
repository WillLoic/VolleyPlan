from ..models.feedbacks import Feedbacks
from .. import db

class FeedbacksService:

    @staticmethod
    def add_feedback(coach_id,data):
        feedback = Feedbacks(commentaire=data.get("commentaire", "").strip(),
                              coach_id=coach_id)

        db.session.add(feedback)
        db.session.commit()
        return feedback, None

    @staticmethod
    def get_feedback(feedback_id,coach_id):
        feedback = Feedbacks.query.filter_by(id=feedback_id,coach_id=coach_id).first()
        return feedback
    
    @staticmethod
    def get_all_feedbacks():
        feedbacks = Feedbacks.query.order_by(Feedbacks.create_at.desc()).all()
        return feedbacks