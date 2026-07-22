import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Base de données Supabase (PostgreSQL)
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", "mysql+pymysql://root:@localhost/volleyplan_db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # Dans config.py
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,      # teste la connexion avant chaque requête
        "pool_recycle": 300,        # recycle les connexions toutes les 5 min
        "pool_timeout": 20,
        "pool_size": 5,
        "max_overflow": 2,
    }
    #paiement via cinetpay
    CINETPAY_API_KEY = os.getenv("CINETPAY_API_KEY")
    CINETPAY_ACCOUNT_PASSWORD = os.getenv("CINETPAY_ACCOUNT_PASSWORD")
    CINETPAY_WEBHOOK_URL = os.getenv("CINETPAY_WEBHOOK_URL")
    CINETPAY_SUCCES_URL  = os.getenv("CINETPAY_SUCCES_URL")
    CINETPAY_FAILED_URL  = os.getenv("CINETPAY_FAILED_URL")
    CINETPAY_SECRET_KEY  = os.getenv("CINETPAY_SECRET_KEY")

    # JWT
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
    JWT_ACCESS_TOKEN_EXPIRES = 60 * 60 * 24 * 30 # 30 jours

    # CORS
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False

config = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "default": DevelopmentConfig,
}