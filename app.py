from flask import Flask, render_template, request, redirect, session, flash, url_for
from models.user import User
import os
import logging
from werkzeug.security import generate_password_hash, check_password_hash
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración de logging para producción
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuración de producción
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['SESSION_COOKIE_SECURE'] = os.environ.get('FLASK_ENV') == 'production'
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'

# Configuración de archivos estáticos para producción
app.config['STATIC_FOLDER'] = 'static'
app.config['TEMPLATES_FOLDER'] = 'templates'

# Configuración de base de datos
database_path = os.path.join(os.path.dirname(__file__), 'database', 'nemesix_db.db')
if not os.path.exists(os.path.dirname(database_path)):
    os.makedirs(os.path.dirname(database_path))

@app.errorhandler(404)
def page_not_found(e):
    logger.warning(f'Página no encontrada: {request.url}')
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    logger.error(f'Error interno del servidor: {str(e)}')
    return render_template('500.html'), 500

@app.route("/")
def index():
    try:
        return render_template("index.html")
    except Exception as e:
        logger.error(f'Error en index: {str(e)}')
        return "Error loading page", 500

@app.route("/login", methods=["GET", "POST"])
def login():
    try:
        if request.method == "POST":
            email = request.form.get("email", "").strip()
            password = request.form.get("password", "")

            if not email or not password:
                logger.warning(f'Intento de login con campos vacíos desde IP: {request.remote_addr}')
                flash("Por favor, complete todos los campos", "error")
                return redirect(url_for('login'))

            user_data = User.get_user_by_email(email)
            if user_data and check_password_hash(user_data['password'], password):
                session['user_id'] = user_data['id']
                session['username'] = user_data['username']
                logger.info(f'Usuario {email} inició sesión exitosamente desde IP: {request.remote_addr}')
                flash("Inicio de sesión exitoso", "success")
                return redirect(url_for('dashboard'))
            else:
                logger.warning(f'Intento de login fallido para: {email} desde IP: {request.remote_addr}')
                flash("Credenciales incorrectas", "error")
                return redirect(url_for('login'))

        return render_template("login.html")
    except Exception as e:
        logger.error(f'Error en login: {str(e)} - IP: {request.remote_addr}')
        flash("Error interno del servidor", "error")
        return redirect(url_for('login'))

@app.route("/register", methods=["GET", "POST"])
def register():
    try:
        if request.method == "POST":
            username = request.form.get("username", "").strip()
            email = request.form.get("email", "").strip()
            password = request.form.get("password", "")

            if not username or not email or not password:
                logger.warning(f'Intento de registro con campos vacíos desde IP: {request.remote_addr}')
                flash("Por favor, complete todos los campos", "error")
                return redirect(url_for('register'))

            hashed_password = generate_password_hash(password)

            if User.create_user(username, email, hashed_password):
                logger.info(f'Nuevo usuario registrado: {email} desde IP: {request.remote_addr}')
                flash("Usuario registrado exitosamente", "success")
                return redirect(url_for('login'))
            else:
                logger.warning(f'Error al registrar usuario: {email} desde IP: {request.remote_addr}')
                flash("Error al registrar usuario", "error")
                return redirect(url_for('register'))

        return render_template("register.html")
    except Exception as e:
        logger.error(f'Error en register: {str(e)} - IP: {request.remote_addr}')
        flash("Error interno del servidor", "error")
        return redirect(url_for('register'))

@app.route("/dashboard")
def dashboard():
    try:
        if 'user_id' not in session:
            return redirect(url_for('login'))

        users = User.get_all_users()
        return render_template("dashboard.html", users=users)
    except Exception as e:
        logger.error(f'Error en dashboard: {str(e)}')
        flash("Error interno del servidor", "error")
        return redirect(url_for('index'))

@app.route("/profile")
def profile():
    try:
        if 'user_id' not in session:
            return redirect(url_for('login'))

        user = User.get_user_by_id(session['user_id'])
        if not user:
            session.clear()
            return redirect(url_for('login'))

        return render_template("profile.html", user=user)
    except Exception as e:
        logger.error(f'Error en profile: {str(e)}')
        flash("Error interno del servidor", "error")
        return redirect(url_for('index'))

@app.route("/logout")
def logout():
    try:
        session.clear()
        logger.info('Usuario cerró sesión')
        flash("Sesión cerrada exitosamente", "success")
        return redirect(url_for('index'))
    except Exception as e:
        logger.error(f'Error en logout: {str(e)}')
        return redirect(url_for('index'))

# Health check endpoint para monitoreo
@app.route("/health")
def health():
    return {"status": "healthy", "timestamp": os.environ.get('TIMESTAMP', 'unknown')}, 200

if __name__ == "__main__":
    # Configuración para desarrollo local
    app.run(
        host='0.0.0.0',
        port=int(os.environ.get('PORT', 8080)),
        debug=os.environ.get('FLASK_ENV') != 'production'
    )
