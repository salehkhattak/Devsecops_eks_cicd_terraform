import os

class Config:
    MYSQL_HOST = os.environ.get('MYSQL_HOST', 'mysql')
    MYSQL_USER = os.environ.get('MYSQL_USER', 'admin')
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD', 'admin')
    MYSQL_DB = os.environ.get('MYSQL_DB', 'mydb')
    MYSQL_PORT = int(os.environ.get('MYSQL_PORT', 3306))
