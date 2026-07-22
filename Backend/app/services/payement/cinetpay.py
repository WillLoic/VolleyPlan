import hmac
import hashlib
import requests
from datetime import datetime, timedelta
from flask import current_app
from app import db
from app.models.cinetpay import Subscription, Payments
from app.models.coach import Coach



#CINETPAY_API_URL = "https://api-checkout.cinetpay.com/v2/payment" #version claude
CINETPAY_API_URL = "https://api.cinetpay.net" #version documentation

class CinetPayService:

    def _formater_telephone(self, telephone: str) -> str:
        """
        CinetPay exige le format international : +237XXXXXXXXX
        On nettoie et on ajoute le préfixe Cameroun si absent.
        """
        tel = telephone.strip().replace(" ", "").replace("-", "")
        if not tel.startswith("+"):
            tel = "+237" + tel.lstrip("0")
        return tel

    # ─────────────────────────────────────────────
    # 0. OBTENIR LE TOKEN D'AUTHENTIFICATION
    # ─────────────────────────────────────────────

    def _get_token(self):
        """
        La nouvelle API Aurore nécessite un token Bearer.
        On l'obtient en envoyant account_key + account_password.
        """
        response = requests.post(
            f"{CINETPAY_API_URL}/v1/oauth/login",  
            json={
                "api_key":      current_app.config["CINETPAY_API_KEY"],
                "api_password": current_app.config["CINETPAY_ACCOUNT_PASSWORD"]
            },
            timeout=60
        ) 
        data = response.json()
        if data.get("code") == 200:
            return data["access_token"]
        raise Exception(f"Impossible d'obtenir le token CinetPay : {data}")

    # ─────────────────────────────────────────────
    # 1. INITIER UN PAIEMENT 
    # ─────────────────────────────────────────────
    def initier_paiement(self, coach_id: int, montant: int, currency: str = "XAF"):
        """
        Crée une transaction CinetPay et retourne l'URL de paiement.
        C'est cette URL qu'on envoie au frontend pour rediriger le coach.
        """
        coach = Coach.query.get(coach_id)
        if not coach:
            return {"success": False, "message": "Coach introuvable"}

        # On crée d'abord un paiement en DB avec status PENDING
        # Comme ça si le webhook n'arrive jamais, on sait qu'il y a eu une tentative
        paiement = Payments(
            coach_id=coach_id,
            abonnement_id=None,  # sera rempli dans le webhook
            amount=montant,
            currency=currency,
            provider="CINETPAY",
            status="PENDING"
        )
        db.session.add(paiement)
        db.session.commit()

        # Séparer le nom en prénom + nom
        # Si le coach a un seul mot dans nom, on met le même des deux côtés
        nom_parts = coach.nom.strip().split(" ", 1)
        client_first_name = nom_parts[0]
        client_last_name  = nom_parts[1] if len(nom_parts) > 1 else nom_parts[0]

        # merchant_transaction_id limité à 30 caractères
        merchant_tx_id = f"VP-{paiement.id}"[:30]


        try:
            # Payload envoyé à CinetPay
            token = self._get_token()
            payload = {
                "merchant_transaction_id": merchant_tx_id,
                "amount": montant,
                "lang": "fr",
                "currency": currency,
                "designation": "Abonnement VolleyPlan Premium - 1 an",
                "notify_url": current_app.config["CINETPAY_WEBHOOK_URL"],  # ton URL webhook
                "success_url": current_app.config["CINETPAY_SUCCES_URL"],   # où rediriger après paiement reussi
                "failed_url": current_app.config["CINETPAY_FAILED_URL"],   # où rediriger après paiement echoue
                #"customer_id": str(coach_id),
                "client_email":           coach.email,
                "client_phone_number": self._formater_telephone(coach.telephone),
                "client_first_name":      client_first_name,
                "client_last_name":       client_last_name,
                "direct_pay": False
                
            }
            

        
            response = requests.post(f"{CINETPAY_API_URL}/v1/payment", json=payload,headers={"Authorization": f"Bearer {token}"}, timeout=60)
            data = response.json()
            #print("Donnee envoyer apres requete de paiement")
            #print(data)

            if data.get("code") == 200 :
                details = data.get("details", {})
    
                # INITIATED ou PENDING = succès, on retourne le payment_url
                if details.get("status") in ["INITIATED", "PENDING"]:
                    # 👇 on sauvegarde le notify_token reçu
                    paiement.notify_token =  data.get("notify_token")
                    db.session.commit()
                    return {
                        "success": True,
                        "payment_url": data["payment_url"],
                        "transaction_id": merchant_tx_id
                    }
            else:
                # CinetPay a refusé, on marque le paiement FAILED
                # Paiement échoué malgré code 200 (ex: mauvais numéro)
                details = data.get("details", {})
                paiement.status = "FAILED"
                db.session.commit()
                errors = details.get("errors", {})
                message = details.get("message", "Erreur inconnue")
                return {"success": False, "message": message, "errors": errors}

        except requests.exceptions.Timeout:
            paiement.status = "FAILED"
            db.session.commit()
            return {"success": False, "message": "CinetPay ne répond pas (timeout)"}

        except Exception as e:
            paiement.status = "FAILED"
            db.session.commit()
            return {"success": False, "message": str(e)}






    def verifier_transaction(self, merchant_transaction_id: str):
        """
        Interroge directement l'API CinetPay pour connaître le VRAI statut
        d'une transaction. C'est la seule source de vérité.
        """
        token = self._get_token()
        response = requests.get(
            f"{CINETPAY_API_URL}/v1/payment/{merchant_transaction_id}",
            headers={"Authorization": f"Bearer {token}"},
            timeout=30
        )
        return response.json()



    # ─────────────────────────────────────────────
    # 2. TRAITER LE WEBHOOK
    # ─────────────────────────────────────────────
    
    def traiter_webhook(self, data: dict):
        """
        Le webhook ne sert que de "signal". On ne fait jamais confiance
        à son contenu — on revérifie systématiquement auprès de CinetPay.
        """
        merchant_tx_id = data.get("merchant_transaction_id")
        notify_token    = data.get("notify_token")

        if not merchant_tx_id:
            return {"success": False, "message": "merchant_transaction_id manquant"}

        # Retrouver le paiement en DB
        try:
            paiement_id = int(merchant_tx_id.replace("VP-", ""))
        except:
            return {"success": False, "message": "merchant_transaction_id invalide"}

        paiement = Payments.query.filter_by(id=paiement_id).first()
        if not paiement:
            return {"success": False, "message": "Transaction introuvable"}

        # ── Idempotence : si déjà traité, on ignore mais on répond 200 ──
        if paiement.status == "SUCCESS":
            return {"success": True, "message": "Déjà traité (idempotence)"}

        # ── Vérifier le notify_token (anti-usurpation) ──
        # On l'a stocké dans meta_data lors de l'initiation du paiement
        #expected_token = (paiement.meta_data or {}).get("notify_token")
        expected_token = paiement.notify_token 
        if expected_token and notify_token != expected_token:
            return {"success": False, "message": "notify_token invalide — possible usurpation"}

        # ── ÉTAPE CRITIQUE : revérifier le statut RÉEL auprès de CinetPay ──
        try:
            verif = self.verifier_transaction(merchant_tx_id)
        except Exception as e:
            return {"success": False, "message": f"Erreur vérification CinetPay : {str(e)}"}

        statut_reel = verif.get("data", {}).get("status") or verif.get("status")

        if statut_reel != "SUCCESS":
            paiement.status = "FAILED" if statut_reel == "FAILED" else "PENDING"
            db.session.commit()
            return {"success": False, "message": f"Statut réel non confirmé : {statut_reel}"}

        # ── Le paiement est VRAIMENT confirmé par CinetPay lui-même ──
        try:
            abonnement = Subscription(
                coach_id=paiement.coach_id,
                plan="PREMIUM",
                status="active",
                payment_provider="CINETPAY",
                transaction_id=data.get("transaction_id"),
                start_date=datetime.utcnow(),
                end_date=datetime.utcnow() + timedelta(days=365)
            )
            db.session.add(abonnement)
            db.session.flush()

            paiement.status        = "SUCCESS"
            paiement.abonnement_id = abonnement.id
            paiement.meta_data     = {**(paiement.meta_data or {}), "webhook": data, "verification": verif}

            coach = Coach.query.get(paiement.coach_id)
            coach.forfait        = "PREMIUM"
            coach.expire_forfait = abonnement.end_date

            db.session.commit()
            return {"success": True, "message": "Abonnement activé"}

        except Exception as e:
            db.session.rollback()
            return {"success": False, "message": str(e)}


    
    """def traiter_webhook(self, data: dict):
        
        CinetPay envoie une notification quand le paiement est SUCCESS ou FAILED.
        Le statut est dans data["status"] avec la nouvelle API.
        
        code            = data.get("code")
        merchant_tx_id    = data.get("merchant_transaction_id")

        if code != 100:
            return {"success": False, "message": f"Paiement non confirmé : {code}"}

        # Retrouver le paiement via merchant_transaction_id (format "VP-{id}")
        try:
            paiement_id = int(merchant_tx_id.replace("VP-", ""))
        except:
            return {"success": False, "message": "merchant_transaction_id invalide"}

        paiement = Payments.query.filter_by(
            id=paiement_id,
            status="PENDING"
        ).first()

        if not paiement:
            return {"success": False, "message": "Transaction introuvable ou déjà traitée"}

        try:
            # Créer l'abonnement
            abonnement = Subscription(
                coach_id=paiement.coach_id,
                plan="PREMIUM",
                status="active",
                payment_provider="CINETPAY",
                transaction_id=merchant_tx_id,
                start_date=datetime.utcnow(),
                end_date=datetime.utcnow() + timedelta(days=365)
            )
            db.session.add(abonnement)
            db.session.flush()

            # Mettre à jour le paiement
            paiement.status        = "SUCCESS"
            paiement.abonnement_id = abonnement.id
            paiement.meta_data     = data

            # Activer le coach
            coach = Coach.query.get(paiement.coach_id)
            coach.forfait        = "PREMIUM"
            coach.expire_forfait = abonnement.end_date

            db.session.commit()
            return {"success": True, "message": "Abonnement activé"}

        except Exception as e:
            db.session.rollback()
            return {"success": False, "message": str(e)}"""