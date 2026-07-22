from app import db
from datetime import datetime, timedelta


class Subscription(db.Model):
    __tablename__ = "abonnements"

    id = db.Column(db.Integer, primary_key=True)
    coach_id   = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False)
    plan = db.Column(db.String(20)) #premium, professionnal, free
    status = db.Column(db.String(20), default='pending') # pending, actived, expired
    start_date = db.Column(db.DateTime, default=None)
    end_date = db.Column(db.DateTime, default=None)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    payment_provider = db.Column(db.String(20), default="CINETPAY") #cinetpay ou stripe
    transaction_id = db.Column(db.String(255), nullable=True) #donner par cinetpay

    def to_dict(self):
        return{
            "id" : self.id,
            "coach_id" : self.coach_id,
            "plan" : self.plan,
            "start_date" : self.start_date.isoformat() if self.start_date else None,
            "end_date" : self.end_date.isoformat() if self.end_date else None,
            "created_at" : self.created_at.isoformat() if self.created_at else None,
            "status" : self.status,
            "payment_provider" : self.payment_provider
        }


class Payments(db.Model):
    __tablename__ = "paiements"

    id = db.Column(db.Integer, primary_key=True)
    coach_id   = db.Column(db.Integer, db.ForeignKey("coaches.id"), nullable=False)
    amount = db.Column(db.Float)
    abonnement_id = db.Column(db.Integer, db.ForeignKey("abonnements.id"), nullable=True)
    provider = db.Column(db.String(20)) #CINETPAY, STRIPE
    status = db.Column(db.String(20)) #PENDDING, EXPIRED
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    currency = db.Column(db.String(10))# monnaie: EUR, US, XAF...
    meta_data= db.Column(db.JSON, default={})
    notify_token = db.Column(db.String(255), nullable=True)
    


    def to_dict(self):
        return{
            "id" : self.id,
            "coach_id" : self.coach_id,
            "amount" : self.amount,
            "abonnement_id" : self.abonnement_id,
            "provider" : self.provider,
            "status" : self.status,
            "created_at" : self.created_at.isoformat() if self.created_at else None,
            "currency" : self.currency,
            "metadata" : self.meta_data
        }



def app_context(app):
     with app.app_context():
         db.create_all()