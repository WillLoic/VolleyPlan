from .. import db
from datetime import datetime

class AnalyticsEvent(db.Model):
    __tablename__ = 'analytics_events'

    id = db.Column(db.Integer, primary_key=True)
    # user_id est nullable car on peut traquer des événements avant que le coach soit connecté
    user_id = db.Column(db.Integer, db.ForeignKey('coaches.id'), nullable=True)
    event_name = db.Column(db.String(100), nullable=False, index=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    event_data = db.Column(db.JSON, nullable=True) # Stockage flexible pour les détails
    session_id = db.Column(db.String(100), nullable=True, index=True)

    coach = db.relationship('Coach', backref=db.backref('analytics_events', lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "event_name": self.event_name,
            "timestamp": self.timestamp.isoformat(),
            "event_data": self.event_data,
            "session_id": self.session_id
        }