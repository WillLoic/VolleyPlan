from app import db


class Exercice(db.Model):
    __tablename__ = "exercices"

    id         = db.Column(db.Integer, primary_key=True)
    seance_id  = db.Column(db.Integer, db.ForeignKey("seances.id"), nullable=False)
    nom        = db.Column(db.String(200), nullable=False)
    duree      = db.Column(db.Integer, nullable=False)   # en minutes
    domaine    = db.Column(db.String(50), nullable=True)  # CONSERVÉ pour rollback — ne plus utiliser
    domaines   = db.Column(db.JSON, default=list)         # ["service", "reception", ...] — source de vérité
    description = db.Column(db.Text, nullable=True)
    ordre       = db.Column(db.Integer, default=0)

    def to_dict(self):
        return {
            "id":          self.id,
            "seance_id":   self.seance_id,
            "nom":         self.nom,
            "duree":       self.duree,
            "domaines":    self.domaines or [],
            "description": self.description,
            "ordre":       self.ordre,
        }
    
def app_context(app):
    with app.app_context():
        db.create_all()