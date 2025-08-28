#!/bin/bash

# Script para gestionar sesiones de Screen
# Fecha: 28 de agosto de 2025

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

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

SESSION_NAME="nemesix_server"

echo "📺 GESTIÓN DE SESIONES SCREEN - NEMESIX"
echo "======================================="

case "$1" in
    "list"|"ls")
        print_status "Sesiones de screen activas:"
        screen -list
        ;;

    "connect"|"attach"|"r")
        if screen -list | grep -q "$SESSION_NAME"; then
            print_status "Conectando a la sesión: $SESSION_NAME"
            screen -r $SESSION_NAME
        else
            print_error "No existe la sesión: $SESSION_NAME"
            print_info "Sesiones disponibles:"
            screen -list
        fi
        ;;

    "stop"|"kill"|"quit")
        if screen -list | grep -q "$SESSION_NAME"; then
            print_warning "Deteniendo la sesión: $SESSION_NAME"
            screen -S $SESSION_NAME -X quit
            print_success "Sesión detenida exitosamente"
        else
            print_error "No existe la sesión: $SESSION_NAME"
        fi
        ;;

    "status")
        if screen -list | grep -q "$SESSION_NAME"; then
            print_success "✅ El servidor NEMESIX está corriendo"
            print_info "Sesión: $SESSION_NAME"
            print_info "URL: http://127.0.0.1:8080"
        else
            print_warning "❌ El servidor NEMESIX no está corriendo"
            print_info "Para iniciarlo: ./start_server.sh"
        fi
        ;;

    "logs"|"log")
        if screen -list | grep -q "$SESSION_NAME"; then
            print_status "Mostrando logs de la sesión (presiona Ctrl+C para salir):"
            screen -S $SESSION_NAME -X hardcopy /tmp/screen_log.txt
            tail -f /tmp/screen_log.txt
        else
            print_error "No existe la sesión: $SESSION_NAME"
        fi
        ;;

    *)
        echo "Uso: $0 {list|connect|stop|status|logs}"
        echo ""
        echo "📋 COMANDOS DISPONIBLES:"
        echo "   list     - Ver todas las sesiones activas"
        echo "   connect  - Conectarte a la sesión del servidor"
        echo "   stop     - Detener el servidor"
        echo "   status   - Verificar si el servidor está corriendo"
        echo "   logs     - Ver los logs del servidor"
        echo ""
        echo "💡 EJEMPLOS:"
        echo "   ./manage_screen.sh list"
        echo "   ./manage_screen.sh connect"
        echo "   ./manage_screen.sh stop"
        echo "   ./manage_screen.sh status"
        ;;
esac
