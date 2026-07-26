from flask import Flask, current_app, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_mail import Mail
from .config import config
from dotenv import load_dotenv
import os

# Chargement des variables d'environnement (.env)
load_dotenv()

db      = SQLAlchemy()
migrate = Migrate()
jwt     = JWTManager()
mail    = Mail()

def create_app():
    from .models import coach,exercices,joueurs,planning,seances,invitation,planning_collaborator,notification,feedbacks,cinetpay,presences, partage_planning, rapport_mensuel, action_jeu ,action_jeu_json
    app = Flask(__name__)
    env = os.getenv("FLASK_ENV", "development")
    app.config.from_object(config[env])

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    
    # Configuration SMTP pour l'envoi de mails
    app.config['MAIL_SERVER'] = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    app.config['MAIL_PORT'] = int(os.getenv('MAIL_PORT', 587))
    app.config['MAIL_USE_TLS'] = os.getenv('MAIL_USE_TLS', 'True').lower() == 'true'
    app.config['MAIL_USERNAME'] = os.getenv('MAIL_USERNAME')  # Ton adresse email
    app.config['MAIL_PASSWORD'] = os.getenv('MAIL_PASSWORD')
    app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_DEFAULT_SENDER', 'willloic36@gmail.com')

    mail.init_app(app)

    CORS(app, origins="*", supports_credentials=True)
    # On ne fait plus de create_all() manuel ici car on utilise Flask-Migrate
    coach.app_context(app)
    exercices.app_context(app)
    joueurs.app_context(app)
    planning.app_context(app)
    seances.app_context(app)
    invitation.app_context(app)
    planning_collaborator.app_context(app)
    notification.app_context(app)
    feedbacks.app_context(app)
    cinetpay.app_context(app)
    presences.app_context(app)
    partage_planning.app_context(app)
    rapport_mensuel.app_context(app)
    action_jeu.app_context(app)
    action_jeu_json.app_context(app)




    # Enregistrement des blueprints
    from .controllers.auth import auth_bp
    from .controllers.joueurs import joueur_bp
    from .controllers.planning import planning_bp
    from .controllers.seances import seance_bp
    from .controllers.bilan import bilan_bp
    from .controllers.pdf import pdf_bp
    from .controllers.invitation import invitation_bp
    from .controllers.notifications import notification_bp
    from .controllers.feedbacks import feedbacks_bp
    from .controllers.coach import coach_bp
    from .controllers.analytics import analytics_bp
    from .controllers.cinetpay import cinetpay_bp
    from .controllers.stats_joueurs import stats_bp
    from .controllers.partage_planning import public_bp
    from .controllers.rapport_mensuel import rapport_bp
    from .controllers.action_jeu import action_jeu_bp
    from .controllers.ai import ai_bp
    from .controllers.kpay import kpay_bp
    


    app.register_blueprint(auth_bp,     url_prefix="/api/auth")
    app.register_blueprint(joueur_bp,   url_prefix="/api/joueurs")
    app.register_blueprint(planning_bp, url_prefix="/api/plannings")
    app.register_blueprint(seance_bp,   url_prefix="/api/seances")
    app.register_blueprint(bilan_bp,    url_prefix="/api/bilan")
    app.register_blueprint(pdf_bp,      url_prefix="/api/pdf")
    app.register_blueprint(invitation_bp,      url_prefix="/api/invitations")
    app.register_blueprint(notification_bp,      url_prefix="/api/notifications")
    app.register_blueprint(feedbacks_bp,      url_prefix="/api/feedbacks")
    app.register_blueprint(coach_bp,          url_prefix="/api/coach")
    app.register_blueprint(analytics_bp,      url_prefix="/api/admin")
    app.register_blueprint(cinetpay_bp,      url_prefix="/api/cinetpay")
    app.register_blueprint(stats_bp,         url_prefix="/api/stats")
    app.register_blueprint(public_bp, url_prefix="/api/public")
    app.register_blueprint(rapport_bp, url_prefix="/api/plannings")
    app.register_blueprint(action_jeu_bp, url_prefix="/api/actions")
    app.register_blueprint(ai_bp,          url_prefix="/api/ai")
    app.register_blueprint(kpay_bp, url_prefix="/api/kpay")

    @app.route("/api/health")
    def health():
        return {"status": "ok", "app": "VolleyPlan API"}
        
    from .scheduler import init_scheduler
    init_scheduler(app)
    
    return app