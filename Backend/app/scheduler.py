import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

def check_attendance_reminders(app):
    from app import db
    from app.models.seances import Seance
    from app.models.notification import Notification

    with app.app_context():
        now = datetime.utcnow()
        # Rechercher toutes les séances sans présence prise et avec une date planifiée
        seances = Seance.query.filter(Seance.presences_prises == False, Seance.date_seance.isnot(None)).all()
        for seance in seances:
            try:
                h_debut = datetime.strptime(seance.heure_debut or "00:00", "%H:%M").time()
            except Exception:
                from datetime import time
                h_debut = time(0, 0)
            seance_datetime = datetime.combine(seance.date_seance, h_debut)
            
            reminder_time = seance_datetime + timedelta(hours=10)
            # S'assurer que le rappel s'envoie 10h après le début de la séance
            if reminder_time <= now:
                # Vérifier si une notification de rappel existe déjà pour cette séance
                notif_exists = Notification.query.filter_by(seance_id=seance.id, type="presence_rappel").first()
                if not notif_exists:
                    coach_id = seance.planning.coach_id
                    msg = f"N'oubliez pas d'enregistrer les absences pour votre séance '{seance.titre}'."
                    notif = Notification(
                        coach_id=coach_id,
                        message=msg,
                        type="presence_rappel",
                        seance_id=seance.id
                    )
                    db.session.add(notif)
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            logger.error(f"Erreur check_attendance_reminders: {str(e)}")

def check_attendance_autolocks(app):
    from app import db
    from app.models.seances import Seance

    with app.app_context():
        now = datetime.utcnow()
        seances = Seance.query.filter(Seance.presences_prises == False, Seance.date_seance.isnot(None)).all()
        for seance in seances:
            try:
                h_debut = datetime.strptime(seance.heure_debut or "00:00", "%H:%M").time()
            except Exception:
                from datetime import time
                h_debut = time(0, 0)
            seance_datetime = datetime.combine(seance.date_seance, h_debut)
            
            # Verrouiller automatiquement 34 heures après le début
            lock_time = seance_datetime + timedelta(hours=34)
            if lock_time <= now:
                seance.presences_prises = True
                seance.presences_auto = True
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            logger.error(f"Erreur check_attendance_autolocks: {str(e)}")

def check_rapports_mensuels(app):
    from app import db
    from datetime import date
    from app.models.planning import Planning
    from app.models.notification import Notification
    from app.models.coach import Coach
    from app.services.rapport_mensuel import generer_rapport_si_eligible
    from app.services.pdf import generer_pdf_rapport_mensuel
    from app.services.email import EmailService

    with app.app_context():
        # On ne fait le travail lourd que le 1er du mois
        if date.today().day != 1:
            return

        plannings = Planning.query.all()
        for planning in plannings:
            try:
                rapport, est_nouveau = generer_rapport_si_eligible(planning.id)
                if not est_nouveau or rapport is None:
                    continue

                # Notification in-app
                notif = Notification(
                    coach_id=planning.coach_id,
                    message=f"Votre rapport mensuel pour '{planning.titre}' est disponible.",
                    type="rapport_mensuel",
                    planning_id=planning.id,
                )
                db.session.add(notif)
                db.session.commit()

                # Email avec PDF en pièce jointe
                coach = Coach.query.get(planning.coach_id)
                if coach and coach.email:
                    pdf_bytes = generer_pdf_rapport_mensuel(rapport.donnees, planning)
                    EmailService.send_rapport_mensuel_email_brevo(
                        coach.email, planning.titre, rapport.donnees, pdf_bytes
                    )
            except Exception as e:
                db.session.rollback()
                logger.error(f"Erreur check_rapports_mensuels pour planning {planning.id}: {str(e)}")

def init_scheduler(app):
    try:
        from flask_apscheduler import APScheduler
        scheduler = APScheduler()
        app.config['SCHEDULER_API_ENABLED'] = True
        scheduler.init_app(app)
        scheduler.start()

        # Enregistrement des jobs
        scheduler.add_job(
            id='attendance_reminders_job',
            func=check_attendance_reminders,
            args=[app],
            trigger='interval',
            minutes=30
        )
        scheduler.add_job(
            id='attendance_autolocks_job',
            func=check_attendance_autolocks,
            args=[app],
            trigger='interval',
            minutes=30
        )
        scheduler.add_job(
            id='rapports_mensuels_job',
            func=check_rapports_mensuels,
            args=[app],
            trigger='interval',
            hours=6
        )
        logger.info("Scheduler APScheduler initialisé avec succès.")
    except ImportError:
        logger.warning("Le package 'flask-apscheduler' n'est pas installé. Les tâches de présence en arrière-plan ne tourneront pas.")


