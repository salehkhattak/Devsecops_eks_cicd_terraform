import os
import sys

# Add the root directory to path so it can find the backend module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.app import create_app

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        from backend.app.models import init_db_schema
        init_db_schema()
    print("Starting Flask app on http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)
