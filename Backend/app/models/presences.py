from app import db
from datetime import datetime
from sqlalchemy import UniqueConstraint


class Absence(db.Model):
    """
    On ne stocke que les ABSENCES.
    Si presences_prises = True et qu'aucun enregistrement n'existe
    pour (seance_id, joueur_id), le joueur est considéré PRÉSENT.
    """
    __tablename__ = "absences"

    id         = db.Column(db.Integer, primary_key=True)
    seance_id  = db.Column(db.Integer, db.ForeignKey("seances.id",  ondelete="CASCADE"), nullable=False)
    joueur_id  = db.Column(db.Integer, db.ForeignKey("joueurs.id",  ondelete="CASCADE"), nullable=False)
    motif      = db.Column(db.String(200), nullable=True)   # raison de l'absence (optionnel)
    marked_at  = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("seance_id", "joueur_id", name="uq_absence_seance_joueur"),
    )

    def to_dict(self):
        return {
            "id":        self.id,
            "seance_id": self.seance_id,
            "joueur_id": self.joueur_id,
            "motif":     self.motif,
            "marked_at": self.marked_at.isoformat() if self.marked_at else None,
        }


def app_context(app):
    with app.app_context():
        db.create_all()
