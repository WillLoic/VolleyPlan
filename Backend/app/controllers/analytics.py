from flask import Blueprint, request, jsonify
from app.models.analytics_event import AnalyticsEvent
from app.models.coach import Coach
from app.models.planning import Planning
from app.models.joueurs import Joueur
from app.models.feedbacks import Feedbacks
from app.models.seances import Seance
from app.models.exercices import Exercice
from app.models.invitation import Invitation
from app.models.planning_collaborator import PlanningCollaborator
from app import db
import jwt
from flask import current_app
from functools import wraps
from sqlalchemy import func
from datetime import datetime, timedelta
from flask_jwt_extended import jwt_required, get_jwt_identity

analytics_bp = Blueprint('analytics', __name__)

def admin_required(f):
    @wraps(f)
    @jwt_required()
    def decorated(*args, **kwargs):
        coach_id = get_jwt_identity()
        coach = db.session.get(Coach, coach_id)
        if not coach or coach.role != 'admin':
            return jsonify({'message': 'Accès refusé : Admin requis'}), 403
        return f(coach, *args, **kwargs)
    return decorated

@analytics_bp.route('/analytics/event', methods=['POST'])
@jwt_required(optional=True)
def track_event():
    data = request.get_json()
    if not data:
        return jsonify({"message": "Données manquantes"}), 400

    # On s'assure que user_id est un entier si présent
    raw_user_id = get_jwt_identity()
    user_id = int(raw_user_id) if raw_user_id else None

    new_event = AnalyticsEvent(
        user_id=user_id,
        event_name=data.get('event_name'),
        event_data=data.get('event_data'), # Sera None si non envoyé par le front
        session_id=data.get('session_id')
    )

    db.session.add(new_event)
    db.session.commit()

    return jsonify({"message": "Événement enregistré"}), 201

@analytics_bp.route('/stats/summary', methods=['GET'])
@admin_required
def get_admin_summary(current_admin):
    now = datetime.utcnow()
    
    # 1. Volumes globaux
    total_coaches = Coach.query.count()
    total_plannings = Planning.query.count()
    total_joueurs = Joueur.query.count()
    total_feedbacks = Feedbacks.query.count()

    # 2. Utilisateurs Actifs (Analytics)
    last_24h = now - timedelta(hours=24)
    last_30d = now - timedelta(days=30)
    
    dau = db.session.query(func.count(func.distinct(AnalyticsEvent.user_id)))\
        .filter(AnalyticsEvent.timestamp >= last_24h).scalar() or 0
    mau = db.session.query(func.count(func.distinct(AnalyticsEvent.user_id)))\
        .filter(AnalyticsEvent.timestamp >= last_30d).scalar() or 0

    # 3. Analyse de la profondeur (Complexité des plannings)
    avg_seances = db.session.query(func.avg(Planning.nb_seances)).scalar() or 0
    total_exercises = Exercice.query.count()
    avg_exercises = (total_exercises / total_plannings) if total_plannings > 0 else 0

    # 4. Activité du Roster
    avg_players_per_coach = (total_joueurs / total_coaches) if total_coaches > 0 else 0
    player_activity = AnalyticsEvent.query.filter(AnalyticsEvent.event_name.in_(['player_added', 'player_removed'])).count()

    # 5. Collaboration & Invitations
    invites_sent = Invitation.query.count()
    invites_accepted = Invitation.query.filter_by(status='accepted').count()
    acceptance_rate = (invites_accepted / invites_sent * 100) if invites_sent > 0 else 0
    
    total_collabs = PlanningCollaborator.query.count()
    nb_shared_plannings = db.session.query(func.count(func.distinct(PlanningCollaborator.planning_id))).scalar() or 0
    avg_collabs = (total_collabs / nb_shared_plannings) if nb_shared_plannings > 0 else 0

    # 6. Sécurité & Divers
    password_resets = AnalyticsEvent.query.filter_by(event_name='password_reset_requested').count()
    pdf_exports = AnalyticsEvent.query.filter_by(event_name='pdf_exported').count()
    mode_counts = db.session.query(Planning.mode, func.count(Planning.id))\
        .group_by(Planning.mode).all()
    
    return jsonify({
        "kpis": {
            "total_coaches": total_coaches,
            "total_plannings": total_plannings,
            "total_joueurs": total_joueurs,
            "total_feedbacks": total_feedbacks,
            "dau": dau,
            "mau": mau,
            "pdf_exports": pdf_exports,
            "avg_seances": round(float(avg_seances), 1),
            "avg_exercises": round(float(avg_exercises), 1),
            "avg_players_per_coach": round(float(avg_players_per_coach), 1),
            "player_activity": player_activity,
            "invites_sent": invites_sent,
            "acceptance_rate": round(float(acceptance_rate), 1),
            "avg_collaborators": round(float(avg_collabs), 1),
            "password_resets": password_resets
        },
        "plannings_by_mode": dict(mode_counts)
    }), 200




@analytics_bp.route('/coaches', methods=['GET'])
@admin_required
def get_all_coaches(current_admin):
    q = request.args.get('q', '')
    query = Coach.query
    if q:
        query = query.filter(db.or_(
            Coach.nom.ilike(f'%{q}%'),
            Coach.email.ilike(f'%{q}%'),
            Coach.nom_equipe.ilike(f'%{q}%')
        ))
    coaches = query.order_by(Coach.created_at.desc()).all()
    
    # Pour chaque coach, on peut essayer de trouver sa dernière activité via les events
    coach_list = []
    for c in coaches:
        last_event = AnalyticsEvent.query.filter_by(user_id=c.id)\
            .order_by(AnalyticsEvent.timestamp.desc()).first()
        
        c_dict = c.to_dict()
        c_dict['last_activity'] = last_event.timestamp.isoformat() if last_event else None
        c_dict['plannings_count'] = len(c.plannings)
        coach_list.append(c_dict)
        
    return jsonify(coach_list), 200


@analytics_bp.route('/feedbacks', methods=['GET'])
@admin_required
def get_all_feedbacks(current_admin):
    q = request.args.get('q', '')
    query = db.session.query(Feedbacks).join(Coach)
    if q:
        query = query.filter(db.or_(
            Feedbacks.commentaire.ilike(f'%{q}%'),
            Coach.nom.ilike(f'%{q}%'),
            Coach.email.ilike(f'%{q}%')
        ))
    all_feedbacks = query.order_by(Feedbacks.created_at.desc()).all()
    res = []
    for f in all_feedbacks:
        coach = db.session.get(Coach, f.coach_id)
        res.append({
            "id": f.id,
            "content": f.commentaire,
            "created_at": f.created_at.isoformat() if f.created_at else None,
            "status": f.status,
            "coach_name": coach.nom if coach else "Inconnu",
            "coach_email": coach.email if coach else "N/A"
        })
        
    return jsonify(res), 200

@analytics_bp.route('/feedbacks/<int:feedback_id>', methods=['PUT', 'DELETE'])
@admin_required
def manage_feedback(current_admin, feedback_id):
    feedback = Feedbacks.query.get_or_404(feedback_id)
    
    if request.method == 'DELETE':
        db.session.delete(feedback)
        db.session.commit()
        return jsonify({"message": "Feedback supprimé"}), 200
        
    if request.method == 'PUT':
        data = request.get_json()
        status = data.get('status')
        if status:
            feedback.status = status
            db.session.commit()
            return jsonify(feedback.to_dict()), 200
        return jsonify({"error": "Status manquant"}), 400