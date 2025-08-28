#!/bin/bash

# Script simplificado de despliegue para Nemesix en Ubuntu
# Versión: 1.0 - Corregida

set -e

echo "🚀 Iniciando despliegue simplificado de Nemesix..."

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar si estamos en Ubuntu/Debian
if ! command_exists apt; then
    print_error "Este script es para sistemas Ubuntu/Debian"
    exit 1
fi

# Actualizar sistema
print_status "📦 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias del sistema
print_status "🔧 Instalando dependencias del sistema..."
sudo apt install -y python3 python3-pip python3-venv nginx git ufw curl

# Instalar certbot (opcional)
sudo apt install -y certbot python3-certbot-nginx

# Configurar firewall básico
print_status "🔥 Configurando firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'

# Crear directorio del proyecto si no existe
PROJECT_DIR="/var/www/nemesix"
if [ ! -d "$PROJECT_DIR" ]; then
    print_status "📁 Creando directorio del proyecto..."
    sudo mkdir -p $PROJECT_DIR
    sudo chown -R $USER:$USER $PROJECT_DIR
fi

# Copiar archivos del proyecto
print_status "📋 Copiando archivos del proyecto..."
CURRENT_DIR="$(pwd)"
sudo cp -r $CURRENT_DIR/* $PROJECT_DIR/
sudo chown -R $USER:$USER $PROJECT_DIR

cd $PROJECT_DIR

# Configurar entorno virtual
print_status "🐍 Configurando entorno virtual..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Crear directorios necesarios
print_status "📂 Creando directorios necesarios..."
mkdir -p database
mkdir -p logs
chmod 755 static/
chmod 755 database/
chmod 755 logs/

# Inicializar base de datos
print_status "🗄️ Inicializando base de datos..."
python3 -c "
import sys
import os
sys.path.append('.')
from config.mysqlconnection import connectToMySQL

# Conectar a la base de datos (esto crea las tablas automáticamente)
db = connectToMySQL('nemesix_db')
print('Base de datos inicializada correctamente')
"

# Crear usuarios de prueba
print_status "👤 Creando usuarios de prueba..."
chmod +x init_test_data.sh
./init_test_data.sh

# Configurar Nginx
print_status "🌐 Configurando Nginx..."

# Actualizar configuración de Nginx con la ruta correcta
sudo sed -i "s|/ruta/a/tu/proyecto/nemesix_testing|$PROJECT_DIR|g" nginx.conf

# Copiar configuración
sudo cp nginx.conf /etc/nginx/sites-available/nemesix

# Crear enlace simbólico
sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/

# Remover configuración por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# Probar configuración
if sudo nginx -t; then
    sudo systemctl reload nginx
    print_status "✅ Nginx configurado correctamente"
else
    print_error "❌ Error en configuración de Nginx"
    exit 1
fi

# Crear servicio systemd
print_status "⚙️ Creando servicio systemd..."
sudo tee /etc/systemd/system/nemesix.service > /dev/null <<EOF
[Unit]
Description=Nemesix Flask Application
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
Environment="FLASK_ENV=production"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --config gunicorn_config.py app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar servicio
sudo systemctl daemon-reload
sudo systemctl enable nemesix
sudo systemctl start nemesix

# Verificar que el servicio esté corriendo
if sudo systemctl is-active --quiet nemesix; then
    print_status "✅ Servicio Nemesix iniciado correctamente"
else
    print_error "❌ Error al iniciar el servicio Nemesix"
    sudo systemctl status nemesix
    exit 1
fi

# Verificar conectividad
print_status "🔍 Verificando conectividad..."
sleep 3

if curl -f http://localhost/health > /dev/null 2>&1; then
    print_status "✅ Aplicación funcionando correctamente"
else
    print_error "❌ Error de conectividad"
fi

print_status "🎉 ¡Despliegue completado!"
echo ""
echo "📋 Información importante:"
echo "   🌐 URL local: http://localhost"
echo "   🔧 Servicio: sudo systemctl status nemesix"
echo "   🌐 Nginx: sudo systemctl status nginx"
echo "   📝 Logs de aplicación: sudo journalctl -u nemesix -f"
echo "   📝 Logs de Nginx: sudo tail -f /var/log/nginx/nemesix_error.log"
echo "   🏥 Health check: http://localhost/health"
echo ""
echo "👤 Credenciales de prueba:"
echo "   Admin: admin@nemesix.com / admin123"
echo "   Test: test1@nemesix.com / test123"