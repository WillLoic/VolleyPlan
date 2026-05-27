from ..models.coach import Coach
from .. import db
from .email import EmailService
from flask_jwt_extended import create_access_token, decode_token
from datetime import timedelta

class PasswordReset:

    @staticmethod
    def request_reset(email):
        print(f"Demande de reset reçue pour : {email}")
        print(f"Recherche du coach avec l'email : {email}")
        coach = Coach.query.filter_by(email=email).first()
        if not coach:
            # Pour la sécurité, on ne dit pas si l'email existe ou pas
            return True, "Si votre adresse est connue, vous recevrez un email sous peu."

        # On génère un token de 1 heure
        reset_token = create_access_token(
            identity=str(coach.id), 
            expires_delta=timedelta(hours=1),
            additional_claims={"purpose": "password_reset"}
        )

        print(f"Coach trouvé : {coach.email}. Tentative d'envoi de l'email de réinitialisation.")
        success = EmailService.send_reset_email(email, reset_token)
        if not success:
            print("L'envoi de l'email a échoué dans EmailService")
            return False, "Erreur lors de l'envoi de l'email (Brevo)."
        else:
            print("EmailService a indiqué un succès pour l'envoi.")
        return True, "Email de réinitialisation envoyé."

    @staticmethod
    def reset_password(token, new_password):
        try:
            decoded = decode_token(token)
            if decoded.get("purpose") != "password_reset":
                return False, "Token invalide pour cette action."
            
            coach = Coach.query.get(int(decoded['sub']))
            coach.set_password(new_password)
            db.session.commit()
            return True, None
        except Exception:
            return False, "Lien invalide ou expiré."