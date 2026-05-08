from backend.app.models import MessageModel

class MessageService:
    @staticmethod
    def get_messages():
        try:
            return MessageModel.get_all_messages()
        except Exception as e:
            raise Exception(f"Failed to fetch messages: {e}")

    @staticmethod
    def add_message(message, author="Anonymous"):
        if not message or not str(message).strip():
            raise ValueError("Message content cannot be empty")
        
        if not author or not str(author).strip():
            author = "Anonymous"

        try:
            return MessageModel.create_message(message, author)
        except Exception as e:
            raise Exception(f"Failed to create message: {e}")
            
    @staticmethod
    def like_message(message_id):
        try:
            return MessageModel.like_message(message_id)
        except Exception as e:
            raise Exception(f"Failed to like message: {e}")
