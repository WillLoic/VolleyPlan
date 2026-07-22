import uuid
from datetime import datetime, timedelta
from app import db

class PartagePublic(db.Model):
    __tablename__ = "partages_planning"
    id          = db.Column(db.Integer, primary_key=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id", ondelete="CASCADE"), nullable=False, unique=True)
    token       = db.Column(db.String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at  = db.Column(db.DateTime, nullable=False)

    @staticmethod
    def generer_expiration():
        return datetime.utcnow() + timedelta(days=15)

    @property
    def est_expire(self):
        return datetime.utcnow() > self.expires_at

    def to_dict(self):
        return {
            "token": self.token,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat(),
            "est_expire": self.est_expire,
        }

def app_context(app):
    with app.app_context():
        db.create_all()
        pass