from ..models.invitation import Invitation
from ..models.planning_collaborator import PlanningCollaborator
from ..models.planning import Planning
from ..models.coach import Coach
from .. import db
from .email import EmailService
from datetime import datetime

class InvitationService:

    @staticmethod
    def create_invitation(planning_id, sender_coach_id, invited_email):
        # Vérifier si déjà invité ou collaborateur
        existing = Invitation.query.filter_by(planning_id=planning_id, invited_email=invited_email, status="pending").first()
        if existing:
            return None, "Une invitation est déjà en cours pour cet email."
        
        collab = PlanningCollaborator.query.filter_by(planning_id=planning_id, email=invited_email).first()
        if collab:
            return None, "Cet utilisateur est déjà collaborateur sur ce planning."

        invitation = Invitation(
            planning_id=planning_id,
            sender_coach_id=sender_coach_id,
            invited_email=invited_email
        )

        # On récupère les noms pour personnaliser l'email
        planning = db.session.get(Planning, planning_id)
        sender = db.session.get(Coach, sender_coach_id)
        
        # Envoi de l'email réel
        envoie = EmailService.send_invitation_email_brevo(invited_email, invitation.token, planning.titre, sender.nom)
        if envoie != True:
            return None, f"L'email n'a pas pu être envoyé ({envoie}). Vérifiez votre connexion."

        # On n'enregistre l'invitation QUE si l'email est bien parti
        db.session.add(invitation)
        db.session.commit()
        return invitation, None

    @staticmethod
    def validate_token(token):
        invitation = Invitation.query.filter_by(token=token).first()
        if not invitation:
            return None, "Invitation introuvable."
        if invitation.status != "pending":
            return None, "Cette invitation a déjà été traitée."
        if invitation.expiration_date < datetime.utcnow():
            invitation.status = "expired"
            db.session.commit()
            return None, "Cette invitation a expiré."
        return invitation, None

    @staticmethod
    def get_planning_by_token(token):
        invitation = Invitation.query.filter_by(token=token).first()
        if not invitation:
            return None, "Invitation introuvable."
        if invitation.status == "revoked":
            return None, "Cette invitation a été révoquée par le coach."
        if invitation.expiration_date < datetime.utcnow() and invitation.status == "pending":
            return None, "Cette invitation a expiré."
            
        planning = Planning.query.get(invitation.planning_id)
        return planning, None

    @staticmethod
    def accept_invitation(token, coach_id=None):
        invitation = Invitation.query.filter_by(token=token).first()
        if not invitation:
            return None, "Invitation introuvable."
        
        if invitation.status == "accepted":
            collab = PlanningCollaborator.query.filter_by(planning_id=invitation.planning_id, email=invitation.invited_email).first()
            return collab, None

        invitation.status = "accepted"
        collaborator = PlanningCollaborator(
            planning_id=invitation.planning_id,
            coach_id=coach_id,
            email=invitation.invited_email
        )
        db.session.add(collaborator)
        db.session.commit()
        return collaborator, None

    @staticmethod
    def remove_collaborator(planning_id, email, coach_id):
        planning = Planning.query.filter_by(id=planning_id, coach_id=coach_id).first()
        if not planning:
            return False, "Seul le coach principal peut retirer un membre du staff."
        
        # Supprimer des collaborateurs
        PlanningCollaborator.query.filter_by(planning_id=planning_id, email=email).delete()
        # Révoquer les invitations en attente pour cet email
        Invitation.query.filter_by(planning_id=planning_id, invited_email=email, status="pending").update({"status": "revoked"})
        
        db.session.commit()
        return True, None

    @staticmethod
    def claim_collaborations(coach_id, email):
        # On cherche les collaborations orphelines (coach_id est null) liées à cet email
        PlanningCollaborator.query.filter_by(email=email, coach_id=None).update({"coach_id": coach_id})
        db.session.commit()