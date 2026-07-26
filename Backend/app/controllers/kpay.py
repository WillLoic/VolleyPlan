from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.payement.kpay import KPayService

kpay_bp = Blueprint("kpay", __name__)
service = KPayService()


@kpay_bp.route("/initier", methods=["POST"])
@jwt_required()
def initier_paiement():
    body     = request.get_json()
    coach_id = get_jwt_identity()
    montant  = body.get("montant", 65000)  # 100€ ≈ 65 000 XAF

    if not coach_id:
        return jsonify({"success": False, "message": "coach_id manquant"}), 400

    resultat = service.initier_paiement(coach_id, montant)

    if not resultat:
        return jsonify({"success": False, "message": "Erreur interne"}), 500

    return jsonify(resultat), 200 if resultat["success"] else 500


@kpay_bp.route("/retour", methods=["GET"])
def retour_paiement():
    """
    KPay redirige le client vers cette URL après paiement.
    On vérifie la signature, puis on confirme le statut via l'API.
    """
    query = request.args.to_dict()

    # 1. Vérifier la signature HMAC
    if not service.verifier_signature_retour(query):
        return jsonify({"success": False, "message": "Signature invalide"}), 403

    status      = query.get("status")
    external_id = query.get("externalId")
    reference   = query.get("reference")

    if status != "COMPLETED":
        return jsonify({"success": False, "message": f"Paiement non complété : {status}"}), 200

    # 2. Récupérer le kpay_id depuis la DB via external_id
    try:
        paiement_id = int(external_id.replace("VP-", ""))
        from app.models import Payments
        paiement = Payments.query.get(paiement_id)
        kpay_id  = paiement.meta_data.get("kpay_id") if paiement else None
    except:
        return jsonify({"success": False, "message": "Transaction introuvable"}), 400

    # 3. Vérifier le vrai statut auprès de KPay (règle d'or)
    kpay_data = service.verifier_paiement(kpay_id)
    if kpay_data.get("status") != "COMPLETED":
        return jsonify({"success": False, "message": "Statut non confirmé par KPay"}), 200

    # 4. Activer l'abonnement
    resultat = service.activer_abonnement(external_id, kpay_data)
    return jsonify(resultat), 200

@kpay_bp.route("/webhook", methods=["POST"])
def webhook():
    """
    KPay appelle cette URL à chaque changement de statut.
    IMPORTANT : on lit le raw body pour la vérification HMAC.
    """
    raw_body  = request.get_data()  # ← body brut, pas request.get_json()
    signature = request.headers.get("X-KPAY-Signature", "")

    resultat, status_code = service.traiter_webhook(raw_body, signature)

    # KPay attend toujours un 200 rapide
    return jsonify(resultat), status_code