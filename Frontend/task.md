# Task List — Roster Premium

## Installation
- [/] Installer flask-apscheduler

## Modèles
- [ ] `models/presences.py` — table absences (NOUVEAU)
- [ ] `models/seances.py` — ajouter `presences_prises`, `presences_auto`
- [ ] `models/notification.py` — ajouter `type`, `seance_id`

## Utils
- [ ] `utils/decorators.py` — `@premium_required`

## Services
- [ ] `services/presence.py` — logique prise de présences
- [ ] `services/stats_joueurs.py` — calcul radar, stats, comparaison

## Scheduler
- [ ] `app/scheduler.py` — jobs auto-notif + auto-lock

## Controllers
- [ ] `controllers/joueurs.py` — routes présences (GET + POST)
- [ ] `controllers/stats_joueurs.py` — routes stats (NOUVEAU)
- [ ] `controllers/notifications.py` — update to_dict avec seance_id

## App Init
- [ ] `app/__init__.py` — register blueprint + scheduler + model presences

## Migration DB
- [ ] `flask db migrate` + `flask db upgrade`
