from flask import Blueprint, jsonify
from app.services.partage_planning import PartagePublicService

public_bp = Blueprint("public", __name__)


@public_bp.route("/planning/<token>", methods=["GET"])
def get_planning_public(token):
    planning, partage, error = PartagePublicService.get_planning_public(token)

    if error and not partage:
        return jsonify({"success": False, "message": error}), 404

    if error:  # lien trouvé mais expiré
        return jsonify({"success": False, "message": error}), 410

    data = planning.to_dict(include_seances=True)
    # On retire tout ce qui n'a rien à faire dans une vue publique
    data.pop("collaborators", None)
    data.pop("invitations", None)
    data.pop("coach_id", None)

    return jsonify({
        "success": True,
        "planning": data,
        "expires_at": partage.expires_at.isoformat(),
    }), 200