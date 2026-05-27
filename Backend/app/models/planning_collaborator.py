from app import db
from datetime import datetime

class PlanningCollaborator(db.Model):
    __tablename__ = "planning_collaborators"

    id          = db.Column(db.Integer, primary_key=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id"), nullable=False)
    coach_id    = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=True)
    email       = db.Column(db.String(120), nullable=False)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "planning_id": self.planning_id,
            "coach_id": self.coach_id,
            "email": self.email
        }

def app_context(app):
     with app.app_context():
         db.create_all()