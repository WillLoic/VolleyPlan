# Générateur de Planning IA (Gemini)

C'est une excellente idée ! Utiliser Gemini (que tu as déjà configuré dans `AI.py`) pour générer automatiquement des plannings va faire gagner un temps fou aux coachs.

## User Review Required
> [!IMPORTANT]
> **Choix de l'Expérience Utilisateur (UX)**
> Tu as mentionné que l'IA doit demander au coach s'il veut inclure les statistiques s'il ne le précise pas. Il y a deux façons de faire cela :
> 
> **Option A (Recommandée - Formulaire Simple)** : Avant d'appeler l'IA, on affiche une "Bottom Sheet" ou un "Dialog" où le coach tape son besoin textuel (ex: *"Je veux 3 séances sur le bloc/défense"*). En dessous, on met un **bouton/toggle "Prendre en compte les statistiques de mon équipe"**. C'est rapide, clair, et ça évite une conversation à rallonge.
> 
> **Option B (Interface Chatbot)** : On crée un vrai écran de chat (type ChatGPT). Le coach discute, et l'IA lui répond *"Voulez-vous que j'analyse vos statistiques avant de générer le planning ?"*. C'est plus interactif mais beaucoup plus long à développer et potentiellement plus lent pour le coach.
> 
> **=> Quelle option préfères-tu ? L'Option A est la plus efficace côté UX.**

## Proposed Architecture

### Backend (API & Services)

#### [NEW] `Backend/app/controllers/ai.py`
Nouveau contrôleur pour exposer l'endpoint POST `/api/ai/planning/generate`. Il recevra le `prompt` textuel et un booléen `use_stats`.

#### [MODIFY] `Backend/app/services/AI.py`
Mise à jour de `create_AI_planning()` pour accepter le prompt et les stats.
- **Prompt Engineering** : On va forcer Gemini 2.5 Flash à répondre avec un **schéma JSON strict** qui correspond exactement au format attendu par ton frontend (`titre`, `mode`, `nb_seances`, `seances`, `exercices`).
- **Stats Context** : Si `use_stats` est vrai, on ira chercher un résumé analytique des points forts/faibles de l'équipe (grâce aux statistiques existantes) et on les injectera dans le prompt caché envoyé à Gemini.

### Frontend (Flutter)

#### [NEW] `Frontend/volleyplan/lib/widgets/ai_generator_dialog.dart` (ou équivalent)
Un dialogue magnifique pour saisir la demande IA, avec le bouton "Inclure les stats". Il affichera un loader avec une petite animation pendant que Gemini réfléchit.

#### [MODIFY] `Frontend/volleyplan/lib/screen/planning/planning_form_screen.dart`
Une fois le JSON généré par l'IA renvoyé au frontend, plutôt que de l'enregistrer directement en base, on va **l'injecter dans le `PlanningFormScreen`**. Ainsi, le coach verra le planning généré par l'IA, pourra le lire, ajuster la durée de quelques exercices s'il le souhaite, puis cliquer sur "Sauvegarder" lui-même. C'est la meilleure pratique (Human in the loop).

#### [MODIFY] `Frontend/volleyplan/lib/screen/home/home_screen.dart` (ou `planning_list_screen.dart`)
Ajout d'un bouton flottant (FAB) stylisé "✨ Générer avec l'IA" pour déclencher le dialogue.

## Verification Plan
1. Lancer le dialogue IA.
2. Taper "Je veux un entrainement de 2 séances axé sur la réception, niveau avancé".
3. Cocher la case des stats.
4. Vérifier que le backend appelle Gemini, inclut les données, et retourne un JSON valide.
5. Vérifier que le formulaire `PlanningFormScreen` s'ouvre avec les 2 séances et les exercices pré-remplis.
