#!/bin/bash

# Script de solución rápida para Error 502 Bad Gateway en Nemesix
# Versión: 3.0 - Optimizado para Ubuntu
# Fecha: 28 de agosto de 2025

set -e

# Colores
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "🔧 SOLUCIÓN RÁPIDA PARA ERROR 502 BAD GATEWAY"
echo "=============================================="

# 1. Detener servicios
print_status "Deteniendo servicios..."
sudo systemctl stop nemesix 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# 2. Verificar y crear directorios
print_status "Verificando directorios..."
PROJECT_DIR="/var/www/nemesix"
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR

# 3. Copiar archivos actualizados
print_status "Copiando archivos actualizados..."
sudo cp -r * $PROJECT_DIR/ 2>/dev/null || true
sudo chown -R $USER:$USER $PROJECT_DIR

cd $PROJECT_DIR

# 4. Recrear entorno virtual
print_status "Recreando entorno virtual..."
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. Crear directorios necesarios
print_status "Creando directorios necesarios..."
mkdir -p database logs
chmod 755 static/ database/ logs/

# 6. Inicializar base de datos
print_status "Inicializando base de datos..."
python3 -c "
import sys
sys.path.append('.')
from config.mysqlconnection import connectToMySQL
db = connectToMySQL('nemesix_db')
print('Base de datos inicializada')
"

# 7. Actualizar configuración de Nginx
print_status "Actualizando configuración de Nginx..."
sudo sed -i "s|/ruta/a/tu/proyecto/nemesix_testing|$PROJECT_DIR|g" nginx.conf
sudo cp nginx.conf /etc/nginx/sites-available/nemesix
sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/ 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default

# 8. Probar configuración de Nginx
print_status "Probando configuración de Nginx..."
if sudo nginx -t; then
    print_success "Configuración de Nginx correcta"
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

# 9. Actualizar servicio systemd
print_status "Actualizando servicio systemd..."
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

# 10. Recargar systemd
print_status "Recargando systemd..."
sudo systemctl daemon-reload

# 11. Iniciar servicios
print_status "Iniciando servicios..."
sudo systemctl start nemesix
sudo systemctl start nginx

# 12. Verificar servicios
print_status "Verificando servicios..."
sleep 3

if sudo systemctl is-active --quiet nemesix; then
    print_success "Servicio Nemesix activo"
else
    print_error "Servicio Nemesix falló"
    sudo systemctl status nemesix
    exit 1
fi

if sudo systemctl is-active --quiet nginx; then
    print_success "Servicio Nginx activo"
else
    print_error "Servicio Nginx falló"
    sudo systemctl status nginx
    exit 1
fi

# 13. Probar conectividad
print_status "Probando conectividad..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_success "Aplicación funcionando correctamente"
else
    print_error "Error de conectividad"
    exit 1
fi

print_success "✅ ¡PROBLEMA SOLUCIONADO!"
echo ""
echo "🌐 URLs disponibles:"
echo "   Local: http://localhost"
echo "   Health check: http://localhost/health"
echo ""
echo "� Comandos útiles:"
echo "   Ver estado: sudo systemctl status nemesix"
echo "   Ver logs: sudo journalctl -u nemesix -f"
echo "   Reiniciar: sudo systemctl restart nemesix"
