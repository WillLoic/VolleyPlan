def generer_ou_regenerer_lien(coach_id, planning_id) -> dict:
    """
    - Vérifie que le planning appartient au coach
    - Si un partage existe déjà pour ce planning → régénère token + expires_at
    - Sinon → en crée un nouveau
    - Retourne {"token": ..., "url": "https://volleyplan.app/public/planning/<token>", "expires_at": ...}
    """

def revoquer_lien(coach_id, planning_id):
    """
    Non exposé dans l'UI pour l'instant (décision produit : pas de révocation manuelle).
    Gardé côté service pour usage interne / modération future si besoin.
    """

def get_planning_public(token) -> dict | None:
    """
    - Cherche le PartagePublic par token
    - Si introuvable ou expiré → retourne None
    - Sinon → retourne les données du planning en lecture seule
      (même structure que get_planning normal, MAIS sans données sensibles :
       pas d'email des collaborateurs, pas d'actions possibles)
    """

import uuid
from datetime import datetime

from .. import db
from ..models.partage_planning import PartagePublic
from ..models.planning import Planning


class PartagePublicService:

    @staticmethod
    def generer_ou_regenerer_lien(coach_id, planning_id):
        planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
        if not planning:
            return None, "Planning introuvable ou accès refusé"

        partage = PartagePublic.query.filter_by(planning_id=planning_id).first()

        if partage:
            # Régénération : on écrase le token existant, pas de nouvelle ligne
            partage.token = str(uuid.uuid4())
            partage.created_at = datetime.utcnow()
            partage.expires_at = PartagePublic.generer_expiration()
        else:
            partage = PartagePublic(
                planning_id=planning_id,
                expires_at=PartagePublic.generer_expiration(),
            )
            db.session.add(partage)

        db.session.commit()
        return partage, None

    @staticmethod
    def get_lien_actuel(coach_id, planning_id):
        """Retourne le lien existant sans en générer un nouveau (peut être None)."""
        planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
        if not planning:
            return None, "Planning introuvable ou accès refusé"
        partage = PartagePublic.query.filter_by(planning_id=planning_id).first()
        return partage, None

    @staticmethod
    def get_planning_public(token):
        """
        Retourne (planning, partage, error).
        - planning est None si erreur (token invalide ou expiré)
        - partage est toujours retourné quand trouvé (utile pour distinguer 404 vs 410)
        """
        partage = PartagePublic.query.filter_by(token=token).first()
        if not partage:
            return None, None, "Lien introuvable"

        if partage.est_expire:
            return None, partage, "Ce lien a expiré"

        planning = Planning.query.get(partage.planning_id)
        if not planning:
            return None, partage, "Planning introuvable"

        return planning, partage, None