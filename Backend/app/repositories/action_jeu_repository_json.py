from collections import defaultdict
from .. import db
from ..models.action_jeu_json import ActionJeuJSON
from .action_jeu_repository import ActionJeuRepository


class ActionJeuRepositoryJSON(ActionJeuRepository):

    def save_batch(self, seance_id, exercice_id, actions):
        objets = [
            ActionJeuJSON(
                seance_id=seance_id, exercice_id=exercice_id,
                joueur_id=a["joueur_id"], domaine=a["domaine"],
                donnees=a.get("donnees", {}),
            )
            for a in actions
        ]
        db.session.bulk_save_objects(objets, return_defaults=True)
        db.session.commit()
        return [o.id for o in objets]

    def delete(self, action_id, coach_id):
        action = ActionJeuJSON.query.get(action_id)
        if not action:
            return False, "Action introuvable"
        from ..models.seances import Seance
        seance = Seance.query.get(action.seance_id)
        if not seance or seance.planning.coach_id != coach_id:
            return False, "Accès refusé"
        db.session.delete(action)
        db.session.commit()
        return True, None

    def _aggreger(self, actions: list[ActionJeuJSON]) -> dict:
        par_domaine = defaultdict(lambda: {"total": 0, "par_champ": defaultdict(lambda: defaultdict(int))})
        for a in actions:
            bucket = par_domaine[a.domaine]
            bucket["total"] += 1
            for champ, valeur in (a.donnees or {}).items():
                val_str = str(valeur).lower() if isinstance(valeur, bool) else str(valeur)
                bucket["par_champ"][champ][val_str] += 1
        return {
            dom: {"total": v["total"], "par_champ": {c: dict(vv) for c, vv in v["par_champ"].items()}}
            for dom, v in par_domaine.items()
        }

    def get_stats_joueur_exercice(self, exercice_id, joueur_id):
        actions = ActionJeuJSON.query.filter_by(exercice_id=exercice_id, joueur_id=joueur_id).all()
        return self._aggreger(actions)

    def get_stats_exercice(self, exercice_id):
        actions = ActionJeuJSON.query.filter_by(exercice_id=exercice_id).all()
        par_joueur = defaultdict(list)
        for a in actions:
            par_joueur[a.joueur_id].append(a)
        return {jid: self._aggreger(acts) for jid, acts in par_joueur.items()}

    def get_stats_seance(self, seance_id):
        actions = ActionJeuJSON.query.filter_by(seance_id=seance_id).all()
        par_exercice = defaultdict(list)
        for a in actions:
            par_exercice[a.exercice_id].append(a)
        resultat = {}
        for ex_id, acts in par_exercice.items():
            par_joueur = defaultdict(list)
            for a in acts:
                par_joueur[a.joueur_id].append(a)
            resultat[ex_id] = {jid: self._aggreger(j_acts) for jid, j_acts in par_joueur.items()}
        return resultat