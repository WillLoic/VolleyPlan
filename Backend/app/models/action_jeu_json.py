from datetime import datetime
from app import db


class ActionJeuJSON(db.Model):
    __tablename__ = "actions_jeu_json"

    id          = db.Column(db.Integer, primary_key=True)
    seance_id   = db.Column(db.Integer, db.ForeignKey("seances.id", ondelete="CASCADE"), nullable=False, index=True)
    exercice_id = db.Column(db.Integer, db.ForeignKey("exercices.id", ondelete="CASCADE"), nullable=False, index=True)
    joueur_id   = db.Column(db.Integer, db.ForeignKey("joueurs.id", ondelete="CASCADE"), nullable=False, index=True)
    domaine     = db.Column(db.String(20), nullable=False, index=True)
    donnees     = db.Column(db.JSON, nullable=False)  # {"type_action": "smashe", "position": "6", ...}
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id, "seance_id": self.seance_id, "exercice_id": self.exercice_id,
            "joueur_id": self.joueur_id, "domaine": self.domaine,
            "donnees": self.donnees, "created_at": self.created_at.isoformat(),
        }


def app_context(app):
    with app.app_context():
        db.create_all()