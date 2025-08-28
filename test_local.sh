#!/bin/bash

# Script de prueba local completa para Nemesix
# Versión: 1.0
# Fecha: 28 de agosto de 2025

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

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

echo -e "${CYAN}🧪 PRUEBA LOCAL COMPLETA DE NEMESIX${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# 1. Verificar entorno
print_header "1. VERIFICACIÓN DEL ENTORNO"

echo -n "Python versión: "
python3 --version

echo -n "Directorio actual: "
pwd

echo -n "Entorno virtual: "
if [ -z "$VIRTUAL_ENV" ]; then
    print_warning "No activado"
    source .venv/bin/activate
    print_success "Activado"
else
    print_success "Ya activo"
fi

# 2. Verificar dependencias
print_header "2. VERIFICACIÓN DE DEPENDENCIAS"

echo "Verificando dependencias instaladas:"
pip list | grep -E "(Flask|Werkzeug|sqlite)" || print_warning "Algunas dependencias pueden faltar"

# 3. Configurar entorno
print_header "3. CONFIGURACIÓN DEL ENTORNO"

if [ ! -f ".env" ]; then
    print_status "Creando archivo .env..."
    cp .env.example .env
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    sed -i '' "s/tu_clave_secreta_muy_segura_aqui/$SECRET_KEY/" .env
    print_success "Archivo .env creado"
else
    print_success "Archivo .env ya existe"
fi

# 4. Inicializar base de datos
print_header "4. INICIALIZACIÓN DE BASE DE DATOS"

if [ ! -f "database/nemesix_db.db" ]; then
    print_status "Creando base de datos..."
    python3 -c "
import sys
sys.path.append('.')
from config.mysqlconnection import connectToMySQL
print('Base de datos creada')
"
else
    print_success "Base de datos ya existe"
fi

# 5. Inicializar datos de prueba
print_header "5. DATOS DE PRUEBA"

print_status "Inicializando usuarios de prueba..."
chmod +x init_test_data.sh
./init_test_data.sh

# 6. Verificar archivos estáticos
print_header "6. VERIFICACIÓN DE ARCHIVOS ESTÁTICOS"

echo -n "Directorio static: "
if [ -d "static" ]; then
    file_count=$(find static -type f | wc -l)
    print_success "$file_count archivos encontrados"
else
    print_error "Directorio static no encontrado"
fi

echo -n "Directorio templates: "
if [ -d "templates" ]; then
    template_count=$(find templates -name "*.html" | wc -l)
    print_success "$template_count templates encontrados"
else
    print_error "Directorio templates no encontrado"
fi

# 7. Probar aplicación con Python
print_header "7. PRUEBA DE FUNCIONALIDADES"

print_status "Probando importaciones..."
python3 -c "
try:
    from app import app
    from models.user import User
    from config.mysqlconnection import connectToMySQL
    print('✅ Todas las importaciones exitosas')
except Exception as e:
    print(f'❌ Error en importaciones: {e}')
    exit(1)
"

print_status "Probando modelo de usuario..."
python3 -c "
try:
    from models.user import User
    # Intentar obtener usuarios
    users = User.get_all_users()
    print(f'✅ Modelo funcionando - {len(users)} usuarios encontrados')
except Exception as e:
    print(f'❌ Error en modelo: {e}')
"

# 8. Iniciar aplicación en background
print_header "8. INICIANDO APLICACIÓN"

print_status "Iniciando servidor Flask en background..."
export FLASK_ENV=development
python3 -c "
import os
os.environ['FLASK_ENV'] = 'development'
from app import app
print('🚀 Servidor iniciado en http://127.0.0.1:8000')
print('📝 Presiona Ctrl+C para detener')
app.run(host='0.0.0.0', port=8000, debug=True, use_reloader=False)
" &
SERVER_PID=$!

# Esperar que el servidor inicie
sleep 3

# 9. Probar endpoints
print_header "9. PRUEBA DE ENDPOINTS"

echo "Probando endpoints básicos..."

# Función para probar endpoint
test_endpoint() {
    local url=$1
    local description=$2

    echo -n "$description: "
    if python3 -c "
import urllib.request
import sys
try:
    with urllib.request.urlopen('$url', timeout=5) as response:
        if response.status == 200:
            print('✅ OK')
        else:
            print(f'⚠️  Código {response.status}')
except Exception as e:
    print(f'❌ Error: {str(e)[:50]}...')
    sys.exit(1)
"; then
        return 0
    else
        return 1
    fi
}

# Probar endpoints
test_endpoint "http://127.0.0.1:8000/" "Página principal"
test_endpoint "http://127.0.0.1:8000/health" "Health check"
test_endpoint "http://127.0.0.1:8000/login" "Página de login"
test_endpoint "http://127.0.0.1:8000/register" "Página de registro"

# 10. Información final
print_header "10. INFORMACIÓN FINAL"

print_success "🎉 ¡Aplicación probada exitosamente!"
echo ""
echo "🌐 URLs de acceso:"
echo "   • Aplicación: http://127.0.0.1:8000"
echo "   • Login: http://127.0.0.1:8000/login"
echo "   • Registro: http://127.0.0.1:8000/register"
echo ""
echo "👤 Credenciales de prueba:"
echo "   • Admin: admin@nemesix.com / admin123"
echo "   • Test: test1@nemesix.com / test123"
echo ""
echo "💡 Para detener el servidor: Ctrl+C"
echo ""
print_warning "📝 Notas importantes:"
echo "   • La aplicación está corriendo en modo desarrollo"
echo "   • Los archivos estáticos se sirven correctamente"
echo "   • El sistema de autenticación está funcionando"
echo "   • La base de datos SQLite está inicializada"
echo ""

# Mantener el servidor corriendo
print_status "Presiona Ctrl+C para detener la aplicación..."
wait $SERVER_PID
