# VolleyPlan — Système de Statistiques de Jeu par Action

## Contexte général du projet (pour une IA sans historique)

VolleyPlan est une application SaaS de planification d'entraînements de volleyball, avec :
- **Backend** : Flask + SQLAlchemy + PostgreSQL (Supabase), architecture en `models/` `services/` `controllers/`, JWT pour l'auth
- **Frontend** : Flutter Web (+ mobile), architecture `screen/` `services/` `widgets/` `models/`, GoRouter pour la navigation, système i18n avec `AppLocalizations` (français/anglais)
- **Domaine métier existant** : un `Coach` crée des `Planning`, chaque planning contient des `Seance`, chaque séance contient des `Exercice`. Chaque exercice a actuellement **un seul domaine** technique associé (`service`, `reception`, `passe`, `attaque`, `block`, `defense`, `physique`, `general`) et une `duree` en minutes. Un `BilanService` calcule la répartition du volume d'entraînement par domaine sur un planning.
- **Fonctionnalités déjà en place** : gestion de présence par séance (table `absences`, workflow de fenêtre de saisie), export PDF et Excel des plannings, partage public par lien à token, rapport mensuel automatique.

## Objectif de cette fonctionnalité

Des coachs utilisateurs (dont un qui prépare une **CAN**, avec un enjeu commercial réel — abonnement conditionné à cette fonctionnalité, **délai de 2 semaines**) ont exprimé un besoin qui dépasse la simple planification : ils veulent mesurer objectivement, action par action, la performance de chaque joueur pendant un exercice, pour ensuite ajuster leurs futurs plannings sur la base de données réelles plutôt que d'intuition seule.

Concrètement : pendant qu'un exercice se déroule (ex. un exercice de service de 20 minutes), une personne (le coach ou un collaborateur déjà présent dans le système d'invitation existant) saisit **chaque action de jeu de chaque joueur** en temps réel (ex. "Bitouna a servi, service smashé, zone 6, résultat : perdu"). L'application agrège ensuite ces actions en statistiques par joueur et par exercice.

**Contrainte de volume critique** : une séance de 3h avec ~14 joueurs peut générer **plusieurs milliers d'actions individuelles**. Toute décision technique doit être pensée pour ce volume.

---

## Décisions actées (à respecter strictement)

| Sujet | Décision |
|---|---|
| Relation exercice ↔ domaine | Un exercice passe de **un seul domaine** (`String`) à **plusieurs domaines possibles** (`JSON list`), migration obligatoire des données existantes |
| Calcul du bilan (durée par domaine) | Si un exercice de 20 min travaille service ET réception, on compte **20 min sur chacun** des deux domaines (pas de division). Le total du bilan par domaine peut donc dépasser la somme brute des durées d'exercices — c'est voulu |
| Domaines couverts par les stats d'action | **5 domaines seulement** : `service`, `reception`, `passe`, `attaque`, `defense`, `block` (6 en comptant bien tous listés). Les domaines `physique` et `general` **n'ont pas** de saisie d'action détaillée — ce sont de simples exercices sans stats fines |
| Lien entre actions de joueurs différents | **Aucun lien explicite**. Le service de Kavogo et la réception de Bitouna sur ce même échange ne sont **pas reliés** en base. Chaque action est indépendante, rattachée uniquement à `(exercice, joueur, domaine)` |
| Correction d'une action | **Impossible**. Une action validée est définitive. Seule option : suppression puis recréation |
| Stockage des caractéristiques d'une action | **Colonnes fixes génériques** pour le MVP (voir section dédiée), choisies pour la rapidité d'agrégation sur gros volume. **Obligation architecturale** : ce choix doit être caché derrière une couche d'abstraction (pattern Repository) pour pouvoir basculer vers un stockage JSON flexible plus tard **sans toucher au frontend ni aux controllers** — les deux approches doivent produire strictement le même contrat de données en sortie |
| Saisie côté frontend | Formulaire à **une seule ligne** par domaine dans l'exercice actif. Chaque validation d'action stocke **localement** (en mémoire, côté client) et réinitialise le formulaire à zéro — jamais d'accumulation visuelle de lignes |
| Envoi vers le backend | **Un seul appel réseau** à la fin de l'exercice (bouton "Terminer l'exercice"), envoyant **toutes les actions accumulées localement en un seul batch** |
| Comportement en cas d'échec de l'envoi | Le coach **reste bloqué** sur l'exercice en cours, ne peut **pas** passer au suivant tant que l'envoi n'a pas réussi. Bouton de nouvelle tentative. Les données restent en mémoire locale tant que l'envoi n'est pas confirmé — **aucune perte de données** |
| Qui saisit | Le coach principal ou un collaborateur déjà invité via le système d'invitation existant (`PlanningCollaborator`) — aucun nouveau système de rôle nécessaire |

---

## 1. Migration `exercice.domaine` → `exercice.domaines`

### 1.1 Modèle actuel (à modifier)

Le modèle `Exercice` a actuellement un champ `domaine = db.Column(db.String(50))`. Il doit devenir :

```python
domaines = db.Column(db.JSON, default=list)  # ["service", "reception"]
```

### 1.2 Migration SQL (Supabase)

```sql
-- 1. Ajouter la nouvelle colonne
ALTER TABLE exercices ADD COLUMN IF NOT EXISTS domaines JSON;

-- 2. Recopier les valeurs existantes dans le nouveau format liste
UPDATE exercices
SET domaines = json_build_array(domaine)
WHERE domaine IS NOT NULL AND domaines IS NULL;

-- 3. Valeur par défaut pour les lignes sans domaine (ne devrait pas exister mais sécurité)
UPDATE exercices SET domaines = '[]'::json WHERE domaines IS NULL;

-- 4. La colonne "domaine" (ancienne, singulier) est conservée pour rollback de sécurité
--    mais n'est plus utilisée par le code applicatif après cette migration.
--    Elle peut être supprimée dans un nettoyage ultérieur, PAS immédiatement.
```

