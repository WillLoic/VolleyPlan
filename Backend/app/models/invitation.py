from app import db
from datetime import datetime, timedelta
import secrets

class Invitation(db.Model):
    __tablename__ = "invitations"

    id               = db.Column(db.Integer, primary_key=True)
    planning_id      = db.Column(db.Integer, db.ForeignKey("plannings.id"), nullable=False)
    sender_coach_id  = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False)
    invited_email    = db.Column(db.String(120), nullable=False)
    token            = db.Column(db.String(100), unique=True, nullable=False)
    status           = db.Column(db.String(20), default="pending") # pending, accepted, revoked, expired
    expiration_date  = db.Column(db.DateTime, nullable=False)
    created_at       = db.Column(db.DateTime, default=datetime.utcnow)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.token:
            self.token = secrets.token_urlsafe(32)
        if not self.expiration_date:
            self.expiration_date = datetime.utcnow() + timedelta(days=3)

    def to_dict(self):
        return {
            "id": self.id,
            "planning_id": self.planning_id,
            "invited_email": self.invited_email,
            "status": self.status,
            "expiration_date": self.expiration_date.isoformat(),
            "created_at": self.created_at.isoformat()
        }
    
def app_context(app):
     with app.app_context():
         db.create_all()