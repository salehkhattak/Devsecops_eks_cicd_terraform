from backend.app import mysql

def init_db_schema():
    try:
        cur = mysql.connection.cursor()
        
        # Check if table exists
        cur.execute("SHOW TABLES LIKE 'messages'")
        if cur.fetchone():
            # Check if new columns exist
            cur.execute("SHOW COLUMNS FROM messages LIKE 'author'")
            if not cur.fetchone():
                cur.execute("ALTER TABLE messages ADD COLUMN author VARCHAR(255) DEFAULT 'Anonymous'")
            
            cur.execute("SHOW COLUMNS FROM messages LIKE 'likes'")
            if not cur.fetchone():
                cur.execute("ALTER TABLE messages ADD COLUMN likes INT DEFAULT 0")

            cur.execute("SHOW COLUMNS FROM messages LIKE 'created_at'")
            if not cur.fetchone():
                cur.execute("ALTER TABLE messages ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
        else:
            cur.execute('''
            CREATE TABLE messages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                message TEXT,
                author VARCHAR(255) DEFAULT 'Anonymous',
                likes INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            ''')
        mysql.connection.commit()
        cur.close()
        print("Database schema initialized successfully (with author, likes, created_at)")
    except Exception as e:
        print(f"Database schema initialization error: {e}")

class MessageModel:
    @staticmethod
    def get_all_messages():
        cur = mysql.connection.cursor()
        cur.execute('SELECT id, message, author, likes, created_at FROM messages ORDER BY id DESC')
        messages = cur.fetchall()
        cur.close()
        
        result = []
        for msg in messages:
            result.append({
                'id': msg[0],
                'message': msg[1],
                'author': msg[2],
                'likes': msg[3],
                'created_at': msg[4]
            })
        return result

    @staticmethod
    def create_message(message, author="Anonymous"):
        cur = mysql.connection.cursor()
        cur.execute('INSERT INTO messages (message, author) VALUES (%s, %s)', [message, author])
        mysql.connection.commit()
        
        last_id = cur.lastrowid
        cur.close()
        return last_id

    @staticmethod
    def like_message(message_id):
        cur = mysql.connection.cursor()
        cur.execute('UPDATE messages SET likes = likes + 1 WHERE id = %s', [message_id])
        mysql.connection.commit()
        cur.close()
        return True
