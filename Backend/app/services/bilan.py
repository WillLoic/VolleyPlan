from ..models.planning import Planning
from ..services.planning import PlanningService

DOMAINES = [
    {"id": "service",   "label": "Service"},
    {"id": "reception", "label": "Réception"},
    {"id": "passe",     "label": "Passe"},
    {"id": "attaque",   "label": "Attaque"},
    {"id": "block",     "label": "Block"},
    {"id": "defense",   "label": "Défense"},
    {"id": "physique",  "label": "Physique"},
    {"id": "general",   "label": "Général"},
]

class BilanService:

    @staticmethod
    def compute(coach_id: int | None, planning_id: int, token: str | None = None) -> tuple[dict | None, str | None]:
        if token:
            from ..services.invitation import InvitationService
            planning, error = InvitationService.get_planning_by_token(token)
        else:
            planning, error = PlanningService.get_by_id(planning_id, coach_id)
            
        if error:
            return None, error

        seances   = planning.seances or []
        all_ex    = [e for s in seances for e in (s.exercices or [])]
        total_min = sum(e.duree for e in all_ex)
        nb_seances = len(seances)

        # Volume par domaine
        by_domain = {d["id"]: 0 for d in DOMAINES}
        for e in all_ex:
            if e.domaine in by_domain:
                by_domain[e.domaine] += e.duree

        domain_stats = []
        for d in DOMAINES:
            minutes = by_domain[d["id"]]
            pct = round((minutes / total_min) * 100) if total_min > 0 else 0
            domain_stats.append({
                "id":      d["id"],
                "label":   d["label"],
                "minutes": minutes,
                "pct":     pct,
            })
        domain_stats.sort(key=lambda x: x["minutes"], reverse=True)

        # Analyse par séance
        seance_durees = []
        seances_detail = []
        for s in seances:
            dur = sum(e.duree for e in (s.exercices or []))
            seance_durees.append(dur)
            seances_detail.append({
                "id":          s.id,
                "titre":       s.titre,
                "ordre":       s.ordre,
                "domaines":    s.domaines,
                "date_seance": s.date_seance.isoformat() if s.date_seance else None,
                "heure_debut": s.heure_debut,
                "lieu":        s.lieu,
                "duree_min":   dur,
                "nb_exercices": len(s.exercices or []),
            })

        avg_seance = round(sum(seance_durees) / nb_seances) if nb_seances > 0 else 0
        max_dur    = max(seance_durees) if seance_durees else 0
        min_dur    = min(seance_durees) if seance_durees else 0

        # Recommandations
        recs = BilanService._recommandations(domain_stats, avg_seance, nb_seances)

        result = {
            "planning_id":  planning.id,
            "titre":        planning.titre,
            "mode":         planning.mode,
            "duree":        planning.duree,
            "nb_joueurs":   len(planning.joueurs),
            "nb_seances":   nb_seances,
            "total_minutes": total_min,
            "avg_seance_minutes": avg_seance,
            "max_seance_minutes": max_dur,
            "min_seance_minutes": min_dur,
            "domain_stats": domain_stats,
            "seances_detail": seances_detail,
            "recommandations": recs,
        }
        return result, None

    @staticmethod
    def compute_global(coach_id: int) -> tuple[dict | None, str | None]:
        from ..models.planning import Planning
        plannings = Planning.query.filter_by(coach_id=coach_id).all()
        
        all_seances = []
        for p in plannings:
            all_seances.extend(p.seances or [])
        
        all_ex = [e for s in all_seances for e in (s.exercices or [])]
        total_min = sum(e.duree for e in all_ex)
        nb_seances = len(all_seances)
        nb_plannings = len(plannings)

        # Volume par domaine
        by_domain = {d["id"]: 0 for d in DOMAINES}
        for e in all_ex:
            if e.domaine in by_domain:
                by_domain[e.domaine] += e.duree

        domain_stats = []
        for d in DOMAINES:
            minutes = by_domain[d["id"]]
            pct = round((minutes / total_min) * 100) if total_min > 0 else 0
            domain_stats.append({
                "id":      d["id"],
                "label":   d["label"],
                "minutes": minutes,
                "pct":     pct,
            })
        domain_stats.sort(key=lambda x: x["minutes"], reverse=True)

        avg_seance = round(total_min / nb_seances) if nb_seances > 0 else 0
        recs = BilanService._recommandations(domain_stats, avg_seance, nb_seances)

        result = {
            "nb_plannings": nb_plannings,
            "nb_seances": nb_seances,
            "total_minutes": total_min,
            "avg_seance_minutes": avg_seance,
            "domain_stats": domain_stats,
            "recommandations": recs,
        }
        return result, None

    @staticmethod
    def _recommandations(domain_stats, avg_seance, nb_seances):
        recs = []
        tech = [d for d in domain_stats if d["id"] != "general" and d["minutes"] > 0]

        if tech:
            top = tech[0]
            if top["pct"] > 45:
                recs.append(f"{top['label']} représente {top['pct']}% du volume — pensez à diversifier.")
            low = tech[-1]
            if low["pct"] < 8:
                recs.append(f"{low['label']} peu travaillé ({low['pct']}%) — à renforcer ?")

        physique = next((d for d in domain_stats if d["id"] == "physique"), None)
        if physique and physique["pct"] == 0 and nb_seances >= 4:
            recs.append("Aucune séance physique planifiée — pensez à intégrer musculation ou endurance.")

        if 0 < avg_seance < 45:
            recs.append(f"Durée moyenne de {avg_seance}min/séance — séances courtes, vérifiez la densité.")
        if avg_seance >= 120:
            recs.append(f"Séances longues ({avg_seance}min en moy.) — surveillez la récupération des joueurs.")

        return recs if recs else ["Planning bien équilibré — bonne répartition des domaines !"]