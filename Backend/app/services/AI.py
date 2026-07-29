import json, os
from google import genai
from google.genai import types


client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))


# Schéma JSON strict que Gemini doit respecter
_PLANNING_JSON_SCHEMA = {
    "type": "object",
    "properties": {
        "titre": {"type": "string"},
        "mode": {"type": "string", "enum": ["groupe", "individuel"]},
        "nb_seances": {"type": "integer"},
        "seances": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "titre": {"type": "string"},
                    "domaines": {
                        "type": "array",
                        "items": {
                            "type": "string",
                            "enum": ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]
                        }
                    },
                    "exercices": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "nom":         {"type": "string"},
                                "duree":       {"type": "integer", "description": "Durée en minutes"},
                                "domaines":    {
                                    "type": "array",
                                    "items": {
                                        "type": "string",
                                        "enum": ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]
                                    }
                                },
                                "description": {"type": "string"}
                            },
                            "required": ["nom", "duree", "domaines", "description"]
                        }
                    }
                },
                "required": ["titre", "domaines", "exercices"]
            }
        }
    },
    "required": ["titre", "mode", "nb_seances", "seances"]
}


class Chadeu_AI():

    @staticmethod
    def create_AI_planning(prompt: str, use_stats: bool, coach_id: int, language: str = "fr") -> dict:
        """
        Génère un planning structuré avec Gemini 2.5 Flash.
        
        Args:
            prompt:    La demande textuelle du coach (ex: "2 séances sur la réception")
            use_stats: Si True, injecte le contexte analytique de l'équipe dans le prompt
            coach_id:  L'ID du coach (pour récupérer ses stats si use_stats=True)
        
        Returns:
            dict: Le planning généré (titre, mode, nb_seances, seances, exercices)
        
        Raises:
            RuntimeError: En cas d'erreur API ou de réponse invalide
        """
        import time

        # --- Contexte des stats (optionnel) ---
        stats_context = ""
        if use_stats:
            try:
                from ..services.stats_joueurs import StatsJoueursService
                stats_data = StatsJoueursService.get_comparaison_equipe(coach_id)
                if stats_data.get("success") and stats_data.get("comparaison"):
                    # Calculer le volume total réel par domaine pour toute l'équipe
                    domaines_list = ["service", "reception", "passe", "attaque", "block", "defense", "physique", "general"]
                    volume_total = {d: 0 for d in domaines_list}
                    for joueur_stats in stats_data["comparaison"]:
                        for dom, vol in joueur_stats.get("volume_reel_par_domaine", {}).items():
                            if dom in volume_total:
                                volume_total[dom] += vol

                    # Trier du plus travaillé au moins travaillé
                    sorted_domaines = sorted(volume_total.items(), key=lambda x: x[1], reverse=True)
                    
                    # Créer un résumé lisible
                    points_forts = [d for d, v in sorted_domaines[:3] if v > 0]
                    points_faibles = [d for d, v in sorted_domaines if v == 0 or v == sorted_domaines[-1][1]]
                    nb_joueurs = len(stats_data["comparaison"])

                    stats_context = f"""
--- CONTEXTE ANALYTIQUE DE L'ÉQUIPE ---
Nombre de joueurs actifs : {nb_joueurs}
Volume d'entraînement réel par domaine (en minutes cumulées pour toute l'équipe) :
{chr(10).join(f'  - {d}: {v} min' for d, v in sorted_domaines)}
Domaines les plus travaillés : {', '.join(points_forts) if points_forts else 'N/A'}
Domaines les moins travaillés / à renforcer : {', '.join(points_faibles) if points_faibles else 'N/A'}
--- FIN DU CONTEXTE ---

En tenant compte de ces statistiques, favorise les domaines sous-travaillés dans ta génération si le coach ne précise pas de domaine particulier.
"""
            except Exception as stats_error:
                # On ne bloque pas la génération si les stats échouent
                print(f"[AI] Avertissement: impossible de charger les stats ({stats_error})")
                stats_context = ""

        # --- Construction du prompt système ---
        system_prompt = f"""Tu es un assistant expert en volleyball, spécialisé dans la planification d'entraînements.
Ta mission est de générer un planning d'entraînement de volleyball structuré et professionnel, adapté à la demande du coach.

{stats_context}

RÈGLES IMPORTANTES :
0. Tu DOIS générer tout le contenu textuel (titre, nom des exercices, descriptions) dans la langue correspondant au code ISO suivant : "{language}".
1. Génère des exercices réalistes, avec des noms clairs et des descriptions utiles (2-3 phrases max).
2. La durée de chaque exercice doit être réaliste (entre 10 et 45 minutes).
3. Le champ "mode" doit être "groupe" si l'entraînement concerne toute l'équipe, "individuel" sinon.
4. Les domaines disponibles sont UNIQUEMENT : service, reception, passe, attaque, block, defense, physique, general.
5. Chaque séance doit avoir entre 3 et 15 exercices.
6. Le titre du planning doit être concis et professionnel.
7. Réponds UNIQUEMENT en JSON valide, sans texte supplémentaire.

DEMANDE DU COACH :
{prompt}
"""

        # --- Appel Gemini ---
        start_ia = time.time()
        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[system_prompt],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=_PLANNING_JSON_SCHEMA,
                )
            )
        except Exception as api_error:
            error_str = str(api_error).lower()
            print(f"[AI] Erreur Gemini complète: {repr(api_error)}")  # ← ajoute ça
            if "503" in error_str or "unavailable" in error_str or "high demand" in error_str:
                raise RuntimeError("SERVICE_TEMPORAIREMENT_INDISPONIBLE")
            else:
                raise RuntimeError(f"ERREUR_SERVICE_IA: {str(api_error)}")

        print(f"[AI] Gemini a répondu en {time.time() - start_ia:.2f}s")

        # --- Validation de la réponse ---
        if not hasattr(response, 'text') or not response.text:
            raise RuntimeError("REPONSE_IA_INVALIDE: réponse vide de Gemini")

        try:
            planning_data = json.loads(response.text)
        except json.JSONDecodeError as e:
            raise RuntimeError(f"REPONSE_IA_INVALIDE: JSON malformé — {str(e)}")

        # Validation minimale de la structure
        required_keys = ["titre", "mode", "nb_seances", "seances"]
        for key in required_keys:
            if key not in planning_data:
                raise RuntimeError(f"REPONSE_IA_INVALIDE: champ manquant '{key}'")
            

        

        return planning_data