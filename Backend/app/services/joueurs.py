from ..models.joueurs import Joueur
from .. import db

class JoueurService:

    @staticmethod
    def get_all(coach_id, include_inactifs=False):
        query = Joueur.query.filter_by(coach_id=coach_id)
        if not include_inactifs:
            query = query.filter_by(actif=True)
        return query.order_by(Joueur.nom).all()

    @staticmethod
    def get_by_id(joueur_id, coach_id):
        return Joueur.query.filter_by(id=joueur_id, coach_id=coach_id).first()

    @staticmethod
    def create(coach_id, data):
        joueur = Joueur(
            coach_id = coach_id,
            nom      = data.get("nom", "").strip(),
            #prenom   = data.get("prenom", "").strip() or None,
            poste    = data.get("poste", "").strip() or None,
            #numero   = data.get("numero"),
        )
        db.session.add(joueur)
        db.session.commit()
        return joueur, None

    @staticmethod
    def update(joueur_id, data, coach_id):
        joueur = Joueur.query.filter_by(id=joueur_id, coach_id=coach_id).first()
        if not joueur:
            return None, "joueur non trouve"
        if "nom"    in data: joueur.nom    = data["nom"].strip()
        #if "prenom" in data: joueur.prenom = data["prenom"].strip() or None
        if "poste"  in data: joueur.poste  = data["poste"].strip() or None
        #if "numero" in data: joueur.numero = data["numero"]
        if "actif"  in data: joueur.actif  = data["actif"]
        db.session.commit()
        return joueur, None

    @staticmethod
    def delete(joueur_id, coach_id):
        # Soft delete — on désactive le joueur
        joueur = Joueur.query.filter_by(id=joueur_id, coach_id=coach_id).first()
        if not joueur:
            return None, "joueur non trouve"
        joueur.actif = False
        db.session.commit()
        return "Joueur desactive", None

    @staticmethod
    def hard_delete(joueur_id, coach_id):
        joueur = Joueur.query.filter_by(id=joueur_id, coach_id=coach_id).first()
        if not joueur:
            return None, "joueur non trouve"
        db.session.delete(joueur)
        db.session.commit()
        return "joueur definitivement supprime", None