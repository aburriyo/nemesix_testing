from flask import Flask, render_template, request, redirect, session, flash, url_for
from models.user import User
import os
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'your_secret_key_here')

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]

        user_data = User.get_user_by_email(email)
        if user_data and check_password_hash(user_data['password'], password):
            session['user_id'] = user_data['id']
            session['username'] = user_data['username']
            flash("Inicio de sesión exitoso", "success")
            return redirect(url_for('dashboard'))
        else:
            flash("Credenciales incorrectas", "error")
            return redirect(url_for('login'))

    return render_template("login.html")

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form["username"]
        email = request.form["email"]
        password = generate_password_hash(request.form["password"])

        if User.create_user(username, email, password):
            flash("Usuario registrado exitosamente", "success")
            return redirect(url_for('login'))
        else:
            return redirect(url_for('register'))

    return render_template("register.html")

@app.route("/dashboard")
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    users = User.get_all_users()
    return render_template("dashboard.html", users=users)

@app.route("/profile")
def profile():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user = User.get_user_by_id(session['user_id'])
    return render_template("profile.html", user=user)

@app.route("/logout")
def logout():
    session.clear()
    flash("Sesión cerrada exitosamente", "success")
    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(debug=True)
