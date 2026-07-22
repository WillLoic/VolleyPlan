from flask import Blueprint, request, jsonify
from app.services.payement.cinetpay import CinetPayService
from flask_jwt_extended import jwt_required, get_jwt_identity

cinetpay_bp = Blueprint("cinetpay", __name__)

service = CinetPayService()


@cinetpay_bp.route("/initier", methods=["POST"])
@jwt_required()
def initier_paiement():
    # Recupere l'identifiant du coach connecté
    coach_id = get_jwt_identity()
    
    """
    Le frontend appelle cette route avec le coach_id et le montant.
    On retourne l'URL de paiement CinetPay à ouvrir dans le navigateur.
    """
    body = request.get_json()

    #coach_id = body.get("coach_id")
    montant  = body.get("montant", 65000)   # 100€ ≈ 65 000 XAF
    currency = body.get("currency", "XAF")

    if not coach_id:
        return jsonify({"success": False, "message": "coach_id manquant"}), 400

    resultat = service.initier_paiement(coach_id, montant, currency)

    if not resultat:
        return jsonify({"succes":False,"message":"Erreur interne innatendu"}), 500
    

    if resultat["success"]:
        return jsonify(resultat), 200
    else:
        return jsonify(resultat), 500


@cinetpay_bp.route("/webhook", methods=["POST","GET"])
def webhook():
    if request.method == "GET":
        # Sonde de santé CinetPay
        return "", 200
    """
    CinetPay appelle cette route automatiquement après chaque paiement.
    On ne contrôle pas qui appelle ça — CinetPay le fait tout seul.
    """
    data = request.get_json() or request.form.to_dict()
    # CinetPay peut envoyer du JSON ou du form-data selon la config
    print("webhook recu:")
    print(data)
    resultat = service.traiter_webhook(data)
    print("resultat traitement")
    print(resultat) 
    # CinetPay attend toujours un 200, même si c'est une erreur de notre côté
    # Si on retourne autre chose, il va retry en boucle
    return jsonify(resultat), 200