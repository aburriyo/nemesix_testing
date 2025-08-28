from config.mysqlconnection import connectToMySQL
from flask import flash
import re
from werkzeug.security import generate_password_hash, check_password_hash

EMAIL_REGEX = re.compile(r'^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9._-]+\.[a-zA-Z]+$')

class User:
    def __init__(self, data):
        self.id = data['id']
        self.username = data['username']
        self.email = data['email']
        self.password = data['password']
        self.created_at = data['created_at']
        self.updated_at = data['updated_at']

    @classmethod
    def create_user(cls, username, email, password):
        if not cls.validate_user({'username': username, 'email': email, 'password': password}):
            return False

        # Hash the password before storing
        hashed_password = generate_password_hash(password)

        query = "INSERT INTO users (username, email, password) VALUES (%(username)s, %(email)s, %(password)s);"
        data = {
            'username': username,
            'email': email,
            'password': hashed_password
        }
        return connectToMySQL('nemesix_db').query_db(query, data)

    @classmethod
    def get_user_by_email(cls, email):
        query = "SELECT * FROM users WHERE email = %(email)s;"
        data = {'email': email}
        result = connectToMySQL('nemesix_db').query_db(query, data)
        if result:
            return result[0]
        return False

    @classmethod
    def get_user_by_id(cls, id):
        query = "SELECT * FROM users WHERE id = %(id)s;"
        data = {'id': id}
        result = connectToMySQL('nemesix_db').query_db(query, data)
        if result:
            return cls(result[0])
        return False

    @staticmethod
    def validate_user(user):
        is_valid = True

        if len(user['username']) < 3:
            flash('El nombre de usuario debe tener al menos 3 caracteres')
            is_valid = False

        if not EMAIL_REGEX.match(user['email']):
            flash('Por favor, ingresa un email válido')
            is_valid = False

        if len(user['password']) < 8:
            flash('La contraseña debe tener al menos 8 caracteres')
            is_valid = False

        return is_valid

    @classmethod
    def get_all_users(cls):
        query = "SELECT * FROM users ORDER BY created_at DESC;"
        result = connectToMySQL('nemesix_db').query_db(query)
        users = []
        if result:
            for row in result:
                users.append(cls(row))
        return users

    @classmethod
    def update_user(cls, user_id, data):
        # Construir query dinámicamente basado en los campos a actualizar
        fields = []
        for key in data.keys():
            fields.append(f"{key} = %({key})s")

        query = f"UPDATE users SET {', '.join(fields)}, updated_at = CURRENT_TIMESTAMP WHERE id = %(id)s;"
        data['id'] = user_id

        return connectToMySQL('nemesix_db').query_db(query, data)

    @classmethod
    def delete_user(cls, user_id):
        query = "DELETE FROM users WHERE id = %(id)s;"
        data = {'id': user_id}
        return connectToMySQL('nemesix_db').query_db(query, data)
