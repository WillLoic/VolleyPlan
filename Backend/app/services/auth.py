from ..models.coach import Coach
from .. import db
from flask_jwt_extended import create_access_token

class AuthService:

    @staticmethod
    def register(nom, telephone, nom_equipe, password, email):
        if Coach.query.filter_by(telephone=telephone).first():
            return None, "Ce numéro de téléphone est déjà utilisé"
        if Coach.query.filter_by(email=email).first():
            return None, "Cet email est déjà utilisé"
        coach = Coach(nom=nom, telephone=telephone, nom_equipe=nom_equipe, email=email)
        coach.set_password(password)
        db.session.add(coach)
        db.session.commit()
        token = create_access_token(identity=str(coach.id))
        #return {"token":token,"msg":"Vous etes enregistre et connecte"}, None
        return {"token":token,"coach":coach.to_dict(), "msg":"Vous etes enregiste"}, None
        #return "nouveau coach enregistre", None

    @staticmethod
    def login(telephone, password):
        coach = Coach.query.filter_by(telephone=telephone).first()
        if not coach or not coach.check_password(password):
            return None, "Numéro ou mot de passe incorrect"
        
        from .invitation import InvitationService
        InvitationService.claim_collaborations(coach.id, coach.telephone) # On peut adapter selon si on utilise email ou tel
        
        token = create_access_token(identity=str(coach.id))
        return {"token":token,"coach":coach.to_dict(), "msg":"Vous etes enregistr"}, None
        #return {"token":token,"msg":"Vous etes connecte"}, None
    
    @staticmethod
    def get_coach_by_id(coach_id):
        return Coach.query.get(coach_id)