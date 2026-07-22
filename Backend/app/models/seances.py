from app import db
from datetime import datetime


class Seance(db.Model):
    __tablename__ = "seances"

    id          = db.Column(db.Integer, primary_key=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id"), nullable=False)
    titre       = db.Column(db.String(200), nullable=False)
    ordre       = db.Column(db.Integer, default=0)       # position dans le planning
    domaines    = db.Column(db.JSON, default=list)        # ["service","attaque",...]
    date_seance = db.Column(db.Date, nullable=True)       # date prévue (optionnel)
    heure_debut = db.Column(db.String(5), nullable=True)  # "09:00"
    lieu        = db.Column(db.String(100), nullable=True)
    notes       = db.Column(db.Text, nullable=True)
    presences_prises = db.Column(db.Boolean, default=False)
    presences_auto   = db.Column(db.Boolean, default=False)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    # Relations
    exercices = db.relationship(
        "Exercice", backref="seance", lazy=True,
        cascade="all, delete-orphan", order_by="Exercice.ordre"
    )

    def duree_totale(self):
        return sum(e.duree for e in self.exercices)

    def to_dict(self, include_exercices=False):
        data = {
            "id":           self.id,
            "planning_id":  self.planning_id,
            "titre":        self.titre,
            "ordre":        self.ordre,
            "domaines":     self.domaines or [],
            "date_seance":  self.date_seance.isoformat() if self.date_seance else None,
            "heure_debut":  self.heure_debut,
            "lieu":         self.lieu,
            "notes":        self.notes,
            "presences_prises": self.presences_prises,
            "presences_auto":   self.presences_auto,
            "duree_totale": self.duree_totale(),
            "created_at":   self.created_at.isoformat(),
        }
        if include_exercices:
            data["exercices"] = [e.to_dict() for e in self.exercices]
        return data
    
def app_context(app):
    with app.app_context():
        db.create_all()