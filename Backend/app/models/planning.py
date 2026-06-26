from app import db
from app.models.joueurs import planning_joueurs
from datetime import datetime

from app.models.planning_collaborator import PlanningCollaborator
from app.models.invitation import Invitation

class Planning(db.Model):
    __tablename__ = "plannings"

    id         = db.Column(db.Integer, primary_key=True)
    coach_id   = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False)
    titre      = db.Column(db.String(200), nullable=False)
    mode       = db.Column(db.String(20), nullable=False)   # groupe | individuel
    duree      = db.Column(db.String(20), nullable=False)   # hebdomadaire | mensuel
    nb_seances = db.Column(db.Integer, nullable=False)
    poste      = db.Column(db.String(100), nullable=True)    # si mode individuel
    date_debut = db.Column(db.Date, nullable=True)
    date_fin   = db.Column(db.Date, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relations
    joueurs = db.relationship("Joueur", secondary=planning_joueurs, lazy="subquery")
    seances = db.relationship(
        "Seance", backref="planning", lazy=True,
        cascade="all, delete-orphan", order_by="Seance.ordre"
    )
    collaborators = db.relationship("PlanningCollaborator", backref="planning", cascade="all, delete-orphan")
    invitations   = db.relationship("Invitation", backref="planning", cascade="all, delete-orphan")

    def to_dict(self, include_seances=False):
        data = {
            "id":         self.id,
            "coach_id":   self.coach_id,
            "titre":      self.titre,
            "mode":       self.mode,
            "duree":      self.duree,
            "nb_seances": self.nb_seances,
            "poste":      self.poste,
            "date_debut": self.date_debut.isoformat() if self.date_debut else None,
            "date_fin":   self.date_fin.isoformat() if self.date_fin else None,
            "joueurs":    [j.to_dict() for j in self.joueurs],
            "seances":    [s.to_dict(include_exercices=include_seances) for s in self.seances],#
            "collaborators": [c.to_dict() for c in self.collaborators],
            "invitations":   [i.to_dict() for i in self.invitations if i.status == 'pending'],
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
        """if include_seances:
            data["seances"] = [s.to_dict(include_exercices=True) for s in self.seances]
        return data"""
        return data
    
def app_context(app):
    with app.app_context():
        db.create_all()
        pass