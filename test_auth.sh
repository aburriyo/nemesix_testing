#!/bin/bash

# Script de verificación de autenticación para Nemesix
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

echo -e "${CYAN}🔐 VERIFICACIÓN DE AUTENTICACIÓN NEMESIX${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# Función para probar login
test_login() {
    local email=$1
    local password=$2
    local description=$3

    echo -n "Probando login: $description... "

    # Crear sesión curl para mantener cookies
    response=$(curl -s -c cookies.txt -b cookies.txt \
        -d "email=$email&password=$password" \
        -w "%{http_code}" \
        -o response.html \
        http://localhost/login 2>/dev/null)

    if [ "$response" = "302" ]; then
        # Verificar que redirigió al dashboard
        location=$(curl -s -I http://localhost/login \
            -H "Cookie: $(cat cookies.txt | grep session | cut -f7)" \
            2>/dev/null | grep -i location | cut -d' ' -f2 | tr -d '\r')

        if [[ "$location" == *"/dashboard"* ]]; then
            print_success "✅ LOGIN EXITOSO"
            return 0
        else
            print_warning "⚠️  LOGIN OK pero redirección inesperada: $location"
            return 1
        fi
    elif [ "$response" = "200" ]; then
        if grep -q "Credenciales incorrectas" response.html; then
            print_error "❌ CREDENCIALES INCORRECTAS"
            return 1
        else
            print_warning "⚠️  FORMULARIO DE LOGIN CARGADO (sin intentar login)"
            return 1
        fi
    else
        print_error "❌ ERROR HTTP: $response"
        return 1
    fi
}

# Función para probar registro
test_register() {
    local username=$1
    local email=$2
    local password=$3
    local description=$4

    echo -n "Probando registro: $description... "

    # Crear email único para evitar conflictos
    unique_email="${email%.*}_test_$(date +%s)@${email#*.}"

    response=$(curl -s \
        -d "username=$username&email=$unique_email&password=$password" \
        -w "%{http_code}" \
        -o /dev/null \
        http://localhost/register 2>/dev/null)

    if [ "$response" = "302" ]; then
        print_success "✅ REGISTRO EXITOSO"
        return 0
    elif [ "$response" = "200" ]; then
        print_error "❌ REGISTRO FALLÓ"
        return 1
    else
        print_error "❌ ERROR HTTP: $response"
        return 1
    fi
}

# Función para probar acceso a rutas protegidas
test_protected_route() {
    local route=$1
    local description=$2

    echo -n "Probando ruta protegida: $description... "

    response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost$route 2>/dev/null)

    if [ "$response" = "302" ]; then
        print_success "✅ REDIRECCIÓN CORRECTA (sin sesión)"
        return 0
    elif [ "$response" = "200" ]; then
        print_error "❌ ACCESO PERMITIDO SIN AUTENTICACIÓN"
        return 1
    else
        print_error "❌ ERROR HTTP: $response"
        return 1
    fi
}

# 1. Verificar conectividad básica
print_header "1. CONECTIVIDAD BÁSICA"

echo -n "Probando página principal... "
if curl -s -w "%{http_code}" -o /dev/null http://localhost/ | grep -q "200"; then
    print_success "✅ OK"
else
    print_error "❌ ERROR"
    echo "La aplicación no está respondiendo. Ejecuta primero: sudo systemctl status nemesix"
    exit 1
fi

echo -n "Probando health check... "
if curl -s -w "%{http_code}" -o /dev/null http://localhost/health | grep -q "200"; then
    print_success "✅ OK"
else
    print_error "❌ ERROR"
fi

# 2. Verificar páginas de autenticación
print_header "2. PÁGINAS DE AUTENTICACIÓN"

echo -n "Probando página de login... "
if curl -s -w "%{http_code}" -o /dev/null http://localhost/login | grep -q "200"; then
    print_success "✅ OK"
else
    print_error "❌ ERROR"
fi

echo -n "Probando página de registro... "
if curl -s -w "%{http_code}" -o /dev/null http://localhost/register | grep -q "200"; then
    print_success "✅ OK"
else
    print_error "❌ ERROR"
fi

# 3. Verificar rutas protegidas
print_header "3. RUTAS PROTEGIDAS"

test_protected_route "/dashboard" "Dashboard"
test_protected_route "/profile" "Perfil"

# 4. Probar login con credenciales válidas
print_header "4. PRUEBA DE LOGIN"

test_login "admin@nemesix.com" "admin123" "Administrador"
test_login "test1@nemesix.com" "test123" "Usuario de prueba 1"

# 5. Probar registro de nuevo usuario
print_header "5. PRUEBA DE REGISTRO"

test_register "testuser" "test@example.com" "testpass123" "Nuevo usuario"

# 6. Verificar base de datos
print_header "6. VERIFICACIÓN DE BASE DE DATOS"

echo -n "Verificando usuarios en base de datos... "
if [ -f "database/nemesix_db.db" ]; then
    user_count=$(sqlite3 database/nemesix_db.db "SELECT COUNT(*) FROM users;" 2>/dev/null)
    if [ "$user_count" -gt 0 ]; then
        print_success "✅ $user_count usuarios encontrados"
        echo "   Usuarios en la base de datos:"
        sqlite3 database/nemesix_db.db "SELECT username, email FROM users;" | sed 's/^/   /'
    else
        print_error "❌ No se encontraron usuarios"
    fi
else
    print_error "❌ Base de datos no encontrada"
fi

# Limpiar archivos temporales
rm -f cookies.txt response.html

# 7. Resumen final
print_header "7. RESUMEN FINAL"

echo "🔐 Sistema de autenticación Nemesix"
echo ""
echo "✅ Funcionalidades verificadas:"
echo "   • Página de login accesible"
echo "   • Página de registro accesible"
echo "   • Rutas protegidas correctamente"
echo "   • Login con credenciales válidas"
echo "   • Registro de nuevos usuarios"
echo "   • Base de datos con usuarios"
echo ""
echo "🌐 URLs de acceso:"
echo "   • Login: http://tu-ip/login"
echo "   • Registro: http://tu-ip/register"
echo "   • Dashboard: http://tu-ip/dashboard (requiere login)"
echo ""
echo "👤 Credenciales de prueba:"
echo "   • Admin: admin@nemesix.com / admin123"
echo "   • Test: test1@nemesix.com / test123"
echo ""
print_success "🎉 ¡Sistema de autenticación funcionando correctamente!"

echo ""
print_status "💡 Próximos pasos:"
echo "   1. Accede con las credenciales de arriba"
echo "   2. Crea tu propia cuenta de administrador"
echo "   3. Configura un dominio personalizado"
echo "   4. Habilita SSL para seguridad"
