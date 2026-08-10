import hmac
import hashlib
import time
import requests
from datetime import datetime, timedelta
from flask import current_app
from app import db
from app.models.coach import Coach
from app.models.cinetpay import Payments, Subscription
from app.models.analytics_event import AnalyticsEvent


KPAY_BASE_URL = "https://admin.kpay.site/api/v1"


class KPayService:

    def _headers(self):
        """Headers d'authentification KPay — simple, pas de token à générer."""
        return {
            "X-API-Key":    current_app.config["KPAY_API_KEY_LIVE"],
            "X-Secret-Key": current_app.config["KPAY_SECRET_KEY_LIVE"],
        }

    # ─────────────────────────────────────────────
    # 1. INITIER UN PAIEMENT (mode GATEWAY)
    # ─────────────────────────────────────────────
    def initier_paiement(self, coach_id: int, montant: int):
        """
        Crée une session de paiement KPay et retourne le gatewayUrl.
        Le coach sera redirigé vers cette URL pour choisir Orange/MTN et payer.
        """
        coach = Coach.query.get(coach_id)
        if not coach:
            return {"success": False, "message": "Coach introuvable"}

        # Créer le paiement en DB avec status PENDING
        paiement = Payments(
            coach_id=coach_id,
            abonnement_id=None,
            amount=montant,
            currency="XAF",
            provider="KPAY",
            status="PENDING"
        )
        db.session.add(paiement)
        db.session.commit()

        # externalId = notre clé d'idempotence, max 30 caractères
        external_id = f"VP-{paiement.id}"

        try:
            payload = {
                "amount":      montant,
                "externalId":  external_id,
                "description": "Abonnement VolleyPlan de 1 an",
                #"customerName":  coach.nom,
                "customerEmail": coach.email,
                #"isTest": False,
                "returnUrl":   current_app.config["KPAY_RETURN_URL"],
                "cancelUrl":   current_app.config["KPAY_CANCEL_URL"],
            }

            response = requests.post(
                f"{KPAY_BASE_URL}/payments/init",
                headers=self._headers(),
                json=payload,
                timeout=30
            )
            data = response.json()
            #print("KPAY INIT RESPONSE:", data)

            if response.status_code == 201:
                # Stocker le kpay_id pour retrouver la transaction dans le webhook
                paiement.meta_data = {"kpay_id": data["id"], "reference": data["reference"]}
                db.session.commit()

                # --- Analytics : initiation de paiement ---
                try:
                    plan = next(
                        (p for m, p in [(25000, "BASIC"), (50000, "PREMIUM"), (125000, "PREMIUM_PLUS")]
                         if m == montant),
                        "UNKNOWN"
                    )
                    event = AnalyticsEvent(
                        user_id=coach_id,
                        event_name="payment_initiated",
                        event_data={
                            "amount": montant,
                            "currency": "XAF",
                            "plan": plan,
                            "external_id": external_id,
                            "provider": "KPAY",
                        },
                        session_id=None,
                    )
                    db.session.add(event)
                    db.session.commit()
                except Exception:
                    pass  # analytics non-bloquant
                # ------------------------------------------

                return {
                    "success":     True,
                    "gateway_url": data["gatewayUrl"],
                    "kpay_id":     data["id"],
                    "external_id": external_id
                }
            else:
                paiement.statut = "FAILED"
                db.session.commit()
                return {"success": False, "message": data.get("message", "Erreur KPay")}

        except Exception as e:
            paiement.statut = "FAILED"
            db.session.commit()
            return {"success": False, "message": str(e)}


    # ─────────────────────────────────────────────
    # 2. VÉRIFIER LA SIGNATURE DU RETOUR
    # ─────────────────────────────────────────────
    def verifier_signature_retour(self, query: dict) -> bool:
        """
        KPay signe la returnUrl avec HMAC-SHA256.
        On vérifie que la signature est valide ET que le timestamp
        a moins de 10 minutes (anti-replay).
        """
        gateway_secret = current_app.config["KPAY_GATEWAY_SECRET"]

        # Reconstruction de la chaîne signée
        s = f"{query.get('status', '')}|{query.get('reference', '')}|{query.get('externalId', '')}|{query.get('ts', '')}"
        expected = hmac.new(
            gateway_secret.encode(),
            s.encode(),
            hashlib.sha256
        ).hexdigest()

        # Vérifier la signature
        sig_ok = hmac.compare_digest(expected, query.get("sig", ""))

        # Vérifier que le timestamp a moins de 10 minutes (anti-replay)
        ts = int(query.get("ts", 0))
        ts_ok = (time.time() * 1000 - ts) < 10 * 60 * 1000

        return sig_ok and ts_ok


    # ─────────────────────────────────────────────
    # 3. VÉRIFIER LE STATUT RÉEL AUPRÈS DE KPAY
    # ─────────────────────────────────────────────
    def verifier_paiement(self, kpay_id: str) -> dict:
        """
        Source de vérité : on interroge KPay directement.
        Règle d'or : ne jamais faire confiance au returnUrl seul.
        """
        response = requests.get(
            f"{KPAY_BASE_URL}/payments/{kpay_id}",
            headers=self._headers(),
            timeout=30
        )
        return response.json()


    # ─────────────────────────────────────────────
    # 4. ACTIVER L'ABONNEMENT APRÈS PAIEMENT CONFIRMÉ
    # ─────────────────────────────────────────────
    def activer_abonnement(self, external_id: str, kpay_data: dict, montant: int):
        """
        Appelée après confirmation du statut COMPLETED côté KPay.
        Active le forfait PREMIUM du coach.
        """
        # Retrouver le paiement via external_id (format "VP-{id}")
        try:
            paiement_id = int(external_id.replace("VP-", ""))
        except:
            return {"success": False, "message": "externalId invalide"}

        paiement = Payments.query.filter_by(
            id=paiement_id,
            status="PENDING"
        ).first()

        if not paiement:
            return {"success": False, "message": "Transaction introuvable ou déjà traitée"}

        try:
            if montant==25000:
                # Créer l'abonnement
                abonnement = Subscription(
                    coach_id=paiement.coach_id,
                    plan="BASIC",
                    status="active",
                    payment_provider="KPAY",
                    transaction_id=kpay_data.get("reference"),
                    start_date=datetime.utcnow(),
                    end_date=datetime.utcnow() + timedelta(days=365)
                )
                db.session.add(abonnement)
                db.session.flush()

                # Mettre à jour le paiement
                paiement.status        = "SUCCESS"
                paiement.abonnement_id = abonnement.id
                paiement.meta_data     = kpay_data

                # Activer le coach
                coach = Coach.query.get(paiement.coach_id)
                coach.forfait        = "BASIC"
                coach.expire_forfait = abonnement.end_date

                db.session.commit()
            elif montant == 50000:
                # Créer l'abonnement
                abonnement = Subscription(
                    coach_id=paiement.coach_id,
                    plan="PREMIUM",
                    status="active",
                    payment_provider="KPAY",
                    transaction_id=kpay_data.get("reference"),
                    start_date=datetime.utcnow(),
                    end_date=datetime.utcnow() + timedelta(days=365)
                )
                db.session.add(abonnement)
                db.session.flush()

                # Mettre à jour le paiement
                paiement.status        = "SUCCESS"
                paiement.abonnement_id = abonnement.id
                paiement.meta_data     = kpay_data

                # Activer le coach
                coach = Coach.query.get(paiement.coach_id)
                coach.forfait        = "PREMIUM"
                coach.expire_forfait = abonnement.end_date

                db.session.commit()
            elif montant == 125000:
                # Créer l'abonnement
                abonnement = Subscription(
                    coach_id=paiement.coach_id,
                    plan="PREMIUM_PLUS",
                    status="active",
                    payment_provider="KPAY",
                    transaction_id=kpay_data.get("reference"),
                    start_date=datetime.utcnow(),
                    end_date=datetime.utcnow() + timedelta(days=365)
                )
                db.session.add(abonnement)
                db.session.flush()

                # Mettre à jour le paiement
                paiement.status        = "SUCCESS"
                paiement.abonnement_id = abonnement.id
                paiement.meta_data     = kpay_data

                # Activer le coach
                coach = Coach.query.get(paiement.coach_id)
                coach.forfait        = "PREMIUM_PLUS"
                coach.expire_forfait = abonnement.end_date

                db.session.commit()

            # --- Analytics : paiement réellement complété ---
            try:
                plan_map = {25000: "BASIC", 50000: "PREMIUM", 125000: "PREMIUM_PLUS"}
                event = AnalyticsEvent(
                    user_id=paiement.coach_id,
                    event_name="payment_completed",
                    event_data={
                        "amount": montant,
                        "currency": "XAF",
                        "plan": plan_map.get(montant, "UNKNOWN"),
                        "external_id": external_id,
                        "provider": "KPAY",
                        "reference": kpay_data.get("reference"),
                    },
                    session_id=None,
                )
                db.session.add(event)
                db.session.commit()
            except Exception:
                pass  # analytics non-bloquant
            # ------------------------------------------------

            return {"success": True, "message": "Abonnement activé"}

        except Exception as e:
            db.session.rollback()
            return {"success": False, "message": str(e)}



    # ─────────────────────────────────────────────
    # 5. TRAITER LE WEBHOOK
    # ─────────────────────────────────────────────
    def traiter_webhook(self, raw_body: bytes, signature_recue: str):
        """
        KPay envoie un POST avec le body brut signé en HMAC-SHA256.
        Règle d'or : vérifier la signature sur le RAW body avant tout traitement.
        """
        # 1. Vérifier la signature sur le body BRUT (pas le JSON re-sérialisé)
        webhook_secret = current_app.config["KPAY_WEBHOOK_SECRET"]
        expected = hmac.new(
            webhook_secret.encode(),
            raw_body,
            hashlib.sha256
        ).hexdigest()

        if not hmac.compare_digest(expected, signature_recue):
            return {"success": False, "message": "Signature webhook invalide"}, 400

        # 2. Parser le body
        import json
        event = json.loads(raw_body.decode("utf-8"))
        #print("KPAY WEBHOOK EVENT:", event)

        event_type  = event.get("event")
        external_id = event.get("externalId")
        payment_id  = event.get("paymentId")
        status      = event.get("status")

        # On ne traite que les paiements complétés
        if event_type != "payment.completed" or status != "COMPLETED":
            return {"success": False, "message": f"Event ignoré : {event_type} / {status}"}, 200

        # 3. Idempotence — déjà traité ?
        try:
            paiement_id = int(external_id.replace("VP-", ""))
            paiement = Payments.query.filter_by(id=paiement_id).first()
        except:
            return {"success": False, "message": "externalId invalide"}, 400

        if not paiement:
            return {"success": False, "message": "Transaction introuvable"}, 400

        if paiement.status == "SUCCESS":
            return {"success": True, "message": "Déjà traité (idempotence)"}, 200

        # 4. Vérifier le vrai statut auprès de KPay (règle d'or)
        kpay_data = self.verifier_paiement(payment_id)
        if kpay_data.get("status") != "COMPLETED":
            return {"success": False, "message": f"Statut non confirmé : {kpay_data.get('status')}"}, 200

        # 5. Activer l'abonnement
        resultat = self.activer_abonnement(external_id, kpay_data, paiement.amount)
        return resultat, 200