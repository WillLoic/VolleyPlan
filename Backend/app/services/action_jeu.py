# pyrefly: ignore [missing-import]
from ..utils.domaines_action_config import valider_action, get_config_domaine
from ..models.seances import Seance
from ..models.exercices import Exercice
from ..repositories.action_jeu_factory import get_action_jeu_repository

class ActionJeu:
    @staticmethod
    def enregistrer_actions_exercice(coach_id, seance_id, exercice_id, actions: list[dict]) -> tuple[list[int] | None, str | None]:
        """
        actions = [
        {"joueur_id": 3, "domaine": "service", "donnees": {...}},
        ...
        ]
        Valide chaque action contre la config de son domaine AVANT tout enregistrement.
        Comportement TOUT OU RIEN : si une seule action est invalide, rien n'est enregistré.
        """
        seance = Seance.query.get(seance_id)
        if not seance:
            return None, "Séance introuvable"

        if seance.planning.coach_id != coach_id:
            # Vérifier aussi les collaborateurs (même logique que PlanningService.update)
            from ..models.planning_collaborator import PlanningCollaborator
            is_collab = PlanningCollaborator.query.filter_by(
                planning_id=seance.planning_id, coach_id=coach_id
            ).first() is not None
            if not is_collab:
                return None, "Accès refusé"

        exercice = Exercice.query.get(exercice_id)
        if not exercice or exercice.seance_id != seance_id:
            return None, "Exercice introuvable pour cette séance"

        domaines_exercice = set(exercice.domaines or [])

        for a in actions:
            if "joueur_id" not in a or "domaine" not in a:
                return None, "Chaque action doit contenir joueur_id et domaine"
            if a["domaine"] not in domaines_exercice:
                return None, f"Le domaine '{a['domaine']}' n'est pas travaillé par cet exercice"

            valide, erreur = valider_action(a["domaine"], a.get("donnees", {}))
            if not valide:
                return None, erreur

        repo = get_action_jeu_repository()
        ids = repo.save_batch(seance_id, exercice_id, actions)
        return ids, None

    @staticmethod
    def get_stats_exercice_pour_joueur(exercice_id, joueur_id):
        repo = get_action_jeu_repository()
        return repo.get_stats_joueur_exercice(exercice_id, joueur_id)

    @staticmethod
    def get_stats_exercice_complet(exercice_id):
        repo = get_action_jeu_repository()
        return repo.get_stats_exercice(exercice_id)

    @staticmethod
    def get_stats_seance_complete(seance_id):
        repo = get_action_jeu_repository()
        return repo.get_stats_seance(seance_id)

    @staticmethod
    def supprimer_action(coach_id, action_id):
        repo = get_action_jeu_repository()
        return repo.delete(action_id, coach_id)
