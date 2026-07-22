#def calculer_rapport(planning_id, periode_debut, periode_fin) -> dict:
"""
    Retourne :
    {
      "periode": {"debut": ..., "fin": ...},
      "resume": {
        "nb_seances_prevues": 12,
        "nb_seances_effectuees": 9,
        "taux_realisation": 75.0
      },
      "volume_par_domaine": {
        "service":  {"prevu": 180, "reel": 140},
        "attaque":  {"prevu": 240, "reel": 200},
        ...
      },
      "taux_presence_moyen_equipe": 87.5,
      "seances_manquantes": [
        {"id": 4, "titre": "Séance 4", "date": "2026-06-14"},
        ...
      ]
    }
    
    - "effectuée" = seance.presences_prises == True
    - Le volume "réel" ne compte que les séances effectuées
    - Le taux de présence moyen = moyenne des taux de présence
      individuels des joueurs actifs du planning sur la période
    """

#def generer_rapport_si_eligible(planning_id, auto=True) -> dict | None:
"""
    - Vérifie planning.created_at + 15 jours <= now
    - Calcule periode_debut/periode_fin (mois précédent complet)
    - Si un RapportMensuel existe déjà pour cette période → le retourne
    - Sinon → appelle calculer_rapport(), sauvegarde en DB, retourne le nouveau
    """

#def generer_rapport_a_la_demande(coach_id, planning_id, periode_debut, periode_fin) -> dict:
"""
    Version manuelle : le coach choisit sa période.
    Même logique de calcul, mais genere_auto=False à la sauvegarde.
    """


from datetime import datetime, date, timedelta
from calendar import monthrange

from .. import db
from ..models.planning import Planning
from ..models.seances import Seance
from ..models.presences import Absence
from ..models.rapport_mensuel import RapportMensuel

DOMAINES_IDS = ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]


def _premier_et_dernier_jour_mois_precedent(reference: date) -> tuple[date, date]:
    """Retourne (premier_jour, dernier_jour) du mois précédant la date de référence."""
    premier_jour_mois_courant = reference.replace(day=1)
    dernier_jour_mois_precedent = premier_jour_mois_courant - timedelta(days=1)
    premier_jour_mois_precedent = dernier_jour_mois_precedent.replace(day=1)
    return premier_jour_mois_precedent, dernier_jour_mois_precedent


def calculer_rapport(planning_id: int, periode_debut: date, periode_fin: date) -> dict:
    planning = Planning.query.get(planning_id)
    if not planning:
        return None

    seances_periode = [
        s for s in (planning.seances or [])
        if s.date_seance and periode_debut <= s.date_seance <= periode_fin
    ]

    nb_prevues = len(seances_periode)
    seances_effectuees = [s for s in seances_periode if s.presences_prises]
    nb_effectuees = len(seances_effectuees)
    taux_realisation = round((nb_effectuees / nb_prevues) * 100, 1) if nb_prevues > 0 else 0.0

    # Volume prévu vs réel par domaine
    volume_par_domaine = {d: {"prevu": 0, "reel": 0} for d in DOMAINES_IDS}
    for s in seances_periode:
        for e in (s.exercices or []):
            for dom in (e.domaines or []):
                if dom in volume_par_domaine:
                    volume_par_domaine[dom]["prevu"] += e.duree
    for s in seances_effectuees:
        for e in (s.exercices or []):
            for dom in (e.domaines or []):
                if dom in volume_par_domaine:
                    volume_par_domaine[dom]["reel"] += e.duree

    # Taux de présence moyen de l'équipe sur les séances effectuées
    joueurs = planning.joueurs or []
    seance_ids_effectuees = [s.id for s in seances_effectuees]
    absences = (
        Absence.query.filter(Absence.seance_id.in_(seance_ids_effectuees)).all()
        if seance_ids_effectuees else []
    )
    absences_par_joueur = {}
    for a in absences:
        absences_par_joueur.setdefault(a.joueur_id, 0)
        absences_par_joueur[a.joueur_id] += 1

    if joueurs and nb_effectuees > 0:
        taux_individuels = []
        for j in joueurs:
            nb_absences_j = absences_par_joueur.get(j.id, 0)
            taux_j = ((nb_effectuees - nb_absences_j) / nb_effectuees) * 100
            taux_individuels.append(taux_j)
        taux_presence_moyen = round(sum(taux_individuels) / len(taux_individuels), 1)
    else:
        taux_presence_moyen = 0.0

    # Séances manquantes (date passée, non marquées)
    aujourd_hui = date.today()
    seances_manquantes = [
        {"id": s.id, "titre": s.titre, "date": s.date_seance.isoformat()}
        for s in seances_periode
        if s.date_seance < aujourd_hui and not s.presences_prises
    ]

    return {
        "periode": {
            "debut": periode_debut.isoformat(),
            "fin": periode_fin.isoformat(),
        },
        "resume": {
            "nb_seances_prevues":   nb_prevues,
            "nb_seances_effectuees": nb_effectuees,
            "taux_realisation":     taux_realisation,
        },
        "volume_par_domaine": volume_par_domaine,
        "taux_presence_moyen_equipe": taux_presence_moyen,
        "seances_manquantes": seances_manquantes,
    }


def generer_rapport_si_eligible(planning_id: int, reference: date = None) -> tuple[RapportMensuel | None, bool]:
    """
    Retourne (rapport, est_nouveau).
    est_nouveau = True si un rapport vient d'être créé (déclenche notif + email).
    """
    reference = reference or date.today()
    planning = Planning.query.get(planning_id)
    if not planning:
        return None, False

    if (datetime.utcnow() - planning.created_at) < timedelta(days=15):
        return None, False

    periode_debut, periode_fin = _premier_et_dernier_jour_mois_precedent(reference)

    existant = RapportMensuel.query.filter_by(
        planning_id=planning_id, periode_debut=periode_debut, periode_fin=periode_fin
    ).first()
    if existant:
        return existant, False

    donnees = calculer_rapport(planning_id, periode_debut, periode_fin)
    if donnees is None:
        return None, False

    rapport = RapportMensuel(
        planning_id=planning_id,
        coach_id=planning.coach_id,
        periode_debut=periode_debut,
        periode_fin=periode_fin,
        donnees=donnees,
        genere_auto=True,
    )
    db.session.add(rapport)
    db.session.commit()
    return rapport, True


def generer_rapport_a_la_demande(coach_id: int, planning_id: int, periode_debut: date, periode_fin: date):
    planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
    if not planning:
        return None, "Planning introuvable ou accès refusé"

    existant = RapportMensuel.query.filter_by(
        planning_id=planning_id, periode_debut=periode_debut, periode_fin=periode_fin
    ).first()
    if existant:
        return existant, None

    donnees = calculer_rapport(planning_id, periode_debut, periode_fin)
    rapport = RapportMensuel(
        planning_id=planning_id,
        coach_id=coach_id,
        periode_debut=periode_debut,
        periode_fin=periode_fin,
        donnees=donnees,
        genere_auto=False,
    )
    db.session.add(rapport)
    db.session.commit()
    return rapport, None