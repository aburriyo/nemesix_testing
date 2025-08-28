#!/bin/bash

# Script para actualizar el servidor Nemesix desde Git
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

echo "🔄 ACTUALIZACIÓN DEL SERVIDOR NEMESIX"
echo "====================================="

# Verificar si estamos en un repositorio git
if [ ! -d ".git" ]; then
    print_error "No se encontró repositorio Git en el directorio actual"
    exit 1
fi

# Verificar si hay cambios sin commitear
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Hay cambios sin commitear:"
    git status --short
    echo ""
    read -p "¿Quieres continuar sin guardar estos cambios? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operación cancelada. Guarda tus cambios primero."
        exit 1
    fi
fi

print_status "Verificando estado del repositorio..."
git status

echo ""
print_status "Descargando últimas actualizaciones..."
git pull origin main

echo ""
print_status "Instalando/actualizando dependencias..."
if [ -d "venv" ]; then
    source venv/bin/activate
    pip install -r requirements.txt
else
    print_warning "No se encontró entorno virtual. Creándolo..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

echo ""
print_status "Verificando configuración del servidor..."

# Verificar si hay una sesión de screen corriendo
SESSION_NAME="nemesix_server"
if screen -list | grep -q "$SESSION_NAME"; then
    print_warning "Servidor corriendo detectado. Reiniciando..."

    # Detener el servidor actual
    screen -S $SESSION_NAME -X quit
    sleep 2

    # Iniciar el servidor actualizado
    print_status "Iniciando servidor actualizado..."
    ./start_server.sh
else
    print_info "No hay servidor corriendo. Iniciándolo..."
    ./start_server.sh
fi

echo ""
print_success "✅ ACTUALIZACIÓN COMPLETADA"
echo ""
echo "📋 ESTADO ACTUAL:"
echo "   ✅ Código actualizado desde Git"
echo "   ✅ Dependencias instaladas"
echo "   ✅ Servidor reiniciado"
echo ""
echo "🌐 ACCESO:"
echo "   URL: http://127.0.0.1:8080"
echo "   Health: http://127.0.0.1:8080/health"
echo ""
echo "🔧 GESTIÓN:"
echo "   Estado: ./manage_screen.sh status"
echo "   Logs: ./manage_screen.sh logs"
echo "   Detener: ./manage_screen.sh stop"
