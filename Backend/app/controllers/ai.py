from flask import Blueprint, request, jsonify
from app.utils.decorators import premium_required, premium_plus_required
from flask_jwt_extended import get_jwt_identity, jwt_required
from app.services.AI import Chadeu_AI

ai_bp = Blueprint("ai", __name__)


@ai_bp.route("/planning/generate", methods=["POST"])
@jwt_required()
#@premium_plus_required
def generate_planning():
    """
    Génère un planning d'entraînement via Gemini IA.
    
    Body JSON:
        prompt   (str)  : La demande textuelle du coach.
        use_stats (bool): Si True, injecte le contexte des stats de l'équipe.
    
    Returns:
        200: Le planning généré (titre, mode, nb_seances, seances[])
        400: Champs manquants ou prompt vide
        403: Coach non premium (géré par @premium_required)
        502/503: Erreur du service IA
    """
    coach_id = int(get_jwt_identity())
    data = request.get_json()

    if not data:
        return jsonify({"error": "Corps de requête manquant."}), 400

    prompt = data.get("prompt", "").strip()
    use_stats = bool(data.get("use_stats", False))
    language = data.get("language", "fr")

    if not prompt:
        return jsonify({"error": "Le champ 'prompt' est requis et ne peut pas être vide."}), 400

    if len(prompt) > 1000:
        return jsonify({"error": "Le prompt est trop long (maximum 1000 caractères)."}), 400

    try:
        planning_data = Chadeu_AI.create_AI_planning(
            prompt=prompt,
            use_stats=use_stats,
            coach_id=coach_id,
            language=language,
        )
        return jsonify(planning_data), 200

    except RuntimeError as e:
        error_code = str(e)

        if "SERVICE_TEMPORAIREMENT_INDISPONIBLE" in error_code:
            return jsonify({
                "error": "SERVICE_TEMPORAIREMENT_INDISPONIBLE",
                "message": "Le service IA est actuellement très sollicité. Veuillez réessayer dans quelques minutes.",
                "retry_after": 300
            }), 503

        elif "ERREUR_SERVICE_IA" in error_code:
            print (error_code)
            return jsonify({
                "error": "ERREUR_SERVICE_IA",
                "message": "Erreur temporaire du service IA. Veuillez réessayer.",
                "details": error_code
            }), 501

        elif "REPONSE_IA_INVALIDE" in error_code:
            return jsonify({
                "error": "REPONSE_IA_INVALIDE",
                "message": "L'IA n'a pas pu générer un planning valide. Essayez de reformuler votre demande.",
                "details": error_code
            }), 502

        else:
            return jsonify({
                "error": "ERREUR_INATTENDUE",
                "message": "Une erreur inattendue s'est produite. Veuillez réessayer.",
                "details": error_code
            }), 500

    except Exception as e:
        return jsonify({
            "error": "ERREUR_INATTENDUE",
            "message": "Une erreur inattendue s'est produite. Veuillez réessayer.",
            "details": str(e)
        }), 500


