# VolleyPlan — Partage Public, Export Excel & Rapport Mensuel

## Contexte

Ajout de 3 fonctionnalités indépendantes :

1. **Partage public d'un planning** — lien avec token, lecture seule, expire après 15 jours, non révocable manuellement
2. **Export Excel** — fichier `.xlsx` à 3 feuilles (Planning détaillé / Bilan / Présences avec statut)
3. **Rapport mensuel automatique** — généré le 1er de chaque mois pour tout planning ayant au moins 15 jours d'existence, envoyé par notification in-app + email

---

## Décisions actées

| Sujet | Décision |
|---|---|
| Équipes multiples | **Reporté** — hors périmètre de ce plan |
| Partage public — droits | Lecture seule stricte, aucune action possible |
| Partage public — durée | 15 jours depuis la génération, non révocable manuellement |
| Partage public — après expiration | Le coach doit régénérer un nouveau lien |
| Excel — structure | 3 feuilles : Planning détaillé, Bilan, Présences |
| Excel — feuille Présences | Toutes les séances affichées avec colonne `Statut` (Effectuée / Non effectuée / Planifiée) |
| Rapport mensuel — déclenchement | Automatique le 1er de chaque mois + génération à la demande |
| Rapport mensuel — condition | Planning existant depuis ≥ 15 jours |
| Rapport mensuel — canal | Notification in-app + email (Brevo) |
| Rapport mensuel — source de vérité | Une séance est "effectuée" si `presences_prises = True` |

---

## Architecture existante (rappel)

| Modèle | Table | Champs clés |
|--------|-------|-------------|
| `Coach` | `coaches` | `forfait`, `expire_forfait` |
| `Joueur` | `joueurs` | `coach_id`, `poste`, `actif` |
| `Planning` | `plannings` | `coach_id`, `created_at`, joueurs via `planning_joueurs` |
| `Seance` | `seances` | `planning_id`, `date_seance`, `heure_debut`, `domaines`, `presences_prises`, `presences_auto` |
| `Exercice` | `exercices` | `seance_id`, `domaine`, `duree` |
| `Absence` | `absences` | `seance_id`, `joueur_id`, `motif` |
| `Notification` | `notifications` | `coach_id`, `message`, `type`, `seance_id` |

---

## 1. Partage public d'un planning

### Workflow

```
Coach clique "Partager" sur un planning
      │
      ▼
Génération d'un token unique (UUID) + expires_at = now + 15 jours
      │
      ▼
Lien généré : https://volleyplan.app/public/planning/<token>
      │
      ▼
Le destinataire ouvre le lien SANS connexion
      │
      ├─► Token valide et non expiré → affichage lecture seule du planning
      │
      └─► Token expiré ou introuvable → page "Ce lien a expiré"
      │
      ▼
Après 15 jours → le lien ne fonctionne plus, le coach doit en générer un nouveau
```

### 1.1 Modèles (DB)

---

#### [NEW] `models/partage_public.py`

