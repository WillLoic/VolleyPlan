from flask_mail import Message
from app import mail
import os
import requests
import base64

# Force le chargement pour le debug si ce n'est pas fait globalement
from dotenv import load_dotenv
load_dotenv()

class EmailService:
    @staticmethod
    def send_invitation_email(email, token, planning_title, sender_name):
        # URL de ton frontend (ex: http://localhost:5000 sur le web-server)
        frontend_url = os.getenv("FRONTEND_URL", "http://localhost:64426").strip()
        invite_link = f"{frontend_url}/#/invite/{token}"
        
        subject = f"Invitation VolleyPlan : Collaboration sur {planning_title}"
        
        body = f"""
        Bonjour,
        
        Le coach {sender_name} vous invite à collaborer sur le planning '{planning_title}' via VolleyPlan.
        
        En tant que collaborateur, vous pourrez consulter et modifier les séances de ce planning.
        
        Cliquez sur le lien ci-dessous pour accepter l'invitation (lien valide 3 jours) :
        {invite_link}
        
        L'équipe VolleyPlan.
        """
        
        msg = Message(subject, recipients=[email], body=body)
        try:
            mail.send(msg)
            return True
        except Exception as e:
            print(f"Erreur SMTP : {e}")
            return False


    #methode avec brevo
    @staticmethod
    def send_invitation_email_brevo(email,token,planning_title, sender_name):
        frontend_url = os.getenv("FRONTEND_URL", "http://localhost:64426").strip()
        invite_link = f"{frontend_url}/#/invite/{token}"

        #configuration brevo
        api_key = os.getenv("BREVO_API_KEY")
        if not api_key:
            print("❌ ERREUR : La clé BREVO_API_KEY est manquante !")
            return False

        sender_email = os.getenv("SENDER_EMAIL", "willloic36@gmail.com")
        sender_vp_name = os.getenv("SENDER_NAME", "VolleyPlan")
        url = "https://api.brevo.com/v3/smtp/email" # URL corrigée

        payload = {
            "sender": {"name": sender_vp_name, "email": sender_email},
            "to": [{"email": email}],
            "subject": f"Invitation VolleyPlan : Collaboration sur {planning_title}",
            "htmlContent": f"""
                <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                    <h3>Invitation à collaborer sur VolleyPlan</h3>
                    <p>Bonjour,</p>
                    <p>Le coach {sender_name} vous invite à collaborer sur le planning '{planning_title}' via VolleyPlan.
        
        En tant que collaborateur, vous pourrez consulter et modifier les séances de ce planning.
        
        Cliquez sur le lien ci-dessous pour accepter l'invitation (lien valide 3 jours) : </p>
                    <p><a href='{invite_link}' style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Accepter l'invitation</a></p>
                    
                    <p>L'équipe VolleyPlan</p>
                </div>
            """
        }

        headers = {
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json"
        }

        # 3. Envoi de la requête
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            
            if response.status_code in [201, 200]:
                print(f"✅ EMAIL ENVOYÉ VIA API (Brevo) à {email}")
                return True
            else:
                # Très important pour débugger sur Render si la clé est mauvaise
                print(f"❌ ERREUR API BREVO : {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ ERREUR RÉSEAU API : {str(e)}")
            return False
        

    @staticmethod
    def send_reset_email(email, reset_token):
        """Envoie un email de réinitialisation de mot de passe via Brevo API"""
        
        print(f"--- Tentative d'envoi d'email de reset à {email} ---")
        
        # 1. Préparation de l'URL de reset
        base_url = os.getenv('FRONTEND_URL', 'http://localhost:60867').strip()
        reset_url = f"{base_url}/#/reset-password?token={reset_token}"
    
        # 2. Configuration API
        api_key = os.getenv("BREVO_API_KEY")
        if not api_key:
            print("❌ ERREUR : La clé BREVO_API_KEY est absente du .env !")
            return False
        #print(api_key)
            
        sender_email = os.getenv("SENDER_EMAIL", "willloic36@gmail.com")
        sender_vp_name = os.getenv("SENDER_NAME", "VolleyPlan")
        url = "https://api.brevo.com/v3/smtp/email" # URL corrigée
        
        payload = {
            "sender": {"name": sender_vp_name, "email": sender_email},
            "to": [{"email": email}],
            "subject": "Réinitialisation de mot de passe - VolleyPlan",
            "htmlContent": f"""
                <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                    <h3>Réinitialisation de votre mot de passe</h3>
                    <p>Bonjour,</p>
                    <p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe :</p>
                    <p><a href='{reset_url}' style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Réinitialiser mon mot de passe</a></p>
                    <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
                    <p>L'équipe VolleyPlan</p>
                </div>
            """
        }
        
        headers = {
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json"
        }
    
        # 3. Envoi de la requête
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            
            if response.status_code in [201, 200]:
                print(f"✅ EMAIL ENVOYÉ VIA API (Brevo) à {email}")
                return True
            else:
                # Très important pour débugger sur Render si la clé est mauvaise
                print(f"❌ ERREUR API BREVO : {response.status_code} - {response.text}")
                return False

        except Exception as e:
            print(f"❌ ERREUR RÉSEAU API : {str(e)}")
            return False
        
    @staticmethod
    def send_rapport_mensuel_email_brevo(email, planning_title, rapport_data, pdf_bytes):
        api_key = os.getenv("BREVO_API_KEY")
        if not api_key:
            print("❌ ERREUR : La clé BREVO_API_KEY est manquante !")
            return False

        sender_email = os.getenv("SENDER_EMAIL", "willloic36@gmail.com")
        sender_vp_name = os.getenv("SENDER_NAME", "VolleyPlan")
        url = "https://api.brevo.com/v3/smtp/email"

        resume = rapport_data["resume"]
        pdf_b64 = base64.b64encode(pdf_bytes).decode("utf-8")

        payload = {
            "sender": {"name": sender_vp_name, "email": sender_email},
            "to": [{"email": email}],
            "subject": f"Votre rapport mensuel VolleyPlan — {planning_title}",
            "htmlContent": f"""
                <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                    <h3>Rapport mensuel — {planning_title}</h3>
                    <p>Bonjour,</p>
                    <p>Voici le bilan de votre préparation :</p>
                    <ul>
                        <li>{resume['nb_seances_effectuees']} séances effectuées sur {resume['nb_seances_prevues']} prévues</li>
                        <li>Taux de réalisation : {resume['taux_realisation']}%</li>
                        <li>Taux de présence moyen : {rapport_data['taux_presence_moyen_equipe']}%</li>
                    </ul>
                    <p>Le rapport complet est en pièce jointe.</p>
                    <p>L'équipe VolleyPlan</p>
                </div>
            """,
            "attachment": [{
                "content": pdf_b64,
                "name": f"rapport_mensuel_{planning_title}.pdf",
            }],
        }

        headers = {
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json",
        }

        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            if response.status_code in [201, 200]:
                print(f"✅ RAPPORT MENSUEL ENVOYÉ à {email}")
                return True
            else:
                print(f"❌ ERREUR API BREVO : {response.status_code} - {response.text}")
                return False
        except Exception as e:
            print(f"❌ ERREUR RÉSEAU API : {str(e)}")
            return False