from flask import Blueprint, render_template, request, jsonify
from backend.app.services import MessageService

main = Blueprint('main', __name__)

@main.route('/')
def index():
    try:
        messages = MessageService.get_messages()
        return render_template('index.html', messages=messages)
    except Exception as e:
        return f"Application error: {e}", 500

@main.route('/submit', methods=['POST'])
def submit():
    try:
        new_message = request.form.get('new_message')
        author = request.form.get('author', 'Anonymous')
        
        MessageService.add_message(new_message, author)
        return jsonify({'message': 'Successfully added', 'author': author})
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@main.route('/like/<int:message_id>', methods=['POST'])
def like(message_id):
    try:
        MessageService.like_message(message_id)
        return jsonify({'message': 'Like updated'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
