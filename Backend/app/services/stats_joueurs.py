from datetime import datetime
from app import db
from app.models.joueurs import Joueur
from app.models.planning import Planning
from app.models.seances import Seance
from app.models.exercices import Exercice
from app.models.presences import Absence

class StatsJoueursService:

    @staticmethod
    def _get_all_players_stats_in_memory(coach_id: int):
        """
        Calcule de manière optimisée en mémoire les statistiques de tous les joueurs
        actifs d'un coach. Évite le problème N+1 requêtes.
        """
        # Charger tous les plannings et séances du coach
        plannings = Planning.query.filter_by(coach_id=coach_id).all()
        
        # Charger tous les joueurs actifs du coach
        active_joueurs = Joueur.query.filter_by(coach_id=coach_id, actif=True).all()
        active_joueurs_dict = {j.id: j for j in active_joueurs}

        # Charger toutes les absences pour les plannings de ce coach
        absences = db.session.query(Absence).join(Seance).join(Planning).filter(
            Planning.coach_id == coach_id
        ).all()
        absences_set = {(a.seance_id, a.joueur_id) for a in absences}

        domaines_list = ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]
        
        stats_by_player = {}
        for j_id in active_joueurs_dict:
            stats_by_player[j_id] = {
                "volume_prevu": {d: 0 for d in domaines_list},
                "volume_reel": {d: 0 for d in domaines_list},
                "nb_seances_prevues": 0,
                "nb_seances_reelles": 0,
            }

        now = datetime.utcnow()

        for planning in plannings:
            # Récupérer uniquement les joueurs de ce planning qui sont encore actifs
            planning_player_ids = [j.id for j in planning.joueurs if j.id in active_joueurs_dict]

            for seance in planning.seances:
                # La séance est passée si sa date est aujourd'hui ou dans le passé
                est_passee = True
                if seance.date_seance:
                    est_passee = seance.date_seance <= now.date()

                for j_id in planning_player_ids:
                    if est_passee:
                        stats_by_player[j_id]["nb_seances_prevues"] += 1
                        
                        # Si présences prises et pas d'absence pour ce joueur
                        if seance.presences_prises and (seance.id, j_id) not in absences_set:
                            stats_by_player[j_id]["nb_seances_reelles"] += 1

                    for exercice in seance.exercices:
                        for dom in (exercice.domaines or ["general"]):
                            dom = dom.lower().strip()
                            if dom not in domaines_list:
                                dom = "general"

                            # Volume prévu (toujours ajouté dès que l'exercice existe)
                            stats_by_player[j_id]["volume_prevu"][dom] += exercice.duree

                            # Volume réel (seulement si présence prise et joueur présent)
                            if seance.presences_prises and (seance.id, j_id) not in absences_set:
                                stats_by_player[j_id]["volume_reel"][dom] += exercice.duree

        return stats_by_player, active_joueurs_dict

    @staticmethod
    def get_radar_joueur(joueur_id: int, coach_id: int) -> dict:
        """
        Données pour le radar du joueur vs moyenne de l'équipe.
        """
        stats_by_player, active_joueurs_dict = StatsJoueursService._get_all_players_stats_in_memory(coach_id)

        # Vérifier si le joueur demandé est dans l'équipe
        joueur = Joueur.query.filter_by(id=joueur_id, coach_id=coach_id).first()
        if not joueur:
            return {"success": False, "message": "Joueur introuvable"}

        domaines_list = ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]

        # Si le joueur est actif, on prend ses stats pré-calculées
        if joueur.id in stats_by_player:
            j_stats = stats_by_player[joueur.id]
            volume_prevu = j_stats["volume_prevu"]
            volume_reel = j_stats["volume_reel"]
        else:
            # Fallback s'il est inactif (on calcule individuellement)
            volume_prevu = {d: 0 for d in domaines_list}
            volume_reel = {d: 0 for d in domaines_list}
            # Simple calcul individuel
            plannings = Planning.query.join(Planning.joueurs).filter(Joueur.id == joueur_id, Planning.coach_id == coach_id).all()
            absences = Absence.query.filter_by(joueur_id=joueur_id).all()
            absences_seance_ids = {a.seance_id for a in absences}
            for pl in plannings:
                for se in pl.seances:
                    for ex in se.exercices:
                        for dom in (ex.domaines or ["general"]):
                            dom = dom.lower().strip()
                            if dom not in domaines_list:
                                dom = "general"
                            volume_prevu[dom] += ex.duree
                            if se.presences_prises and se.id not in absences_seance_ids:
                                volume_reel[dom] += ex.duree

        # Calculer la moyenne de l'équipe (uniquement sur les joueurs actifs)
        moyenne_equipe = {d: 0.0 for d in domaines_list}
        num_joueurs = len(stats_by_player)
        if num_joueurs > 0:
            for j_id in stats_by_player:
                for d in domaines_list:
                    moyennes_reel_j = stats_by_player[j_id]["volume_reel"][d]
                    moyenne_equipe[d] += moyennes_reel_j
            for d in domaines_list:
                moyenne_equipe[d] = round(moyenne_equipe[d] / num_joueurs, 1)

        return {
            "success": True,
            "joueur": joueur.to_dict(),
            "volume_prevu": volume_prevu,
            "volume_reel": volume_reel,
            "moyenne_equipe": moyenne_equipe
        }

    @staticmethod
    def get_stats_joueur(joueur_id: int, coach_id: int) -> dict:
        """
        Statistiques individuelles complètes pour un joueur.
        """
        stats_by_player, active_joueurs_dict = StatsJoueursService._get_all_players_stats_in_memory(coach_id)

        joueur = Joueur.query.filter_by(id=joueur_id, coach_id=coach_id).first()
        if not joueur:
            return {"success": False, "message": "Joueur introuvable"}

        domaines_list = ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]

        if joueur.id in stats_by_player:
            j_stats = stats_by_player[joueur.id]
            nb_seances_prevues = j_stats["nb_seances_prevues"]
            nb_seances_reelles = j_stats["nb_seances_reelles"]
            volume_prevu = j_stats["volume_prevu"]
            volume_reel = j_stats["volume_reel"]
        else:
            # Fallback pour joueur inactif
            nb_seances_prevues = 0
            nb_seances_reelles = 0
            volume_prevu = {d: 0 for d in domaines_list}
            volume_reel = {d: 0 for d in domaines_list}
            plannings = Planning.query.join(Planning.joueurs).filter(Joueur.id == joueur_id, Planning.coach_id == coach_id).all()
            absences = Absence.query.filter_by(joueur_id=joueur_id).all()
            absences_seance_ids = {a.seance_id for a in absences}
            now = datetime.utcnow()
            for pl in plannings:
                for se in pl.seances:
                    est_passee = True
                    if se.date_seance:
                        est_passee = se.date_seance <= now.date()
                    if est_passee:
                        nb_seances_prevues += 1
                        if se.presences_prises and se.id not in absences_seance_ids:
                            nb_seances_reelles += 1
                    for ex in se.exercices:
                        for dom in (ex.domaines or ["general"]):
                            dom = dom.lower().strip()
                            if dom not in domaines_list:
                                dom = "general"
                            volume_prevu[dom] += ex.duree
                            if se.presences_prises and se.id not in absences_seance_ids:
                                volume_reel[dom] += ex.duree

        taux_presence = 100.0
        if nb_seances_prevues > 0:
            taux_presence = round((nb_seances_reelles / nb_seances_prevues) * 100, 1)

        return {
            "success": True,
            "joueur": joueur.to_dict(),
            "nb_seances_prevues": nb_seances_prevues,
            "nb_seances_reelles": nb_seances_reelles,
            "taux_presence": taux_presence,
            "volume_prevu_par_domaine": volume_prevu,
            "volume_reel_par_domaine": volume_reel
        }

    @staticmethod
    def get_comparaison_equipe(coach_id: int) -> dict:
        """
        Retourne les statistiques de comparaison de tous les joueurs de l'équipe.
        """
        stats_by_player, active_joueurs_dict = StatsJoueursService._get_all_players_stats_in_memory(coach_id)

        comparaison = []
        for j_id, stats in stats_by_player.items():
            joueur = active_joueurs_dict[j_id]
            nb_seances_prevues = stats["nb_seances_prevues"]
            nb_seances_reelles = stats["nb_seances_reelles"]
            taux_presence = 100.0
            if nb_seances_prevues > 0:
                taux_presence = round((nb_seances_reelles / nb_seances_prevues) * 100, 1)

            comparaison.append({
                "joueur": joueur.to_dict(),
                "taux_presence": taux_presence,
                "nb_seances_reelles": nb_seances_reelles,
                "volume_reel_par_domaine": stats["volume_reel"]
            })

        # Trier par nom de joueur par défaut
        comparaison.sort(key=lambda x: x["joueur"]["nom"])

        return {
            "success": True,
            "comparaison": comparaison
        }
