from app import db
from datetime import datetime

class Feedbacks(db.Model):
    __tablename__ = "feedbacks"

    id = db.Column(db.Integer, primary_key=True)
    coach_id   = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False)
    commentaire = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    status     = db.Column(db.String(20), default='pending') # pending, processed

    def to_dict(self):
        return{
            "id" : self.id,
            "coach_id" : self.coach_id,
            "commentaire" : self.commentaire,
            "created_at" : self.created_at.isoformat() if self.created_at else None,
            "status" : self.status
        }
    
def app_context(app):
     with app.app_context():
         db.create_all()