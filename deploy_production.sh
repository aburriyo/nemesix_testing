#!/bin/bash

# Script de despliegue para servidor de producción
# Fecha: 28 de agosto de 2025

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "🚀 DESPLIEGUE EN PRODUCCIÓN - NEMESIX"
echo "====================================="

# Verificar si estamos en un repositorio git
if [ ! -d ".git" ]; then
    print_error "No se encontró repositorio Git"
    exit 1
fi

print_status "Actualizando código desde repositorio..."
git pull origin main

print_status "Activando entorno virtual..."
source venv/bin/activate

print_status "Instalando dependencias..."
pip install -r requirements.txt

print_status "Aplicando configuración de Nginx..."
sudo ./fix_nginx_complete.sh

print_status "Reiniciando servicios..."
sudo systemctl restart nemesix
sudo systemctl restart nginx

print_status "Verificando servicios..."
sleep 3

if sudo systemctl is-active --quiet nemesix; then
    print_success "✅ Servicio Nemesix activo"
else
    print_error "❌ Servicio Nemesix falló"
    exit 1
fi

if sudo systemctl is-active --quiet nginx; then
    print_success "✅ Servicio Nginx activo"
else
    print_error "❌ Servicio Nginx falló"
    exit 1
fi

print_status "Probando conectividad..."
if curl -s http://localhost/health > /dev/null; then
    print_success "✅ Servidor respondiendo correctamente"
else
    print_error "❌ Servidor no responde"
    exit 1
fi

print_success "🎉 DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo ""
echo "🌐 URLs disponibles:"
echo "   Local: http://localhost"
echo "   Health: http://localhost/health"
echo "   Tu dominio: http://tu-dominio.com"
echo ""
echo "📊 Estado de servicios:"
sudo systemctl status nemesix --no-pager -l
echo ""
sudo systemctl status nginx --no-pager -l
