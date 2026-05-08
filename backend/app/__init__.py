import os
from flask import Flask
from flask_mysqldb import MySQL

mysql = MySQL()

def create_app():
    app = Flask(__name__, 
                template_folder=os.path.abspath(os.path.join(os.path.dirname(__file__), '../../frontend/templates')),
                static_folder=os.path.abspath(os.path.join(os.path.dirname(__file__), '../../frontend/static')))
    
    # Load config from the backend package
    from backend.config import Config
    app.config.from_object(Config)

    # Initialize extensions
    mysql.init_app(app)

    # Database initialization function
    def init_db():
        with app.app_context():
            from backend.app.models import init_db_schema
            init_db_schema()

    # Register blueprints
    from backend.app.routes import main
    app.register_blueprint(main)

    # Initialize DB schema before first request
    # Since Flask 2.2 @app.before_first_request is deprecated, we just call it directly during app creation
    # or handle it otherwise. Calling it here requires app context.
    # We will initialize DB when ran via run.py, not directly here to avoid issues if DB isn't ready.

    return app
