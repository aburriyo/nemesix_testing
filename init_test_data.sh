#!/bin/bash

# Script para inicializar datos de prueba en la base de datos
# Versión: 1.0
# Fecha: 28 de agosto de 2025

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🌱 Inicializando datos de prueba para Nemesix..."

# Verificar que estamos en el directorio correcto
if [ ! -f "app.py" ]; then
    print_error "No se encuentra app.py. Ejecuta este script desde el directorio raíz del proyecto."
    exit 1
fi

# Verificar que existe la base de datos
if [ ! -f "database/nemesix_db.db" ]; then
    print_error "Base de datos no encontrada. Ejecuta primero el despliegue."
    exit 1
fi

print_status "Creando usuario administrador de prueba..."

# Crear script Python para inicializar datos
cat > init_test_data.py << 'EOF'
import sys
import os
sys.path.append('.')

from config.mysqlconnection import connectToMySQL
from werkzeug.security import generate_password_hash
import sqlite3

def init_test_data():
    # Conectar a la base de datos
    db_path = 'database/nemesix_db.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Verificar si ya existe un usuario admin
    cursor.execute("SELECT COUNT(*) FROM users WHERE email = ?", ('admin@nemesix.com',))
    count = cursor.fetchone()[0]

    if count > 0:
        print("Usuario administrador ya existe")
        conn.close()
        return

    # Crear usuario administrador
    admin_username = 'admin'
    admin_email = 'admin@nemesix.com'
    admin_password = 'admin123'  # Cambiar en producción
    hashed_password = generate_password_hash(admin_password)

    cursor.execute('''
        INSERT INTO users (username, email, password)
        VALUES (?, ?, ?)
    ''', (admin_username, admin_email, hashed_password))

    # Crear algunos usuarios de prueba
    test_users = [
        ('testuser1', 'test1@nemesix.com', 'test123'),
        ('testuser2', 'test2@nemesix.com', 'test123'),
        ('testuser3', 'test3@nemesix.com', 'test123'),
    ]

    for username, email, password in test_users:
        hashed_password = generate_password_hash(password)
        cursor.execute('''
            INSERT INTO users (username, email, password)
            VALUES (?, ?, ?)
        ''', (username, email, hashed_password))

    conn.commit()
    conn.close()

    print("✅ Datos de prueba inicializados correctamente")
    print("👤 Usuario administrador creado:")
    print("   Email: admin@nemesix.com")
    print("   Password: admin123")
    print("   ⚠️  IMPORTANTE: Cambia esta contraseña en producción!")
    print("")
    print("👥 Usuarios de prueba creados:")
    print("   test1@nemesix.com / test123")
    print("   test2@nemesix.com / test123")
    print("   test3@nemesix.com / test123")

if __name__ == "__main__":
    init_test_data()
EOF

# Ejecutar el script de inicialización
python3 init_test_data.py

# Limpiar archivo temporal
rm init_test_data.py

print_success "✅ Inicialización de datos completada"
echo ""
print_warning "🔐 Credenciales de acceso:"
echo "   🌐 URL: http://tu-droplet-ip"
echo "   👤 Admin: admin@nemesix.com / admin123"
echo "   👤 Test: test1@nemesix.com / test123"
echo ""
print_warning "⚠️  RECUERDA cambiar la contraseña del administrador en producción"
echo ""
print_status "Para acceder al sistema:"
echo "   1. Ve a: http://tu-droplet-ip"
echo "   2. Haz clic en 'Iniciar Sesión'"
echo "   3. Usa las credenciales de arriba"
echo "   4. Una vez dentro, ve al Dashboard para ver todos los usuarios"
