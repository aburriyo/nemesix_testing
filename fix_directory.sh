#!/bin/bash

# Script auxiliar para resolver problemas de directorio existente
# Versión: 1.0

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

PROJECT_DIR="/var/www/nemesix"

echo "🔧 Asistente para resolver problemas de directorio existente"
echo "======================================================"
echo ""

# Verificar si el directorio existe
if [ ! -d "$PROJECT_DIR" ]; then
    print_success "El directorio $PROJECT_DIR no existe. Puedes ejecutar deploy.sh normalmente."
    exit 0
fi

print_warning "El directorio $PROJECT_DIR ya existe."
echo "Contenido actual:"
ls -la $PROJECT_DIR
echo ""

echo "Opciones disponibles:"
echo "1) Borrar directorio y continuar con deploy.sh"
echo "2) Respaldar contenido y continuar"
echo "3) Ver contenido detallado"
echo "4) Salir"
echo ""

read -p "Selecciona una opción (1-4): " choice

case $choice in
    1)
        print_warning "Esto borrará todo el contenido existente. ¿Estás seguro? (y/N): "
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo rm -rf $PROJECT_DIR
            print_success "Directorio borrado. Ahora puedes ejecutar ./deploy.sh"
        else
            print_status "Operación cancelada."
        fi
        ;;
    2)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_DIR="/var/backups/nemesix_$TIMESTAMP"
        sudo mkdir -p $BACKUP_DIR
        sudo mv $PROJECT_DIR/* $BACKUP_DIR/ 2>/dev/null || true
        sudo rmdir $PROJECT_DIR
        print_success "Contenido respaldado en: $BACKUP_DIR"
        print_success "Ahora puedes ejecutar ./deploy.sh"
        ;;
    3)
        echo "Contenido detallado de $PROJECT_DIR:"
        echo "====================================="
        find $PROJECT_DIR -type f | head -20
        echo ""
        if [ $(find $PROJECT_DIR -type f | wc -l) -gt 20 ]; then
            echo "... y $(($(find $PROJECT_DIR -type f | wc -l) - 20)) archivos más"
        fi
        ;;
    4)
        print_status "Saliendo..."
        exit 0
        ;;
    *)
        print_error "Opción inválida."
        ;;
esac
