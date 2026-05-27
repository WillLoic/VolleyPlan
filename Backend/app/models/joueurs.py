from app import db
from datetime import datetime

# Table d'association planning <-> joueur
planning_joueurs = db.Table(
    "planning_joueurs",
    db.Column("planning_id", db.Integer, db.ForeignKey("plannings.id"), primary_key=True),
    db.Column("joueur_id",   db.Integer, db.ForeignKey("joueurs.id"),   primary_key=True),
)


class Joueur(db.Model):
    __tablename__ = "joueurs"

    id         = db.Column(db.Integer, primary_key=True)
    coach_id   = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False)
    nom        = db.Column(db.String(100), nullable=False)
    poste      = db.Column(db.String(50), nullable=True)   # Passeur, Libéro, Central, etc.
    actif      = db.Column(db.Boolean, default=True)       # False = transféré/parti
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id":         self.id,
            "coach_id":   self.coach_id,
            "nom":        self.nom,
            "poste":      self.poste,
            "actif":      self.actif,
            "created_at": self.created_at.isoformat(),
        }
    
def app_context(app):
    with app.app_context():
        db.create_all()