#!/bin/bash

# Script para iniciar la aplicación Flask con Gunicorn usando Screen
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

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 INICIANDO SERVIDOR FLASK CON SCREEN"
echo "======================================"

# Verificar si screen está instalado
if ! command -v screen &> /dev/null; then
    print_error "Screen no está instalado. Instálalo con:"
    echo "  Ubuntu/Debian: sudo apt-get install screen"
    echo "  CentOS/RHEL: sudo yum install screen"
    echo "  macOS: brew install screen"
    exit 1
fi

# Verificar si el entorno virtual existe
if [ ! -d "venv" ]; then
    print_error "No se encontró el entorno virtual 'venv'"
    print_info "Ejecuta: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Nombre de la sesión de screen
SESSION_NAME="nemesix_server"

# Verificar si ya existe una sesión con ese nombre
if screen -list | grep -q "$SESSION_NAME"; then
    print_warning "Ya existe una sesión de screen llamada '$SESSION_NAME'"
    print_info "Para conectarte: screen -r $SESSION_NAME"
    print_info "Para ver sesiones: screen -list"
    print_info "Para matar la sesión: screen -S $SESSION_NAME -X quit"
    exit 1
fi

print_status "Creando nueva sesión de screen: $SESSION_NAME"

# Crear la sesión de screen y ejecutar el servidor
screen -dmS $SESSION_NAME bash -c "
    echo 'Activando entorno virtual...'
    source venv/bin/activate
    
    echo 'Iniciando servidor Gunicorn...'
    echo 'Servidor corriendo en: http://127.0.0.1:8080'
    echo 'Para detener: Presiona Ctrl+C'
    echo ''
    
    gunicorn --bind 0.0.0.0:8080 --workers 2 app:app
    
    echo 'Servidor detenido.'
    read -p 'Presiona Enter para cerrar...'
"

print_success "✅ SERVIDOR INICIADO EXITOSAMENTE"
echo ""
echo "📋 INFORMACIÓN IMPORTANTE:"
echo "   Sesión de screen: $SESSION_NAME"
echo "   URL del servidor: http://127.0.0.1:8080"
echo "   Health check: http://127.0.0.1:8080/health"
echo ""
echo "🔧 COMANDOS ÚTILES:"
echo "   Ver sesiones activas: screen -list"
echo "   Conectarte a la sesión: screen -r $SESSION_NAME"
echo "   Desconectarte (sin detener): Ctrl+A, luego D"
echo "   Detener servidor: screen -S $SESSION_NAME -X quit"
echo ""
echo "🌐 El servidor seguirá corriendo incluso si cierras la terminal"
echo "   ¡Puedes cerrar esta ventana sin problemas!"
