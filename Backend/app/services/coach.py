from .. import db
from ..models.coach import Coach

class CoachService:


    @staticmethod
    def update_profil(coach_id,data):
        coach = Coach.query.get(coach_id)
        if not coach :
            return None, "pas de coach a cette id"
        coach.nom = data.get("nom", "").strip()
        coach.telephone = data.get("telephone", "").strip()
        coach.nom_equipe = data.get("nom_equipe", "").strip()
        db.session.commit()
        return coach, None