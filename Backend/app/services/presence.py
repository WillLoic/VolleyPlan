from datetime import datetime, timedelta
from app import db
from app.models.seances import Seance
from app.models.presences import Absence
from app.models.planning import Planning

class PresenceService:

    @staticmethod
    def _verifier_appartenance(coach_id: int, seance: Seance) -> bool:
        """
        Vérifie que la séance appartient bien au coach connecté.
        """
        if not seance or not seance.planning:
            return False
        return seance.planning.coach_id == coach_id

    @staticmethod
    def marquer_absences(coach_id: int, seance_id: int, absences_data: list) -> dict:
        """
        Marque les absences pour une séance.
        absences_data = [{"joueur_id": 3, "motif": "blessure"}, ...]
        """
        seance = Seance.query.get(seance_id)
        if not seance:
            return {"success": False, "message": "Séance introuvable"}

        if not PresenceService._verifier_appartenance(coach_id, seance):
            return {"success": False, "message": "Séance non autorisée pour ce coach"}

        # Vérifier si la séance a une date
        if not seance.date_seance:
            return {"success": False, "message": "La séance doit avoir une date planifiée pour marquer les présences"}

        # Calculer le début de la séance
        try:
            h_debut = datetime.strptime(seance.heure_debut or "00:00", "%H:%M").time()
        except Exception:
            from datetime import time
            h_debut = time(0, 0)
        
        seance_datetime = datetime.combine(seance.date_seance, h_debut)

        # Vérifier si la fenêtre est ouverte (heure_debut + 10h)
        if datetime.utcnow() < seance_datetime: #+ timedelta(hours=10):
            return {
                "success": False, 
                "message": "La fenêtre de saisie des présences n'est pas encore ouverte (10 heures après le début de la séance)"
            }

        try:
            # Supprimer les anciennes absences de cette séance (pour ré-écriture/correction)
            Absence.query.filter_by(seance_id=seance_id).delete()

            # Ajouter les nouvelles absences
            planning_joueur_ids = [j.id for j in seance.planning.joueurs]
            for abs_item in absences_data:
                j_id = abs_item.get("joueur_id")
                motif = abs_item.get("motif")
                if j_id in planning_joueur_ids:
                    nouvelle_absence = Absence(
                        seance_id=seance_id,
                        joueur_id=j_id,
                        motif=motif
                    )
                    db.session.add(nouvelle_absence)

            # Mettre à jour le statut de la séance
            seance.presences_prises = True
            seance.presences_auto = False
            db.session.commit()

            return {"success": True, "message": "Présences enregistrées avec succès"}

        except Exception as e:
            db.session.rollback()
            return {"success": False, "message": f"Erreur lors de l'enregistrement : {str(e)}"}

    @staticmethod
    def get_presences_seance(coach_id: int, seance_id: int) -> dict:
        """
        Retourne l'état des présences d'une séance.
        """
        seance = Seance.query.get(seance_id)
        if not seance:
            return {"success": False, "message": "Séance introuvable"}

        if not PresenceService._verifier_appartenance(coach_id, seance):
            return {"success": False, "message": "Séance non autorisée pour ce coach"}

        # Calculer si la fenêtre est ouverte
        fenetre_ouverte = False
        if seance.date_seance:
            try:
                h_debut = datetime.strptime(seance.heure_debut or "00:00", "%H:%M").time()
            except Exception:
                from datetime import time
                h_debut = time(0, 0)
            seance_datetime = datetime.combine(seance.date_seance, h_debut)
            fenetre_ouverte = datetime.utcnow() >= seance_datetime + timedelta(hours=10)

        # Récupérer les absences existantes
        absences = Absence.query.filter_by(seance_id=seance_id).all()
        absences_dict = {a.joueur_id: a.motif for a in absences}

        # Pour chaque joueur du planning, vérifier s'il est absent
        joueurs_res = []
        for joueur in seance.planning.joueurs:
            est_absent = joueur.id in absences_dict
            joueurs_res.append({
                "joueur": joueur.to_dict(),
                "present": not est_absent,
                "motif": absences_dict.get(joueur.id) if est_absent else None
            })

        return {
            "success": True,
            "seance": seance.to_dict(),
            "presences_prises": seance.presences_prises,
            "presences_auto": seance.presences_auto,
            "fenetre_ouverte": fenetre_ouverte,
            "joueurs": joueurs_res
        }
