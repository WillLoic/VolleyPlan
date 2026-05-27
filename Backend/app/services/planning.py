from ..models.planning import Planning
from ..models.joueurs   import Joueur
from ..models.seances   import Seance
from ..models.exercices import Exercice
from ..models.coach     import Coach
from ..models.notification import Notification
from .. import db
from datetime import datetime
from ..models.planning_collaborator import PlanningCollaborator

class PlanningService:

    @staticmethod
    def get_all(coach_id):
        # Récupérer les IDs des collaborations
        collab_ids = [pc.planning_id for pc in PlanningCollaborator.query.filter_by(coach_id=coach_id).all()]
        # Une seule requête pour éviter les doublons (Owned OR Collaborative)
        query = Planning.query.filter(
            (Planning.coach_id == coach_id) | (Planning.id.in_(collab_ids))
        )
        return query.order_by(Planning.created_at.desc()).all()

    @staticmethod
    def get_by_id(planning_id, coach_id, invitation_token=None):
        planning = Planning.query.filter_by(id=planning_id).first()
        if not planning :
            return None, "aucun planning trouve a cette id"

        is_owner = False
        is_collab = False

        # 1. Vérification par Coach ID (Utilisateur connecté)
        if coach_id:
            try:
                current_user_id = int(coach_id)
                is_owner = planning.coach_id == current_user_id
                is_collab = PlanningCollaborator.query.filter_by(
                    planning_id=planning_id, coach_id=current_user_id
                ).first() is not None
            except (ValueError, TypeError):
                pass

        # 2. Vérification par Token d'invitation (Guest)
        if not is_owner and not is_collab and invitation_token:
            from ..services.invitation import InvitationService
            inv_planning, err = InvitationService.get_planning_by_token(invitation_token)
            if inv_planning and inv_planning.id == planning_id:
                is_collab = True
        
        if not (is_owner or is_collab):
            return None, "Accès refusé"
            
        return planning, None

    @staticmethod
    def create(coach_id, data):
        planning = Planning(
            coach_id   = coach_id,
            titre      = data["titre"].strip(),
            mode       = data["mode"],
            duree      = data["duree"],
            nb_seances = int(data["nb_seances"]),
            poste      = data.get("poste"),
            date_debut = datetime.strptime(data["date_debut"], '%Y-%m-%d').date() if data.get("date_debut") else None,
            date_fin   = datetime.strptime(data["date_fin"], '%Y-%m-%d').date() if data.get("date_fin") else None,
        )
        # Associer les joueurs
        joueur_ids = data.get("joueur_ids", [])
        if joueur_ids:
            joueurs = Joueur.query.filter(
                Joueur.id.in_(joueur_ids),
                Joueur.coach_id == coach_id
            ).all()
            planning.joueurs = joueurs

        db.session.add(planning)
        db.session.flush()  # pour avoir l'id

        # Créer les séances vides si envoyées
        for i, s_data in enumerate(data.get("seances", [])):
            seance = Seance(
                planning_id = planning.id,
                titre       = s_data.get("titre", f"Séance {i+1}"),
                ordre       = i,
                domaines    = s_data.get("domaines", []),
                date_seance = s_data.get("date_seance"),
                heure_debut = s_data.get("heure_debut"),
                lieu        = s_data.get("lieu"),
            )
            db.session.add(seance)
            db.session.flush()

            for j, e_data in enumerate(s_data.get("exercices", [])):
                exercice = Exercice(
                    seance_id   = seance.id,
                    nom         = e_data["nom"].strip(),
                    duree       = int(e_data["duree"]),
                    domaine     = e_data["domaine"],
                    description = e_data.get("description"),
                    ordre       = j,
                )
                db.session.add(exercice)

        db.session.commit()
        return planning, None

    @staticmethod
    def update(planning_id, data, coach_id, invitation_token=None):
        # 1. Sécurisation du type de l'ID (force en entier)
        try:
            current_user_id = int(coach_id)
        except (ValueError, TypeError):
            current_user_id = coach_id

        planning = Planning.query.filter_by(id=planning_id).first()
        if not planning :
            return None, "aucun planning trouve a cet id"
        
        # 2. Vérification des permissions
        is_owner = planning.coach_id == current_user_id
        is_collab = PlanningCollaborator.query.filter_by(
            planning_id=planning_id, coach_id=current_user_id
        ).first() is not None
        print(is_owner, is_collab)
        if not (is_owner or is_collab):
            return None, "Accès refusé : vous n'êtes pas membre du staff"

        # Seul le proprio change les métadonnées
        if is_owner:
            if "titre"      in data: planning.titre      = data["titre"].strip()
            if "mode"       in data: planning.mode       = data["mode"]
            if "duree"      in data: planning.duree      = data["duree"]
            if "nb_seances" in data: planning.nb_seances = int(data["nb_seances"])
            if "poste"      in data: planning.poste      = data.get("poste")
            if "date_debut" in data: planning.date_debut = datetime.strptime(data["date_debut"], '%Y-%m-%d').date() if data["date_debut"] else None
            if "date_fin"   in data: planning.date_fin   = datetime.strptime(data["date_fin"], '%Y-%m-%d').date() if data["date_fin"] else None

        if "joueur_ids" in data:
                joueurs = Joueur.query.filter(
                    Joueur.id.in_(data["joueur_ids"]),
                    Joueur.coach_id == planning.coach_id
                ).all()
                planning.joueurs = joueurs

        # Proprios ET Collaborateurs peuvent modifier les séances
        if "seances" in data:
            # Si ce n'est pas le proprio qui modifie, on crée une notification
            if not is_owner:
                email_colab=PlanningCollaborator.query.filter_by(
            planning_id=planning_id, coach_id=current_user_id
        ).first()
                email_colab=email_colab.email
                #updater = db.session.query(Coach).get(current_user_id)
                #updater_name = updater.nom if updater else ""
                notif = Notification(
                    coach_id=planning.coach_id,
                    message=f"Un collaborateur ({email_colab}) a modifié votre planning '{planning.titre}'."
                )
                db.session.add(notif)
                db.session.flush()
            # Supprimer les anciennes séances et recréer
            for s in planning.seances:
                db.session.delete(s)
            db.session.flush()

            for i, s_data in enumerate(data["seances"]):
                seance = Seance(
                    planning_id = planning.id,
                    titre       = s_data.get("titre", f"Séance {i+1}"),
                    ordre       = i,
                    domaines    = s_data.get("domaines", []),
                    date_seance = s_data.get("date_seance"),
                    heure_debut = s_data.get("heure_debut"),
                    lieu        = s_data.get("lieu"),
                )
                db.session.add(seance)
                db.session.flush()

                for j, e_data in enumerate(s_data.get("exercices", [])):
                    exercice = Exercice(
                        seance_id   = seance.id,
                        nom         = e_data["nom"].strip(),
                        duree       = int(e_data["duree"]),
                        domaine     = e_data["domaine"],
                        description = e_data.get("description"),
                        ordre       = j,
                    )
                    db.session.add(exercice)

        db.session.commit()
        return planning, None

    @staticmethod
    def delete(planning_id, coach_id):
        planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
        if not planning : 
            return None, "aucun planning trouve a cet id"
        db.session.delete(planning)
        db.session.commit()
        return True, None

    @staticmethod
    def find_overlap(coach_id, date_seance, heure_debut, exclude_planning_id=None):
        if not date_seance or not heure_debut:
            return None

        # S'assurer que la date est comparée en tant qu'objet date
        target_date = date_seance
        if isinstance(date_seance, str):
            try:
                target_date = datetime.strptime(date_seance, '%Y-%m-%d').date()
            except ValueError:
                return None

        query = db.session.query(Seance).join(Planning).filter(
            Planning.coach_id == coach_id,
            Seance.date_seance == target_date,
            Seance.heure_debut == heure_debut
        )
        if exclude_planning_id:
            query = query.filter(Planning.id != exclude_planning_id)
        return query.first()