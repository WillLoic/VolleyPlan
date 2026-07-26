from app import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash


class Coach(db.Model):
    __tablename__ = "coaches"

    id            = db.Column(db.Integer, primary_key=True)
    nom           = db.Column(db.String(100), nullable=False)
    telephone     = db.Column(db.String(20), unique=True, nullable=False)
    nom_equipe    = db.Column(db.String(100), nullable=False)
    email         = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role          = db.Column(db.String(20), default="user", nullable=False)
    created_at    = db.Column(db.DateTime, default=datetime.utcnow)
    #paiement
    forfait = db.Column(db.String(20), default = "DECOUVERTE") # PREMIUM, PROFESSIONNAL
    expire_forfait = db.Column(db.DateTime, default=None)


    # Relations
    joueurs     = db.relationship("Joueur",       backref="coach", lazy=True, cascade="all, delete-orphan")
    plannings   = db.relationship("Planning",     backref="coach", lazy=True, cascade="all, delete-orphan")
    abonnements = db.relationship("Subscription", backref="coach", lazy=True, cascade="all, delete-orphan")
    paiements   = db.relationship("Payments",     backref="coach", lazy=True, cascade="all, delete-orphan")


    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id":             self.id,
            "nom":            self.nom,
            "telephone":      self.telephone,
            "nom_equipe":     self.nom_equipe,
            "email":          self.email,
            "role":           self.role,
            "created_at":     self.created_at.isoformat(),
            "forfait":        self.forfait or "DECOUVERTE",
            "expire_forfait": self.expire_forfait.isoformat() if self.expire_forfait else None,
        }
    
def app_context(app):
    with app.app_context():
        db.create_all()