> [!IMPORTANT]
> Ne pas supprimer la colonne `domaine` (singulier) dans cette migration. Elle sert de filet de sécurité en cas de bug de la migration `domaines`. Suppression différée à après validation en prod.

### 1.3 Impacts sur le code existant à corriger

Tout le code qui lit `exercice.domaine` (singulier) doit être mis à jour pour lire `exercice.domaines` (liste) :

- `models/exercices.py` — `to_dict()` doit retourner `"domaines": self.domaines or []` au lieu de `"domaine": self.domaine`
- `services/bilan.py` — la boucle `for e in all_ex: if e.domaine in by_domain: by_domain[e.domaine] += e.duree` doit devenir :
  ```python
  for e in all_ex:
      for dom in (e.domaines or []):
          if dom in by_domain:
              by_domain[dom] += e.duree   # duree complète comptée sur CHAQUE domaine, pas divisée
  ```
- `services/excel_export.py` — la logique `d["id"] in (s.domaines or [])` au niveau séance reste inchangée (c'est déjà une liste au niveau séance), mais si le fichier référence `exercice.domaine` quelque part, corriger de la même façon
- `services/pdf.py` — `DOMAIN_LABELS.get(ex.domaine, ex.domaine)` dans le tableau d'exercices doit devenir une jointure des labels de tous les domaines de l'exercice : `", ".join(DOMAIN_LABELS.get(d, d) for d in (ex.domaines or []))`
- Tout formulaire frontend de création/édition d'exercice (`planning_form_screen.dart` ou équivalent) doit passer d'une sélection à choix unique de domaine à une **sélection multiple** (checkboxes ou chips multi-sélectionnables)
- `services/rapport_mensuel.py` — la boucle de calcul du volume par domaine doit suivre la même correction que dans `bilan.py`

---

## 2. Configuration des domaines d'action (le cœur du système générique)

### 2.1 Principe

Au lieu de coder un formulaire différent par domaine, on définit une **configuration déclarative** par domaine, exploitée à la fois par le backend (validation) et le frontend (génération dynamique du formulaire de saisie). Cette configuration doit exister **de manière strictement identique** côté backend (Python) et côté frontend (Dart), pour garantir que ce qui est saisi correspond à ce qui est validé.

### 2.2 Colonnes génériques retenues (MVP — implémentation "colonnes fixes")

Après analyse des 6 domaines, tous leurs champs se regroupent dans **9 colonnes génériques** :

| Colonne | Type | Utilisée par |
|---|---|---|
| `position` | String | service, reception, passe, attaque, defense, block |
| `type_action` | String | service, reception |
| `zone` | String | service, attaque |
| `qualite` | String | reception, passe (qualité de la réception reçue), defense |
| `resultat` | String | service, passe, attaque, block |
| `point_direct` | Boolean | passe uniquement |
| `touche` | Boolean | block uniquement |
| `nombre_bloqueurs` | Integer | attaque, block |
| `puissance_adverse` | String | defense uniquement |

### 2.3 Configuration exacte par domaine — SOURCE DE VÉRITÉ

Cette section fait foi. Chaque domaine ci-dessous liste ses champs actifs (parmi les 9 colonnes génériques), avec leurs valeurs possibles fermées.

#### SERVICE
| Champ générique | Label métier | Valeurs possibles |
|---|---|---|
| `type_action` | Type de service | `smashe`, `flottant` |
| `position` | Position du serveur | `1`, `6`, `5` |
| `zone` | Zone de chute | `1`, `2`, `3`, `4`, `5`, `6` |
| `resultat` | Finalité | `reussi`, `perdu`, `ace` |

#### RÉCEPTION
| Champ générique | Label métier | Valeurs possibles |
|---|---|---|
| `type_action` | Type de service reçu | `smashe`, `flottant` |
| `position` | Position du réceptionneur | `1`, `6`, `5`, `zone_avant` |
| `qualite` | Qualité de la réception | `bonne`, `moyenne`, `mauvaise`, `point_concede` |

#### PASSE
| Champ générique | Label métier | Valeurs possibles |
|---|---|---|
| `position` | Poste de la passe | `1`, `2`, `4`, `6`, `fixe_avant`, `fixe_arriere`, `decale`, `basket` |
| `qualite` | Sur quelle réception | `bonne`, `moyenne`, `mauvaise` |
| `resultat` | Passe réussie | `reussie`, `ratee` |
| `point_direct` | Point direct sur la passe | `true` / `false` |

#### ATTAQUE
| Champ générique | Label métier | Valeurs possibles |
|---|---|---|
| `position` | Poste de l'attaque | `1`, `2`, `4`, `6`, `fixe_avant`, `fixe_arriere`, `decale`, `basket` |
| `nombre_bloqueurs` | Nombre de bloqueurs adverses | `0`, `1`, `2`, `3` |
| `zone` | Zone d'attaque | `grande_diagonale`, `petite_diagonale`, `ligne`, `fausse_ligne`, `bloc_out`, `5`, `1`, `6` |
| `resultat` | Résultat de l'attaque | `point_direct`, `contree`, `defendue`, `faute` |

> [!NOTE]
> **Correction actée par rapport au besoin exprimé initialement** : les 4 champs booléens indépendants (point direct / bloqué / défendu / faute) sont remplacés par un seul champ `resultat` à valeurs mutuellement exclusives, pour éviter les saisies contradictoires (une attaque ne peut pas être à la fois "point direct" et "bloquée").

#### DÉFENSE
| Champ générique | Label métier | Valeurs possibles |
|---|---|---|
| `position` | Position | `1`, `2`, `4`, `5`, `6` |
| `qualite` | Qualité de la défense | `bonne`, `moyenne`, `mauvaise` |
| `puissance_adverse` | Puissance de l'attaque adverse | `elevee`, `moyenne`, `faible` |

#### BLOCK
| Champ générique | Label métier | Valeurs possibles |
|---|---|---|
| `nombre_bloqueurs` | Nombre de bloqueurs | `1`, `2`, `3` |
| `position` | Position du block | `1`, `2`, `4`, `6`, `centre` |
| `resultat` | Block gagnant | `gagnant`, `non_gagnant` |
| `touche` | Touché | `true` / `false` |

### 2.4 Fichier de configuration backend

---

#### [NEW] `config/domaines_action_config.py`

```python
"""
Configuration déclarative des domaines supportant la saisie d'action de jeu.
SOURCE DE VÉRITÉ — toute modification ici doit être répercutée à l'identique
dans le fichier Dart équivalent côté frontend (voir section 2.5 du plan).
"""

DOMAINES_ACTION_CONFIG = {
    "service": {
        "champs": {
            "type_action": ["smashe", "flottant"],
            "position":    ["1", "6", "5"],
            "zone":        ["1", "2", "3", "4", "5", "6"],
            "resultat":    ["reussi", "perdu", "ace"],
        }
    },
    "reception": {
        "champs": {
            "type_action": ["smashe", "flottant"],
            "position":    ["1", "6", "5", "zone_avant"],
            "qualite":     ["bonne", "moyenne", "mauvaise", "point_concede"],
        }
    },
    "passe": {
        "champs": {
            "position":     ["1", "2", "4", "6", "fixe_avant", "fixe_arriere", "decale", "basket"],
            "qualite":      ["bonne", "moyenne", "mauvaise"],
            "resultat":     ["reussie", "ratee"],
            "point_direct": ["true", "false"],  # traité comme booléen à la validation
        }
    },
    "attaque": {
        "champs": {
            "position":         ["1", "2", "4", "6", "fixe_avant", "fixe_arriere", "decale", "basket"],
            "nombre_bloqueurs": ["0", "1", "2", "3"],
            "zone":             ["grande_diagonale", "petite_diagonale", "ligne", "fausse_ligne", "bloc_out", "5", "1", "6"],
            "resultat":         ["point_direct", "contree", "defendue", "faute"],
        }
    },
    "defense": {
        "champs": {
            "position":         ["1", "2", "4", "5", "6"],
            "qualite":          ["bonne", "moyenne", "mauvaise"],
            "puissance_adverse": ["elevee", "moyenne", "faible"],
        }
    },
    "block": {
        "champs": {
            "nombre_bloqueurs": ["1", "2", "3"],
            "position":         ["1", "2", "4", "6", "centre"],
            "resultat":         ["gagnant", "non_gagnant"],
            "touche":           ["true", "false"],
        }
    },
}


def get_config_domaine(domaine: str) -> dict | None:
    return DOMAINES_ACTION_CONFIG.get(domaine)


def valider_action(domaine: str, donnees: dict) -> tuple[bool, str | None]:
    """
    Valide qu'une action soumise respecte la configuration de son domaine.
    donnees = {"type_action": "smashe", "position": "6", ...}
    """
    config = get_config_domaine(domaine)
    if not config:
        return False, f"Domaine '{domaine}' non reconnu pour la saisie d'action"

    champs_attendus = config["champs"]
    for champ, valeur in donnees.items():
        if champ not in champs_attendus:
            return False, f"Champ '{champ}' non attendu pour le domaine '{domaine}'"
        if str(valeur) not in champs_attendus[champ]:
            return False, f"Valeur '{valeur}' invalide pour le champ '{champ}' (domaine '{domaine}')"

    return True, None
```

### 2.5 Fichier de configuration frontend (Dart) — doit être une copie fonctionnelle exacte

---

#### [NEW] `lib/utils/domaines_action_config.dart`

```dart
class DomaineActionConfig {
  final Map<String, List<String>> champs;
  const DomaineActionConfig({required this.champs});
}

const Map<String, DomaineActionConfig> domainesActionConfig = {
  'service': DomaineActionConfig(champs: {
    'type_action': ['smashe', 'flottant'],
    'position': ['1', '6', '5'],
    'zone': ['1', '2', '3', '4', '5', '6'],
    'resultat': ['reussi', 'perdu', 'ace'],
  }),
  'reception': DomaineActionConfig(champs: {
    'type_action': ['smashe', 'flottant'],
    'position': ['1', '6', '5', 'zone_avant'],
    'qualite': ['bonne', 'moyenne', 'mauvaise', 'point_concede'],
  }),
  'passe': DomaineActionConfig(champs: {
    'position': ['1', '2', '4', '6', 'fixe_avant', 'fixe_arriere', 'decale', 'basket'],
    'qualite': ['bonne', 'moyenne', 'mauvaise'],
    'resultat': ['reussie', 'ratee'],
    'point_direct': ['true', 'false'],
  }),
  'attaque': DomaineActionConfig(champs: {
    'position': ['1', '2', '4', '6', 'fixe_avant', 'fixe_arriere', 'decale', 'basket'],
    'nombre_bloqueurs': ['0', '1', '2', '3'],
    'zone': ['grande_diagonale', 'petite_diagonale', 'ligne', 'fausse_ligne', 'bloc_out', '5', '1', '6'],
    'resultat': ['point_direct', 'contree', 'defendue', 'faute'],
  }),
  'defense': DomaineActionConfig(champs: {
    'position': ['1', '2', '4', '5', '6'],
    'qualite': ['bonne', 'moyenne', 'mauvaise'],
    'puissance_adverse': ['elevee', 'moyenne', 'faible'],
  }),
  'block': DomaineActionConfig(champs: {
    'nombre_bloqueurs': ['1', '2', '3'],
    'position': ['1', '2', '4', '6', 'centre'],
    'resultat': ['gagnant', 'non_gagnant'],
    'touche': ['true', 'false'],
  }),
};
```

> [!IMPORTANT]
> Les **labels affichés à l'utilisateur** (ex. "smashe" → "Smashé", "zone_avant" → "Zone avant") et leur **traduction i18n** (fr/en) sont à définir séparément dans les fichiers `.arb` existants, en suivant le pattern déjà utilisé pour `getDomaineLabel()` ailleurs dans le code. Ce plan ne fixe pas ces libellés, seulement les valeurs internes (clés).

---

## 3. Couche d'abstraction du stockage (Repository Pattern) — OBLIGATOIRE

### 3.1 Principe

Le service métier et les controllers ne doivent **jamais** manipuler directement une table SQL. Ils passent par une interface commune, dont on choisit l'implémentation via une configuration d'application. Ceci permet de basculer entre stockage "colonnes fixes" et stockage "JSON flexible" sans modifier une seule ligne en dehors de ce module de repository.

### 3.2 Interface commune

---

#### [NEW] `repositories/action_jeu_repository.py`

```python
from abc import ABC, abstractmethod


class ActionJeuRepository(ABC):

    @abstractmethod
    def save_batch(self, seance_id: int, exercice_id: int, actions: list[dict]) -> list[int]:
        """
        actions = [
          {"joueur_id": 3, "domaine": "service", "donnees": {"type_action": "smashe", "position": "6", "zone": "1", "resultat": "perdu"}},
          ...
        ]
        Retourne la liste des IDs créés.
        """
        ...

    @abstractmethod
    def delete(self, action_id: int, coach_id: int) -> tuple[bool, str | None]:
        ...

    @abstractmethod
    def get_stats_joueur_exercice(self, exercice_id: int, joueur_id: int) -> dict:
        """
        Retourne les stats agrégées d'un joueur sur un exercice, groupées par domaine.
        Format de sortie IDENTIQUE quelle que soit l'implémentation choisie :
        {
          "service": {
            "total": 10,
            "par_champ": {
              "type_action": {"smashe": 8, "flottant": 2},
              "resultat": {"reussi": 5, "perdu": 3, "ace": 2}
            }
          },
          "reception": {...}
        }
        """
        ...

    @abstractmethod
    def get_stats_exercice(self, exercice_id: int) -> dict:
        """Stats agrégées de TOUS les joueurs sur un exercice, même format imbriqué par joueur_id."""
        ...

    @abstractmethod
    def get_stats_seance(self, seance_id: int) -> dict:
        """Stats agrégées sur toute la séance, groupées par exercice puis joueur."""
        ...
```

### 3.3 Implémentation MVP — colonnes fixes

---

#### [NEW] `models/action_jeu.py`

```python
from datetime import datetime
from app import db


class ActionJeu(db.Model):
    __tablename__ = "actions_jeu"

    id           = db.Column(db.Integer, primary_key=True)
    seance_id    = db.Column(db.Integer, db.ForeignKey("seances.id", ondelete="CASCADE"), nullable=False, index=True)
    exercice_id  = db.Column(db.Integer, db.ForeignKey("exercices.id", ondelete="CASCADE"), nullable=False, index=True)
    joueur_id    = db.Column(db.Integer, db.ForeignKey("joueurs.id", ondelete="CASCADE"), nullable=False, index=True)
    domaine      = db.Column(db.String(20), nullable=False, index=True)

    # ── Colonnes génériques (voir section 2.2 du plan) ──────────
    position          = db.Column(db.String(30), nullable=True)
    type_action       = db.Column(db.String(30), nullable=True)
    zone              = db.Column(db.String(30), nullable=True)
    qualite           = db.Column(db.String(30), nullable=True)
    resultat          = db.Column(db.String(30), nullable=True)
    point_direct      = db.Column(db.Boolean, nullable=True)
    touche            = db.Column(db.Boolean, nullable=True)
    nombre_bloqueurs  = db.Column(db.Integer, nullable=True)
    puissance_adverse = db.Column(db.String(20), nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "seance_id": self.seance_id,
            "exercice_id": self.exercice_id,
            "joueur_id": self.joueur_id,
            "domaine": self.domaine,
            "position": self.position,
            "type_action": self.type_action,
            "zone": self.zone,
            "qualite": self.qualite,
            "resultat": self.resultat,
            "point_direct": self.point_direct,
            "touche": self.touche,
            "nombre_bloqueurs": self.nombre_bloqueurs,
            "puissance_adverse": self.puissance_adverse,
            "created_at": self.created_at.isoformat(),
        }


def app_context(app):
    with app.app_context():
        db.create_all()
```

---

#### [NEW] `repositories/action_jeu_repository_colonnes.py`

```python
from collections import defaultdict
from sqlalchemy import func

from .. import db
from ..models.action_jeu import ActionJeu
from .action_jeu_repository import ActionJeuRepository

COLONNES_GENERIQUES = [
    "position", "type_action", "zone", "qualite", "resultat",
    "point_direct", "touche", "nombre_bloqueurs", "puissance_adverse",
]


class ActionJeuRepositoryColonnes(ActionJeuRepository):

    def save_batch(self, seance_id, exercice_id, actions):
        ids = []
        objets = []
        for a in actions:
            donnees = a.get("donnees", {})
            kwargs = {
                "seance_id": seance_id,
                "exercice_id": exercice_id,
                "joueur_id": a["joueur_id"],
                "domaine": a["domaine"],
            }
            for col in COLONNES_GENERIQUES:
                if col in donnees:
                    val = donnees[col]
                    if col in ("point_direct", "touche"):
                        val = str(val).lower() == "true"
                    if col == "nombre_bloqueurs":
                        val = int(val)
                    kwargs[col] = val
            objets.append(ActionJeu(**kwargs))

        db.session.bulk_save_objects(objets, return_defaults=True)
        db.session.commit()
        return [o.id for o in objets]

    def delete(self, action_id, coach_id):
        action = ActionJeu.query.get(action_id)
        if not action:
            return False, "Action introuvable"
        # Vérification de propriété via la chaîne exercice -> seance -> planning -> coach
        from ..models.seances import Seance
        seance = Seance.query.get(action.seance_id)
        if not seance or seance.planning.coach_id != coach_id:
            return False, "Accès refusé"
        db.session.delete(action)
        db.session.commit()
        return True, None

    def _aggreger(self, actions: list[ActionJeu]) -> dict:
        par_domaine = defaultdict(lambda: {"total": 0, "par_champ": defaultdict(lambda: defaultdict(int))})
        for a in actions:
            bucket = par_domaine[a.domaine]
            bucket["total"] += 1
            for col in COLONNES_GENERIQUES:
                val = getattr(a, col)
                if val is not None:
                    bucket["par_champ"][col][str(val)] += 1
        # Conversion des defaultdicts en dict classiques pour la sérialisation JSON
        return {
            dom: {
                "total": v["total"],
                "par_champ": {champ: dict(vals) for champ, vals in v["par_champ"].items()},
            }
            for dom, v in par_domaine.items()
        }

    def get_stats_joueur_exercice(self, exercice_id, joueur_id):
        actions = ActionJeu.query.filter_by(exercice_id=exercice_id, joueur_id=joueur_id).all()
        return self._aggreger(actions)

    def get_stats_exercice(self, exercice_id):
        actions = ActionJeu.query.filter_by(exercice_id=exercice_id).all()
        par_joueur = defaultdict(list)
        for a in actions:
            par_joueur[a.joueur_id].append(a)
        return {jid: self._aggreger(acts) for jid, acts in par_joueur.items()}

    def get_stats_seance(self, seance_id):
        actions = ActionJeu.query.filter_by(seance_id=seance_id).all()
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
```

### 3.4 Implémentation alternative — JSON flexible (à construire EN PARALLÈLE, pour comparaison)

> [!IMPORTANT]
> Le porteur du projet souhaite **comparer concrètement les deux approches** avant de trancher définitivement laquelle garder en production. Cette implémentation doit être construite avec le même niveau de finition que la version colonnes, pas comme un prototype jetable.

---

#### [NEW] `models/action_jeu_json.py`

```python
from datetime import datetime
from app import db


class ActionJeuJSON(db.Model):
    __tablename__ = "actions_jeu_json"

    id          = db.Column(db.Integer, primary_key=True)
    seance_id   = db.Column(db.Integer, db.ForeignKey("seances.id", ondelete="CASCADE"), nullable=False, index=True)
    exercice_id = db.Column(db.Integer, db.ForeignKey("exercices.id", ondelete="CASCADE"), nullable=False, index=True)
    joueur_id   = db.Column(db.Integer, db.ForeignKey("joueurs.id", ondelete="CASCADE"), nullable=False, index=True)
    domaine     = db.Column(db.String(20), nullable=False, index=True)
    donnees     = db.Column(db.JSON, nullable=False)  # {"type_action": "smashe", "position": "6", ...}
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id, "seance_id": self.seance_id, "exercice_id": self.exercice_id,
            "joueur_id": self.joueur_id, "domaine": self.domaine,
            "donnees": self.donnees, "created_at": self.created_at.isoformat(),
        }


def app_context(app):
    with app.app_context():
        db.create_all()
```

---

#### [NEW] `repositories/action_jeu_repository_json.py`

```python
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
                bucket["par_champ"][champ][str(valeur)] += 1
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
```

### 3.5 Factory — sélection de l'implémentation active

---

#### [NEW] `repositories/action_jeu_factory.py`

```python
import os
from .action_jeu_repository_colonnes import ActionJeuRepositoryColonnes
from .action_jeu_repository_json import ActionJeuRepositoryJSON


def get_action_jeu_repository():
    """
    Le mode actif est piloté par la variable d'environnement ACTION_JEU_STORAGE_MODE.
    Valeurs possibles : "colonnes" (défaut, MVP) ou "json".
    Changer cette variable ne nécessite AUCUNE modification du code appelant.
    """
    mode = os.getenv("ACTION_JEU_STORAGE_MODE", "colonnes")
    if mode == "json":
        return ActionJeuRepositoryJSON()
    return ActionJeuRepositoryColonnes()
```

> [!NOTE]
> Tous les services et controllers de ce plan appellent exclusivement `get_action_jeu_repository()`, jamais directement `ActionJeu` ou `ActionJeuJSON`. C'est ce qui garantit la bascule sans régression.

---

## 4. Service métier — validation et orchestration

---

#### [NEW] `services/action_jeu.py`

```python
from ..config.domaines_action_config import valider_action, get_config_domaine
from ..models.seances import Seance
from ..models.exercices import Exercice
from ..repositories.action_jeu_factory import get_action_jeu_repository


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


def get_stats_exercice_pour_joueur(exercice_id, joueur_id):
    repo = get_action_jeu_repository()
    return repo.get_stats_joueur_exercice(exercice_id, joueur_id)


def get_stats_exercice_complet(exercice_id):
    repo = get_action_jeu_repository()
    return repo.get_stats_exercice(exercice_id)


def get_stats_seance_complete(seance_id):
    repo = get_action_jeu_repository()
    return repo.get_stats_seance(seance_id)


def supprimer_action(coach_id, action_id):
    repo = get_action_jeu_repository()
    return repo.delete(action_id, coach_id)
```

---

## 5. Controller (routes API)

---

#### [NEW] `controllers/action_jeu.py`

```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services.action_jeu import (
    enregistrer_actions_exercice,
    get_stats_exercice_pour_joueur,
    get_stats_exercice_complet,
    get_stats_seance_complete,
    supprimer_action,
)
from app.config.domaines_action_config import DOMAINES_ACTION_CONFIG

action_jeu_bp = Blueprint("actions_jeu", __name__)


@action_jeu_bp.route("/config", methods=["GET"])
@jwt_required()
def get_config():
    """Retourne la configuration des domaines pour que le frontend puisse la vérifier / se synchroniser."""
    return jsonify(DOMAINES_ACTION_CONFIG), 200


@action_jeu_bp.route("/seance/<int:seance_id>/exercice/<int:exercice_id>/actions", methods=["POST"])
@jwt_required()
def enregistrer_batch(seance_id, exercice_id):
    coach_id = int(get_jwt_identity())
    data = request.get_json() or {}
    actions = data.get("actions", [])

    if not actions:
        return jsonify({"error": "Aucune action à enregistrer"}), 400

    ids, error = enregistrer_actions_exercice(coach_id, seance_id, exercice_id, actions)
    if error:
        return jsonify({"error": error}), 400

    return jsonify({"success": True, "ids": ids, "count": len(ids)}), 200


@action_jeu_bp.route("/exercice/<int:exercice_id>/joueur/<int:joueur_id>/stats", methods=["GET"])
@jwt_required()
def stats_joueur_exercice(exercice_id, joueur_id):
    stats = get_stats_exercice_pour_joueur(exercice_id, joueur_id)
    return jsonify(stats), 200


@action_jeu_bp.route("/exercice/<int:exercice_id>/stats", methods=["GET"])
@jwt_required()
def stats_exercice(exercice_id):
    stats = get_stats_exercice_complet(exercice_id)
    return jsonify(stats), 200


@action_jeu_bp.route("/seance/<int:seance_id>/stats", methods=["GET"])
@jwt_required()
def stats_seance(seance_id):
    stats = get_stats_seance_complete(seance_id)
    return jsonify(stats), 200


@action_jeu_bp.route("/action/<int:action_id>", methods=["DELETE"])
@jwt_required()
def supprimer(action_id):
    coach_id = int(get_jwt_identity())
    ok, error = supprimer_action(coach_id, action_id)
    if not ok:
        return jsonify({"error": error}), 400
    return jsonify({"success": True}), 200
```

### 5.1 Enregistrement dans `app/__init__.py`

```python
# Import des modèles
from .models import ..., action_jeu, action_jeu_json
action_jeu.app_context(app)
action_jeu_json.app_context(app)

# Import et enregistrement du blueprint
from .controllers.action_jeu import action_jeu_bp
app.register_blueprint(action_jeu_bp, url_prefix="/api/actions")
```

---

## 6. Migration SQL complète (Supabase)

```sql
-- Migration exercice.domaine -> exercice.domaines (voir section 1.2 pour le détail complet)
ALTER TABLE exercices ADD COLUMN IF NOT EXISTS domaines JSON;
UPDATE exercices SET domaines = json_build_array(domaine) WHERE domaine IS NOT NULL AND domaines IS NULL;
UPDATE exercices SET domaines = '[]'::json WHERE domaines IS NULL;

-- Table actions_jeu (implémentation colonnes fixes — MVP)
CREATE TABLE IF NOT EXISTS actions_jeu (
    id SERIAL PRIMARY KEY,
    seance_id INTEGER NOT NULL REFERENCES seances(id) ON DELETE CASCADE,
    exercice_id INTEGER NOT NULL REFERENCES exercices(id) ON DELETE CASCADE,
    joueur_id INTEGER NOT NULL REFERENCES joueurs(id) ON DELETE CASCADE,
    domaine VARCHAR(20) NOT NULL,
    position VARCHAR(30),
    type_action VARCHAR(30),
    zone VARCHAR(30),
    qualite VARCHAR(30),
    resultat VARCHAR(30),
    point_direct BOOLEAN,
    touche BOOLEAN,
    nombre_bloqueurs INTEGER,
    puissance_adverse VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_actions_jeu_seance ON actions_jeu(seance_id);
CREATE INDEX IF NOT EXISTS idx_actions_jeu_exercice ON actions_jeu(exercice_id);
CREATE INDEX IF NOT EXISTS idx_actions_jeu_joueur ON actions_jeu(joueur_id);
CREATE INDEX IF NOT EXISTS idx_actions_jeu_domaine ON actions_jeu(domaine);

-- Table actions_jeu_json (implémentation JSON — pour comparaison)
CREATE TABLE IF NOT EXISTS actions_jeu_json (
    id SERIAL PRIMARY KEY,
    seance_id INTEGER NOT NULL REFERENCES seances(id) ON DELETE CASCADE,
    exercice_id INTEGER NOT NULL REFERENCES exercices(id) ON DELETE CASCADE,
    joueur_id INTEGER NOT NULL REFERENCES joueurs(id) ON DELETE CASCADE,
    domaine VARCHAR(20) NOT NULL,
    donnees JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_actions_jeu_json_seance ON actions_jeu_json(seance_id);
CREATE INDEX IF NOT EXISTS idx_actions_jeu_json_exercice ON actions_jeu_json(exercice_id);
```

---

## 7. Frontend Flutter — écran "Exécuter la séance"

### 7.1 Point d'entrée

Sur l'aperçu d'un planning (`planning_detail_dialog.dart`), à côté du bouton existant "Noter les absences" (déjà implémenté sur chaque séance), ajouter un bouton **"Exécuter la séance"** qui navigue vers un nouvel écran `ExecuterSeanceScreen`, en lui passant `seanceId`.

Route à ajouter dans `main.dart` :
```dart
GoRoute(
  path: '/executer-seance/:seanceId',
  builder: (context, state) {
    final seanceId = int.tryParse(state.pathParameters['seanceId'] ?? '') ?? 0;
    return ExecuterSeanceScreen(seanceId: seanceId);
  },
),
```
Et l'ajouter à la whitelist du `redirect` comme les autres routes protégées (`!loc.startsWith('/executer-seance')`).

### 7.2 Structure de l'écran

---

#### [NEW] `screen/executer_seance_screen.dart`

Comportement attendu, détaillé pas à pas :

1. **Chargement initial** : récupère la séance (via l'API planning existante ou une route dédiée) avec la liste ordonnée de ses exercices et la liste des joueurs du planning.

2. **Vue "liste des exercices"** : affiche les exercices de la séance dans l'ordre (`ordre`), chacun avec son titre et ses domaines. Un exercice a un statut : `à faire`, `en cours`, `terminé`.

3. **Tap sur un exercice "à faire"** → ouvre la **vue de saisie de cet exercice** (voir 7.3).

4. **État local de l'exercice en cours** : une liste en mémoire (`List<Map<String, dynamic>> _actionsEnAttente`) qui accumule les actions validées localement, invisible à l'écran (pas de tableau qui grossit).

5. **Bouton "Terminer l'exercice"** (visible même si `_actionsEnAttente` est vide, pour permettre de passer un exercice sans action à saisir) :
   - Si `_actionsEnAttente` n'est pas vide → envoie **un seul appel** `POST /api/actions/seance/<seanceId>/exercice/<exerciceId>/actions` avec tout le batch
   - Pendant l'envoi : bouton en état de chargement, **impossible de naviguer ailleurs**
   - Si succès : marque l'exercice comme `terminé`, vide `_actionsEnAttente`, retourne à la vue liste des exercices
   - Si échec (erreur réseau ou serveur) : affiche un message d'erreur clair, **le coach reste bloqué sur cet exercice**, bouton "Réessayer l'envoi" reste disponible, `_actionsEnAttente` **n'est pas vidée** (aucune perte de données)

### 7.3 Vue de saisie d'une action — le formulaire générique

---

#### [NEW] `widgets/action_saisie_form.dart`

C'est le composant central, **un seul composant réutilisé pour les 6 domaines**, piloté par `domainesActionConfig`.

Comportement :

1. Si l'exercice a **un seul domaine**, afficher un seul bloc de saisie pour ce domaine.
2. Si l'exercice a **plusieurs domaines** (ex. service + réception), afficher **un bloc de saisie séparé par domaine**, chacun indépendant (pas de lien entre eux, conformément à la décision actée).
3. Pour chaque bloc de domaine :
   - Un sélecteur de **joueur** (dropdown ou liste des joueurs du planning)
   - Pour chaque champ défini dans `domainesActionConfig[domaine].champs`, un sélecteur (chips ou dropdown) avec les valeurs possibles
   - Un bouton **"Valider l'action"** (grand, facilement tapable — usage terrain en conditions réelles, pas un formulaire de bureau)
4. Au tap sur "Valider l'action" :
   - Construit l'objet `{"joueur_id": ..., "domaine": ..., "donnees": {...}}`
   - L'ajoute à `_actionsEnAttente` (au niveau de l'écran parent, via callback ou state management)
   - **Réinitialise immédiatement le formulaire à son état vide** (aucun champ pré-rempli, sauf éventuellement le joueur si on veut permettre une saisie rapide en rafale sur le même joueur — à la discrétion de l'implémentation, non bloquant)
5. Un compteur discret (ex. "12 actions enregistrées pour cet exercice") peut être affiché pour rassurer visuellement le coach que la saisie s'accumule bien, **sans afficher le détail de chaque action**.

> [!NOTE]
> Le mécanisme de stockage local demandé est un **stockage en mémoire (state Flutter)**, pas un stockage persistant type `localStorage`/`SharedPreferences`. Ceci est un choix par défaut pour la simplicité — si le porteur du projet veut une résilience à un rafraîchissement accidentel de page ou une fermeture d'app en cours d'exercice, il faudra ajouter une persistance locale (SharedPreferences en mobile, window.sessionStorage en web) en complément. **Ce point n'a pas été tranché explicitement dans les échanges et doit être confirmé avant implémentation finale.**

### 7.4 Service Flutter

---

#### [NEW] `services/action_jeu_service.dart`

```dart
import 'api_service.dart';

class ActionJeuService {
  static Future<Map<String, dynamic>> getConfig() async {
    return await ApiService.get('/actions/config');
  }

  static Future<Map<String, dynamic>> enregistrerBatch(
      int seanceId, int exerciceId, List<Map<String, dynamic>> actions) async {
    return await ApiService.post(
      '/actions/seance/$seanceId/exercice/$exerciceId/actions',
      {'actions': actions},
    );
  }

  static Future<Map<String, dynamic>> getStatsJoueurExercice(
      int exerciceId, int joueurId) async {
    return await ApiService.get('/actions/exercice/$exerciceId/joueur/$joueurId/stats');
  }

  static Future<Map<String, dynamic>> getStatsExercice(int exerciceId) async {
    return await ApiService.get('/actions/exercice/$exerciceId/stats');
  }

  static Future<Map<String, dynamic>> getStatsSeance(int seanceId) async {
    return await ApiService.get('/actions/seance/$seanceId/stats');
  }
}
```

---

## 8. Écran de consultation des statistiques

---

#### [NEW] `screen/stats_seance_screen.dart`

Une fois une séance exécutée (au moins un exercice terminé avec des actions enregistrées), un écran permet de consulter les résultats agrégés :

- Par exercice, par joueur : affichage du détail retourné par `get_stats_joueur_exercice` — total d'actions, répartition par champ (ex. "Kavogo — Service : 10 actions — 8 smashés / 2 flottants — 5 réussis / 3 perdus / 2 ace")
- Format d'affichage libre à l'implémentation, mais doit rester lisible rapidement par un coach en conditions réelles (pas un tableau brut de données)

> [!NOTE]
> Ce plan ne détaille pas le design précis de cet écran de consultation ni le lien visuel exact avec le futur planning ajusté — cette partie ("le planning se construit en fonction des stats") a été évoquée comme vision mais n'a pas encore de spécification concrète validée. **Cette section est un point ouvert à clarifier dans une itération suivante**, hors du périmètre des 2 semaines.

---

## 9. Récapitulatif des fichiers

### Backend

| Fichier | Action |
|---|---|
| `models/exercices.py` | Modifié — `domaine` → `domaines` (JSON) |
| `services/bilan.py` | Modifié — boucle de calcul par domaine adaptée à liste + durée complète par domaine |
| `services/pdf.py` | Modifié — affichage domaines multiples par exercice |
| `services/excel_export.py` | Modifié — idem si référence à `exercice.domaine` |
| `services/rapport_mensuel.py` | Modifié — idem |
| `config/domaines_action_config.py` | **NOUVEAU** |
| `models/action_jeu.py` | **NOUVEAU** (implémentation colonnes) |
| `models/action_jeu_json.py` | **NOUVEAU** (implémentation JSON) |
| `repositories/action_jeu_repository.py` | **NOUVEAU** (interface abstraite) |
| `repositories/action_jeu_repository_colonnes.py` | **NOUVEAU** |
| `repositories/action_jeu_repository_json.py` | **NOUVEAU** |
| `repositories/action_jeu_factory.py` | **NOUVEAU** |
| `services/action_jeu.py` | **NOUVEAU** |
| `controllers/action_jeu.py` | **NOUVEAU** |
| `app/__init__.py` | Modifié — enregistrement modèles + blueprint |

### Frontend

| Fichier | Action |
|---|---|
| `lib/utils/domaines_action_config.dart` | **NOUVEAU** |
| `screen/executer_seance_screen.dart` | **NOUVEAU** |
| `widgets/action_saisie_form.dart` | **NOUVEAU** |
| `screen/stats_seance_screen.dart` | **NOUVEAU** |
| `services/action_jeu_service.dart` | **NOUVEAU** |
| `widgets/planning_detail_dialog.dart` | Modifié — bouton "Exécuter la séance" |
| Formulaire création/édition d'exercice | Modifié — sélection multi-domaines au lieu de mono-domaine |
| `main.dart` | Modifié — route `/executer-seance/:seanceId` |

---

## 10. Points ouverts / non tranchés — À CLARIFIER avant ou pendant l'implémentation

Ces points ont été identifiés pendant la conception mais n'ont pas de décision actée. Ne pas les trancher unilatéralement sans validation :

1. **Persistance locale du formulaire de saisie** (mémoire simple vs stockage persistant résistant à un rafraîchissement accidentel) — voir note section 7.3
2. **Le lien concret entre statistiques et ajustement du planning suivant** (affichage côte à côte prévu/réalisé ? suggestion automatique ? action manuelle du coach uniquement ?) — vision exprimée mais non spécifiée
3. **Labels et traductions i18n exactes** des valeurs de chaque champ (ex. comment afficher "bloc_out" en français et anglais dans l'UI) — à définir en suivant le pattern i18n existant du projet
4. **Design précis de l'écran de consultation des stats** (section 8) — non spécifié dans le détail
5. **Choix final entre implémentation colonnes et JSON** — les deux doivent être fonctionnelles, le porteur du projet tranchera après test comparatif réel

---

## 11. Ordre d'implémentation recommandé (pour tenir le délai de 2 semaines)

```
Jour 1-2   : Migration exercice.domaine → domaines + corrections bilan/pdf/excel/rapport
Jour 3-4   : Config domaines (backend + frontend) + modèle et repository colonnes (MVP)
Jour 5     : Service action_jeu.py + controller + tests Postman des routes
Jour 6-8   : Frontend — écran ExecuterSeanceScreen + ActionSaisieForm générique
Jour 9     : Intégration bouton dans planning_detail_dialog + route + tests end-to-end
Jour 10    : Écran de consultation des stats (version simple)
Jour 11-12 : Tests réels avec le coach concerné, ajustements UX terrain
Jour 13    : Implémentation JSON en parallèle SI le temps le permet, sinon reportée après la CAN
Jour 14    : Marge de sécurité / corrections de bugs
```

> [!IMPORTANT]
> Si le temps manque, la priorité absolue est : migration domaines + config + repository colonnes + service + controller + écran de saisie fonctionnel. L'écran de consultation des stats détaillé et l'implémentation JSON parallèle peuvent être sacrifiés ou simplifiés en premier si le délai de 2 semaines est trop serré.
