import io
from flask import Blueprint, send_file, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.pdf import generate_planning_pdf
from app.services.planning import PlanningService
from app.services.bilan import BilanService
from app.utils.decorators import basic_required

pdf_bp = Blueprint("pdf", __name__)


@pdf_bp.route("/planning/<int:planning_id>", methods=["GET"])
@jwt_required()
#@basic_required()
def export_pdf(planning_id):
    coach_id = int(get_jwt_identity())

    planning, p_err = PlanningService.get_by_id(planning_id, coach_id)
    if p_err:
        return jsonify({"error": p_err}), 404

    bilan, b_err = BilanService.compute(coach_id, planning_id)
    if b_err:
        return jsonify({"error": b_err}), 404

    buffer = generate_planning_pdf(planning, bilan)

    return send_file(
        io.BytesIO(buffer),
        mimetype="application/pdf",
        as_attachment=True,
        download_name=f"planning_{planning_id}.pdf",
    )