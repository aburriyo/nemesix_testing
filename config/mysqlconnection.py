import sqlite3
import os

class SQLiteConnection:
    def __init__(self, db_name):
        # Crear la carpeta database si no existe
        db_folder = os.path.join(os.path.dirname(__file__), '..', 'database')
        os.makedirs(db_folder, exist_ok=True)

        # Ruta completa de la base de datos
        self.db_path = os.path.join(db_folder, f"{db_name}.db")

        # Inicializar la base de datos si no existe
        self._init_database()

    def _init_database(self):
        """Crear las tablas necesarias si no existen"""
        connection = sqlite3.connect(self.db_path)
        connection.row_factory = sqlite3.Row  # Para obtener resultados como diccionarios
        cursor = connection.cursor()

        # Crear tabla de usuarios
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username VARCHAR(255) NOT NULL UNIQUE,
                email VARCHAR(255) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        connection.commit()
        connection.close()

    def query_db(self, query, data=None):
        connection = sqlite3.connect(self.db_path)
        connection.row_factory = sqlite3.Row
        cursor = connection.cursor()

        try:
            print("Running Query:", query)
            if data:
                print("With data:", data)

            # Convertir parámetros de %(name)s a :name para SQLite
            if data and isinstance(data, dict):
                # Reemplazar %(key)s con :key
                for key in data.keys():
                    query = query.replace(f'%({key})s', f':{key}')

            cursor.execute(query, data or {})

            if query.lower().strip().startswith("insert"):
                # INSERT statements return the ID NUMBER of the row inserted
                connection.commit()
                return cursor.lastrowid
            elif query.lower().strip().startswith("select"):
                # SELECT statements return a LIST of DICTIONARIES
                result = cursor.fetchall()
                # Convertir Row objects a diccionarios
                return [dict(row) for row in result]
            else:
                # UPDATE and DELETE statements return nothing
                connection.commit()
                return True

        except Exception as e:
            print("Something went wrong", e)
            return False
        finally:
            connection.close()

# Mantener compatibilidad con el nombre original de la función
def connectToMySQL(db_name):
    return SQLiteConnection(db_name)