Un planning ne peut avoir qu'un seul lien de partage actif à la fois. Régénérer un lien invalide l'ancien (nouveau token + nouvelle date d'expiration écrasent les anciens).

```python
import uuid
from datetime import datetime, timedelta
from app import db

class PartagePublic(db.Model):
    __tablename__ = "partages_publics"
    id          = db.Column(db.Integer, primary_key=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id", ondelete="CASCADE"), nullable=False, unique=True)
    token       = db.Column(db.String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at  = db.Column(db.DateTime, nullable=False)

    @staticmethod
    def generer_expiration():
        return datetime.utcnow() + timedelta(days=15)

    @property
    def est_expire(self):
        return datetime.utcnow() > self.expires_at

    def to_dict(self):
        return {
            "token": self.token,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat(),
            "est_expire": self.est_expire,
        }
```

> [!NOTE]
> Régénérer un lien = `UPDATE` du même enregistrement (nouveau `token`, nouveau `expires_at`), pas une nouvelle ligne. Ça garde une seule source de vérité par planning et évite l'accumulation de tokens morts.

---

### 1.2 Services

---

#### [NEW] `services/partage_public.py`

```python
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
```

---

### 1.3 Controllers

---

#### [NEW] `controllers/partage_public.py`

Nouveau blueprint `partage_bp`.

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `POST` | `/api/plannings/<id>/partage` | `@jwt_required` | Génère ou régénère le lien de partage |
| `GET` | `/api/public/planning/<token>` | **Aucune** | Consultation publique lecture seule |

**Réponse `POST /api/plannings/<id>/partage` :**
```json
{
  "success": true,
  "token": "a1b2c3d4-...",
  "url": "https://volleyplan.app/public/planning/a1b2c3d4-...",
  "expires_at": "2026-07-17T10:00:00"
}
```

**Réponse `GET /api/public/planning/<token>` (token valide) :**
```json
{
  "success": true,
  "planning": { "titre": "...", "seances": [...], "..." : "..." },
  "expires_at": "2026-07-17T10:00:00"
}
```

**Réponse (token expiré/invalide) :**
```json
{ "success": false, "message": "Ce lien a expiré ou est invalide" }
```
→ HTTP 410 (Gone) pour expiré, 404 pour token inexistant.

---

### 1.4 Frontend Flutter

---

#### [MODIFY] `widgets/planning_detail_dialog.dart`

Ajout d'un bouton **Partager** dans `_buildActionButtons`, visible si `isOwner`. Ouvre un dialog `SharePlanningDialog`.

#### [NEW] `widgets/share_planning_dialog.dart`

```
- Appelle POST /api/plannings/<id>/partage au premier affichage
- Affiche l'URL générée avec bouton "Copier le lien"
- Affiche la date d'expiration ("Expire le 17 juillet 2026")
- Bouton "Régénérer un nouveau lien" → réappelle la même route (écrase l'ancien)
- Pas de bouton "Révoquer" (décision produit)
```

#### [NEW] `screen/public_planning_screen.dart`

Écran public, accessible sans connexion.

```
- Reçoit le token via GoRouter path param
- Appelle GET /api/public/planning/<token>
- Si succès → affiche le planning en lecture seule
  (réutilise les widgets d'affichage existants type _buildPlanningOverview,
   mais SANS les boutons d'action : pas d'édition, pas de suppression,
   pas de "Noter les absences")
- Si expiré/invalide → écran "Ce lien a expiré" avec logo VolleyPlan
  et CTA "Découvrir VolleyPlan" → /register
```

#### [MODIFY] `main.dart`

```dart
GoRoute(
  path: '/public/planning/:token',
  builder: (context, state) =>
      PublicPlanningScreen(token: state.pathParameters['token']!),
),
```
→ Cette route est **hors** de la vérification `loggedIn` dans le `redirect` (comme `/privacy`, `/terms`).

---

## 2. Export Excel

### 2.1 Dépendance

```
openpyxl
```
→ À ajouter dans `requirements.txt`.

### 2.2 Structure du fichier

**Feuille 1 — "Planning"**
| Colonne | Contenu |
|---|---|
| Séance | Numéro + titre |
| Date | `date_seance` |
| Heure | `heure_debut` |
| Domaines | Liste des domaines travaillés |
| Exercices | Nom + durée de chaque exercice |
| Durée totale | Somme des durées d'exercices de la séance |

**Feuille 2 — "Bilan"**
| Colonne | Contenu |
|---|---|
| Domaine | Nom du domaine |
| Volume (min) | Minutes totales sur le planning |
| % du total | Pourcentage |
| Recommandation | Texte de recommandation associé (si applicable) |

Plus en en-tête : nombre total de séances, volume total, durée moyenne par séance.

**Feuille 3 — "Présences"**
| Colonne | Contenu |
|---|---|
| Séance | Numéro + titre |
| Date | `date_seance` |
| **Statut** | `Effectuée` / `Non effectuée` / `Planifiée` |
| Joueur 1, Joueur 2, ... | Une colonne par joueur du planning avec ✓ / ✗ / — |

**Logique du Statut :**
```python
if seance.date_seance_passee and seance.presences_prises:
    statut = "Effectuée"
elif seance.date_seance_passee and not seance.presences_prises:
    statut = "Non effectuée"
else:
    statut = "Planifiée"  # date future
```

### 2.3 Services

---

#### [NEW] `services/excel_export.py`

```python
def generer_excel_planning(planning_id, coach_id) -> BytesIO:
    """
    - Vérifie que le planning appartient au coach
    - Construit le classeur openpyxl avec les 3 feuilles décrites ci-dessus
    - Applique un style basique cohérent avec la charte VolleyPlan
      (en-têtes fond rouge/charcoal, texte blanc, colonnes auto-ajustées)
    - Retourne le fichier en mémoire (BytesIO) prêt à être streamé
    """
```

> [!NOTE]
> Réutilise `services/stats_joueurs.py` et la logique de bilan existante (`bilan.py`) pour ne pas dupliquer les calculs. La feuille 2 doit consommer les mêmes données que celles utilisées pour l'affichage du bilan dans l'app.

### 2.4 Controllers

---

#### [MODIFY] `controllers/planning.py`

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `GET` | `/api/plannings/<id>/export/excel` | `@jwt_required` | Télécharge le fichier `.xlsx` |

Réponse : fichier binaire avec headers appropriés :
```python
return send_file(
    excel_buffer,
    mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    as_attachment=True,
    download_name=f"planning_{planning.titre}.xlsx"
)
```

### 2.5 Frontend Flutter

---

#### [NEW] `services/excel_service.dart`

Miroir de `pdf_service.dart` existant, mais pointant vers `/export/excel` et gérant le téléchargement `.xlsx` au lieu du `.pdf`.

#### [MODIFY] `widgets/planning_detail_dialog.dart`

Dans `_buildActionButtons`, ajout d'un bouton **Export Excel** à côté du bouton Export PDF existant, visible si `isOwner`.

---

## 3. Rapport mensuel automatique

### Workflow

```
Chaque 1er du mois (job planifié)
      │
      ▼
Pour chaque planning actif où (now - created_at) ≥ 15 jours :
      │
      ├─► Calcul du rapport du mois écoulé
      │     - Séances prévues sur la période
      │     - Séances effectuées (presences_prises = True)
      │     - Taux de réalisation
      │     - Volume prévu vs réel par domaine
      │     - Taux de présence moyen de l'équipe
      │     - Liste des séances manquantes
      │
      ├─► Création Notification (type="rapport_mensuel") pour le coach
      │
      └─► Envoi email (Brevo) avec le rapport en pièce jointe PDF
      │
      ▼
Le coach peut aussi générer ce même rapport à la demande
depuis l'app, pour n'importe quelle période antérieure
```

### 3.1 Modèles (DB)

---

#### [NEW] `models/rapport_mensuel.py`

On stocke les rapports générés pour permettre leur consultation ultérieure sans recalcul.

```python
class RapportMensuel(db.Model):
    __tablename__ = "rapports_mensuels"
    id          = db.Column(db.Integer, primary_key=True)
    planning_id = db.Column(db.Integer, db.ForeignKey("plannings.id", ondelete="CASCADE"), nullable=False)
    coach_id    = db.Column(db.Integer, db.ForeignKey("coaches.id", ondelete="CASCADE"), nullable=False)
    periode_debut = db.Column(db.Date, nullable=False)
    periode_fin   = db.Column(db.Date, nullable=False)
    donnees     = db.Column(db.JSON, nullable=False)  # snapshot complet du rapport
    genere_auto = db.Column(db.Boolean, default=True)  # False si généré à la demande
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("planning_id", "periode_debut", "periode_fin"),
    )
```

> [!IMPORTANT]
> La contrainte unique empêche de générer deux fois le rapport auto pour la même période. Une génération "à la demande" sur une période déjà couverte retourne le rapport existant au lieu d'en recalculer un.

#### [MODIFY] `models/notification.py`

`type = "rapport_mensuel"` s'ajoute aux valeurs possibles déjà gérées par le champ existant. Pas de modification de structure nécessaire (le champ `type` est déjà générique).

---

### 3.2 Services

---

#### [NEW] `services/rapport_mensuel.py`

```python
def calculer_rapport(planning_id, periode_debut, periode_fin) -> dict:
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

def generer_rapport_si_eligible(planning_id, auto=True) -> dict | None:
    """
    - Vérifie planning.created_at + 15 jours <= now
    - Calcule periode_debut/periode_fin (mois précédent complet)
    - Si un RapportMensuel existe déjà pour cette période → le retourne
    - Sinon → appelle calculer_rapport(), sauvegarde en DB, retourne le nouveau
    """

def generer_rapport_a_la_demande(coach_id, planning_id, periode_debut, periode_fin) -> dict:
    """
    Version manuelle : le coach choisit sa période.
    Même logique de calcul, mais genere_auto=False à la sauvegarde.
    """
```

---

### 3.3 Job planifié (APScheduler)

---

#### [MODIFY] `scheduler.py`

Nouveau job, exécuté une fois par jour (vérifie si on est le 1er du mois) :

```
Tous les jours à minuit UTC :
  Si aujourd'hui == 1er du mois :
    Pour chaque Planning actif :
      Si (now - planning.created_at).days >= 15 :
        rapport = generer_rapport_si_eligible(planning.id, auto=True)
        Si rapport nouvellement créé :
          → Créer Notification (type="rapport_mensuel", ...)
          → Générer le PDF du rapport (réutilise services/pdf.py)
          → Envoyer par email via Brevo (pièce jointe PDF)
```

> [!NOTE]
> Exécution "tous les jours à minuit + vérification si 1er du mois" plutôt qu'un cron mensuel direct, pour rester cohérent avec l'approche déjà en place dans `scheduler.py` et éviter de dépendre d'un scheduling cron externe fragile sur Render.

---

### 3.4 Controllers

---

#### [NEW] `controllers/rapport_mensuel.py`

Nouveau blueprint `rapport_bp`.

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `GET` | `/api/plannings/<id>/rapports` | `@jwt_required` | Liste des rapports déjà générés pour ce planning |
| `GET` | `/api/plannings/<id>/rapports/<rapport_id>` | `@jwt_required` | Détail d'un rapport |
| `POST` | `/api/plannings/<id>/rapports/generer` | `@jwt_required` | Génération à la demande (body: `periode_debut`, `periode_fin`) |
| `GET` | `/api/plannings/<id>/rapports/<rapport_id>/pdf` | `@jwt_required` | Télécharge le rapport en PDF |

#### [MODIFY] `controllers/notifications.py`

Le `to_dict()` gère déjà `type` et `seance_id`. Pour `type="rapport_mensuel"`, `seance_id` sera `null` — le frontend doit gérer ce cas en redirigeant vers `/planning/<id>/rapports` plutôt que vers une séance.

---

### 3.5 PDF du rapport

---

#### [MODIFY] `services/pdf.py`

Ajout d'une fonction `generer_pdf_rapport_mensuel(rapport_data, planning) -> BytesIO`, réutilisant le style ReportLab déjà en place pour les plannings (logo, couleurs VolleyPlan), avec sections : résumé, graphique simple de répartition par domaine (barres), taux de présence, liste des séances manquantes.

---

### 3.6 Email (Brevo)

---

#### [MODIFY] `services/email.py`

Nouveau template d'email `rapport_mensuel` :

```
Objet : Votre rapport mensuel VolleyPlan — [Nom du planning]

Corps :
  Bonjour [Coach],
  Voici le bilan de votre préparation pour [Mois] :
  - X séances effectuées sur Y prévues (Z%)
  - Taux de présence moyen : W%
  [Voir le rapport complet dans l'app] (lien vers /planning/<id>/rapports/<id>)

  Pièce jointe : rapport_mensuel_[mois].pdf
```

---

### 3.7 Frontend Flutter

---

#### [NEW] `screen/rapport_mensuel_screen.dart`

```
- Liste des rapports disponibles pour un planning (chronologique, plus récent en premier)
- Chaque rapport : période, taux de réalisation en gros, bouton "Voir le détail"
- Détail d'un rapport : résumé, graphique répartition par domaine
  (réutilise les mêmes widgets que le bilan existant),
  taux de présence, liste des séances manquantes
- Bouton "Générer un rapport pour une autre période" → date picker range
  → appelle POST /rapports/generer
- Bouton "Télécharger en PDF"
```

#### [NEW] `services/rapport_service.dart`

Miroir de `bilan_service.dart`/`pdf_service.dart` existants, pointant vers les nouvelles routes `/rapports`.

#### [MODIFY] `screen/home_screen.dart`

Dans le bloc notifications, ajout d'un cas pour `type == "rapport_mensuel"` :

```dart
final isRapport = n.type == "rapport_mensuel";
// Style distinct (ex: vert), tap → context.push('/planning/${n.seanceId ?? planningIdDuRapport}/rapports')
```

> [!IMPORTANT]
> Pour que ce tap fonctionne, la notification doit porter le `planning_id`, pas seulement `seance_id`. Ajouter un champ `planning_id` sur `Notification` (nullable, `ON DELETE SET NULL`) pour ce cas d'usage, distinct de `seance_id` déjà utilisé pour les rappels de présence.

#### [MODIFY] `models/notification.dart` (Flutter)

```dart
final int? planningId;
// ajouté au constructeur + fromJson, en miroir de seanceId
```

#### [MODIFY] `main.dart`

```dart
GoRoute(
  path: '/planning/:id/rapports',
  builder: (context, state) => RapportMensuelScreen(
    planningId: int.parse(state.pathParameters['id']!),
  ),
),
```

---

## Fichiers créés / modifiés — Récapitulatif

### Backend

| Fichier | Action |
|---------|--------|
| `models/partage_public.py` | **NOUVEAU** |
| `models/rapport_mensuel.py` | **NOUVEAU** |
| `models/notification.py` | Modifié — ajout `planning_id` |
| `services/partage_public.py` | **NOUVEAU** |
| `services/excel_export.py` | **NOUVEAU** |
| `services/rapport_mensuel.py` | **NOUVEAU** |
| `services/pdf.py` | Modifié — ajout génération PDF rapport |
| `services/email.py` | Modifié — template rapport mensuel |
| `controllers/partage_public.py` | **NOUVEAU** |
| `controllers/rapport_mensuel.py` | **NOUVEAU** |
| `controllers/planning.py` | Modifié — route export Excel |
| `controllers/notifications.py` | Modifié — gérer `planning_id` dans réponse |
| `scheduler.py` | Modifié — job rapport mensuel |
| `app/__init__.py` | Modifié — register `partage_bp`, `rapport_bp` |
| `requirements.txt` | Modifié — ajout `openpyxl` |

### Frontend

| Fichier | Action |
|---------|--------|
| `widgets/share_planning_dialog.dart` | **NOUVEAU** |
| `screen/public_planning_screen.dart` | **NOUVEAU** |
| `screen/rapport_mensuel_screen.dart` | **NOUVEAU** |
| `services/excel_service.dart` | **NOUVEAU** |
| `services/rapport_service.dart` | **NOUVEAU** |
| `widgets/planning_detail_dialog.dart` | Modifié — boutons Partager + Export Excel |
| `screen/home_screen.dart` | Modifié — notif type `rapport_mensuel` |
| `models/notification.dart` | Modifié — ajout `planningId` |
| `main.dart` | Modifié — routes `/public/planning/:token`, `/planning/:id/rapports` |

---

## Migration DB

```sql
-- Partage public
CREATE TABLE IF NOT EXISTS partages_publics (
    id SERIAL PRIMARY KEY,
    planning_id INTEGER NOT NULL UNIQUE REFERENCES plannings(id) ON DELETE CASCADE,
    token VARCHAR(36) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL
);

-- Rapports mensuels
CREATE TABLE IF NOT EXISTS rapports_mensuels (
    id SERIAL PRIMARY KEY,
    planning_id INTEGER NOT NULL REFERENCES plannings(id) ON DELETE CASCADE,
    coach_id INTEGER NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
    periode_debut DATE NOT NULL,
    periode_fin DATE NOT NULL,
    donnees JSONB NOT NULL,
    genere_auto BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(planning_id, periode_debut, periode_fin)
);

-- Notification : lien vers un planning (pour les rapports mensuels)
ALTER TABLE notifications
ADD COLUMN IF NOT EXISTS planning_id INTEGER REFERENCES plannings(id) ON DELETE SET NULL;
```

### Installation dépendance

```bash
pip install openpyxl
```

---

## Verification Plan

### Partage public
1. ✅ Coach génère un lien → token créé, `expires_at` = now + 15 jours
2. ✅ Régénération → même `planning_id`, nouveau token, ancien token invalide immédiatement
3. ✅ `GET /api/public/planning/<token>` sans auth → retourne le planning en lecture seule
4. ✅ Après 15 jours (ou en simulant `expires_at` dans le passé) → 410 Gone
5. ✅ Token inexistant → 404
6. ✅ Aucune donnée sensible (email collaborateurs) dans la réponse publique

### Export Excel
7. ✅ Fichier `.xlsx` téléchargé s'ouvre correctement (Excel/LibreOffice)
8. ✅ Feuille Présences : séance future → "Planifiée", séance passée avec présences → "Effectuée", séance passée sans présences → "Non effectuée"
9. ✅ Chiffres de la feuille Bilan identiques à ceux affichés dans l'app

### Rapport mensuel
10. ✅ Planning créé il y a < 15 jours → pas de rapport généré même si on est le 1er du mois
11. ✅ Planning créé il y a ≥ 15 jours → rapport généré le 1er du mois suivant
12. ✅ Génération auto en double le même mois → bloquée par la contrainte unique, retourne l'existant
13. ✅ Génération à la demande sur période déjà couverte → retourne le rapport existant (`genere_auto` inchangé)
14. ✅ Notification créée avec `planning_id` renseigné et `seance_id` null
15. ✅ Email reçu avec PDF en pièce jointe
16. ✅ Taux de réalisation cohérent : `nb_seances_effectuees / nb_seances_prevues * 100`
