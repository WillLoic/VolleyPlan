from datetime import datetime
from app import db


class ActionJeu(db.Model):
    __tablename__ = "actions_jeu"

    id           = db.Column(db.Integer, primary_key=True)
    seance_id    = db.Column(db.Integer, db.ForeignKey("seances.id", ondelete="CASCADE"), nullable=False, index=True)
    exercice_id  = db.Column(db.Integer, db.ForeignKey("exercices.id", ondelete="CASCADE"), nullable=False, index=True)
    joueur_id    = db.Column(db.Integer, db.ForeignKey("joueurs.id", ondelete="CASCADE"), nullable=False, index=True)
    domaine      = db.Column(db.String(20), nullable=False, index=True)

    # ── Colonnes génériques (voir section 2.2 du plan) ──────────
    position          = db.Column(db.String(30), nullable=True)
    type_action       = db.Column(db.String(30), nullable=True)
    zone              = db.Column(db.String(30), nullable=True)
    qualite           = db.Column(db.String(30), nullable=True)
    resultat          = db.Column(db.String(30), nullable=True)
    point_direct      = db.Column(db.Boolean, nullable=True)
    touche            = db.Column(db.Boolean, nullable=True)
    nombre_bloqueurs  = db.Column(db.Integer, nullable=True)
    puissance_adverse = db.Column(db.String(20), nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "seance_id": self.seance_id,
            "exercice_id": self.exercice_id,
            "joueur_id": self.joueur_id,
            "domaine": self.domaine,
            "position": self.position,
            "type_action": self.type_action,
            "zone": self.zone,
            "qualite": self.qualite,
            "resultat": self.resultat,
            "point_direct": self.point_direct,
            "touche": self.touche,
            "nombre_bloqueurs": self.nombre_bloqueurs,
            "puissance_adverse": self.puissance_adverse,
            "created_at": self.created_at.isoformat(),
        }


def app_context(app):
    with app.app_context():
        db.create_all()