from app import db
from datetime import datetime
from sqlalchemy import UniqueConstraint

class RapportMensuel(db.Model):
    __tablename__ = "rapports_mensuels"
    id          = db.Column(db.Integer, primary_key=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id", ondelete="CASCADE"), nullable=False)
    coach_id    = db.Column(db.Integer, db.ForeignKey("coaches.id", ondelete="CASCADE"), nullable=False)
    periode_debut = db.Column(db.Date, nullable=False)
    periode_fin   = db.Column(db.Date, nullable=False)
    donnees     = db.Column(db.JSON, nullable=False)  # snapshot complet du rapport
    genere_auto = db.Column(db.Boolean, default=True)  # False si généré à la demande
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("planning_id", "periode_debut", "periode_fin"),
    )



"""from datetime import datetime
from app import db


class RapportMensuel(db.Model):
    __tablename__ = "rapports_mensuels"

    id            = db.Column(db.Integer, primary_key=True)
    planning_id   = db.Column(db.Integer, db.ForeignKey("plannings.id", ondelete="CASCADE"), nullable=False)
    coach_id      = db.Column(db.Integer, db.ForeignKey("coaches.id", ondelete="CASCADE"), nullable=False)
    periode_debut = db.Column(db.Date, nullable=False)
    periode_fin   = db.Column(db.Date, nullable=False)
    donnees       = db.Column(db.JSON, nullable=False)
    genere_auto   = db.Column(db.Boolean, default=True)
    created_at    = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("planning_id", "periode_debut", "periode_fin", name="uq_rapport_periode"),
    )

    def to_dict(self):
        return {
            "id":            self.id,
            "planning_id":   self.planning_id,
            "periode_debut": self.periode_debut.isoformat(),
            "periode_fin":   self.periode_fin.isoformat(),
            "donnees":       self.donnees,
            "genere_auto":   self.genere_auto,
            "created_at":    self.created_at.isoformat(),
        }
"""

def app_context(app):
    with app.app_context():
        db.create_all()