from app import db
from datetime import datetime

class Notification(db.Model):
    __tablename__ = "notifications"

    id         = db.Column(db.Integer, primary_key=True)
    coach_id   = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False) # Destinataire (le proprio)
    message    = db.Column(db.String(500), nullable=False)
    is_read    = db.Column(db.Boolean, default=False)
    type       = db.Column(db.String(50), default="general")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relation avec les séances (optionnel, pour linker les notifs aux séances)
    seance_id  = db.Column(db.Integer, db.ForeignKey("seances.id", ondelete="SET NULL"), nullable=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id", ondelete="SET NULL"), nullable=True)  # ← NOUVEAU
    seance     = db.relationship("Seance", backref=db.backref("notifications", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "message": self.message,
            "is_read": self.is_read,
            "type": self.type,
            "seance_id": self.seance_id,
            "planning_id": self.planning_id,  # ← NOUVEAU
            "created_at": self.created_at.isoformat()
        }

def app_context(app):
     with app.app_context():
         db.create_all()
    #pass