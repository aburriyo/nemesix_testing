#!/bin/bash

# Script de diagnóstico completo para Nemesix - Error 502 Bad Gateway
# Versión: 2.0 - Optimizado para diagnóstico de Bad Gateway
# Fecha: 28 de agosto de 2025

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para imprimir mensajes coloreados
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

print_info() {
    echo -e "${CYAN}[DETAIL]${NC} $1"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar conectividad
check_connectivity() {
    local host=$1
    local port=$2
    local timeout=${3:-5}

    if command_exists nc; then
        if nc -z -w$timeout $host $port >/dev/null 2>&1; then
            return 0
        fi
    elif command_exists timeout && command_exists bash; then
        if timeout $timeout bash -c "echo >/dev/tcp/$host/$port" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

echo -e "${CYAN}🔍 DIAGNÓSTICO COMPLETO DE NEMESIX - ERROR 502 BAD GATEWAY${NC}"
echo -e "${CYAN}================================================================${NC}"
echo "Fecha: $(date)"
echo "Usuario: $(whoami)"
echo "Directorio: $(pwd)"
echo ""

# 1. Verificar servicios systemd
print_header "1. VERIFICACIÓN DE SERVICIOS SYSTEMD"

SERVICES=("nemesix" "nginx")
for service in "${SERVICES[@]}"; do
    echo -n "Servicio $service: "
    if systemctl is-active --quiet $service; then
        print_success "ACTIVO"
        echo "   Estado detallado:"
        systemctl status $service --no-pager -l | head -10 | sed 's/^/   /'
    else
        print_error "INACTIVO"
        echo "   Intentando obtener detalles del error:"
        systemctl status $service --no-pager -l 2>/dev/null | head -10 | sed 's/^/   /' || echo "   No se pudo obtener información"
    fi
    echo ""
done

# 2. Verificar procesos
print_header "2. VERIFICACIÓN DE PROCESOS"

echo "Procesos relacionados con Nemesix:"
ps aux | grep -E "(gunicorn|nemesix|flask)" | grep -v grep | sed 's/^/   /' || print_warning "No se encontraron procesos relacionados"

echo ""
echo "Procesos de Nginx:"
ps aux | grep nginx | grep -v grep | sed 's/^/   /' || print_warning "No se encontraron procesos de Nginx"

# 3. Verificar puertos
print_header "3. VERIFICACIÓN DE PUERTOS"

echo "Puertos TCP abiertos:"
if command_exists netstat; then
    netstat -tlnp 2>/dev/null | grep -E ":(80|8080|443)" | sed 's/^/   /' || print_warning "No se encontraron puertos relevantes"
elif command_exists ss; then
    ss -tlnp | grep -E ":(80|8080|443)" | sed 's/^/   /' || print_warning "No se encontraron puertos relevantes"
else
    print_warning "No se pudo verificar puertos (netstat/ss no disponibles)"
fi

echo ""
echo "Verificando conectividad local:"
echo -n "Puerto 8080 (Gunicorn): "
if check_connectivity localhost 8080; then
    print_success "CONECTADO"
else
    print_error "NO CONECTADO - ¡ESTE ES EL PROBLEMA!"
fi

echo -n "Puerto 80 (Nginx): "
if check_connectivity localhost 80; then
    print_success "CONECTADO"
else
    print_error "NO CONECTADO"
fi

# 4. Verificar archivos de configuración
print_header "4. VERIFICACIÓN DE ARCHIVOS DE CONFIGURACIÓN"

CONFIG_FILES=(
    "/etc/nginx/sites-available/nemesix"
    "/etc/systemd/system/nemesix.service"
    "/var/www/nemesix/app.py"
    "/var/www/nemesix/gunicorn_config.py"
)

for config_file in "${CONFIG_FILES[@]}"; do
    echo -n "Archivo $config_file: "
    if [ -f "$config_file" ]; then
        print_success "EXISTE"
        echo "   Permisos: $(ls -la $config_file | awk '{print $1}')"
        echo "   Propietario: $(ls -la $config_file | awk '{print $3 ":" $4}')"
    else
        print_error "NO EXISTE"
    fi
    echo ""
done

# 5. Verificar configuración de Nginx
print_header "5. VERIFICACIÓN DE NGINX"

echo "Probando configuración de Nginx:"
if command_exists nginx; then
    nginx -t 2>&1 | sed 's/^/   /' || print_error "Configuración de Nginx inválida"
else
    print_error "Nginx no está instalado"
fi

echo ""
echo "Configuración de sitio Nemesix:"
if [ -f "/etc/nginx/sites-available/nemesix" ]; then
    echo "   Contenido del archivo de configuración:"
    cat /etc/nginx/sites-available/nemesix | sed 's/^/   /'
else
    print_error "Archivo de configuración no encontrado"
fi

# 6. Verificar logs
print_header "6. VERIFICACIÓN DE LOGS"

LOG_FILES=(
    "/var/log/nginx/nemesix_error.log"
    "/var/log/nginx/nemesix_access.log"
    "/var/log/nginx/error.log"
)

for log_file in "${LOG_FILES[@]}"; do
    echo "Logs en $log_file:"
    if [ -f "$log_file" ]; then
        if [ -s "$log_file" ]; then
            echo "   Últimas 10 líneas:"
            tail -10 $log_file | sed 's/^/   /'
        else
            print_info "Archivo existe pero está vacío"
        fi
    else
        print_warning "Archivo de log no existe"
    fi
    echo ""
done

# 7. Verificar logs de systemd
print_header "7. LOGS DE SYSTEMD"

echo "Logs del servicio Nemesix (últimas 20 líneas):"
journalctl -u nemesix --no-pager -n 20 2>/dev/null | sed 's/^/   /' || print_warning "No se pudieron obtener logs de systemd"

# 8. Verificar permisos y directorios
print_header "8. VERIFICACIÓN DE PERMISOS Y DIRECTORIOS"

DIRECTORIES=(
    "/var/www/nemesix"
    "/var/www/nemesix/static"
    "/var/www/nemesix/templates"
    "/var/www/nemesix/logs"
)

for dir in "${DIRECTORIES[@]}"; do
    echo -n "Directorio $dir: "
    if [ -d "$dir" ]; then
        print_success "EXISTE"
        echo "   Permisos: $(ls -ld $dir | awk '{print $1}')"
        echo "   Propietario: $(ls -ld $dir | awk '{print $3 ":" $4}')"
    else
        print_error "NO EXISTE"
    fi
    echo ""
done

# 9. Verificar conectividad HTTP
print_header "9. VERIFICACIÓN DE CONECTIVIDAD HTTP"

echo "Probando endpoints locales:"
ENDPOINTS=(
    "http://localhost:8080/"
    "http://localhost:8080/health"
    "http://localhost/"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo -n "Endpoint $endpoint: "
    if command_exists curl; then
        response=$(curl -s -o /dev/null -w "%{http_code}" $endpoint 2>/dev/null)
        if [ "$response" = "200" ]; then
            print_success "OK (200)"
        elif [ "$response" = "502" ]; then
            print_error "BAD GATEWAY (502) - ¡PROBLEMA CONFIRMADO!"
        elif [ "$response" = "404" ]; then
            print_warning "NOT FOUND (404)"
        elif [ "$response" = "000" ]; then
            print_error "CONEXIÓN FALLIDA"
        else
            print_warning "CÓDIGO HTTP: $response"
        fi
    else
        print_warning "curl no disponible"
    fi
    echo ""
done

# 10. Verificar firewall
print_header "10. VERIFICACIÓN DE FIREWALL"

if command_exists ufw; then
    echo "Estado de UFW:"
    ufw status | sed 's/^/   /'
elif command_exists firewall-cmd; then
    echo "Estado de firewalld:"
    firewall-cmd --state 2>/dev/null | sed 's/^/   /' || print_warning "firewalld no activo"
else
    print_warning "No se detectó firewall gestionable"
fi

# 11. Verificar recursos del sistema
print_header "11. VERIFICACIÓN DE RECURSOS DEL SISTEMA"

echo "Memoria disponible:"
free -h | sed 's/^/   /'

echo ""
echo "Espacio en disco:"
df -h /var/www | sed 's/^/   /'

# 12. Análisis específico del error 502
print_header "12. ANÁLISIS ESPECÍFICO DEL ERROR 502"

echo "🔍 Analizando posibles causas del Bad Gateway:"
echo ""

# Verificar si Gunicorn está corriendo
if ! check_connectivity localhost 8080; then
    print_error "❌ CAUSA IDENTIFICADA: Gunicorn no está escuchando en el puerto 8080"
    echo "   Esto significa que el backend de Flask no está funcionando"
    echo ""
fi

# Verificar configuración de Nginx
if [ -f "/etc/nginx/sites-available/nemesix" ]; then
    if grep -q "proxy_pass.*8080" /etc/nginx/sites-available/nemesix; then
        print_success "✅ Configuración de proxy_pass parece correcta"
    else
        print_error "❌ Configuración de proxy_pass incorrecta en Nginx"
    fi
else
    print_error "❌ Archivo de configuración de Nginx no encontrado"
fi

# Verificar si el servicio está activo
if ! systemctl is-active --quiet nemesix; then
    print_error "❌ CAUSA IDENTIFICADA: Servicio Nemesix no está activo"
    echo "   El servicio systemd no pudo iniciar correctamente"
    echo ""
fi

# 13. Recomendaciones específicas para 502
print_header "13. RECOMENDACIONES PARA SOLUCIONAR BAD GATEWAY"

echo "🔧 SOLUCIONES RECOMENDADAS (en orden de prioridad):"
echo ""

if ! systemctl is-active --quiet nemesix; then
    print_error "1. El servicio Nemesix no está activo - SOLUCIÓN PRIORITARIA:"
    echo "   sudo systemctl start nemesix"
    echo "   sudo systemctl status nemesix"
    echo "   sudo journalctl -u nemesix -f"
    echo ""
fi

if ! check_connectivity localhost 8080; then
    print_error "2. Gunicorn no está escuchando - SOLUCIÓN:"
    echo "   # Verificar si el proceso está corriendo"
    echo "   ps aux | grep gunicorn"
    echo "   "
    echo "   # Intentar iniciar manualmente"
    echo "   cd /var/www/nemesix"
    echo "   source venv/bin/activate"
    echo "   gunicorn --config gunicorn_config.py app:app"
    echo "   "
    echo "   # Si funciona manualmente, revisar configuración de systemd"
    echo "   sudo systemctl daemon-reload"
    echo "   sudo systemctl restart nemesix"
    echo ""
fi

print_warning "3. Verificar configuración de Nginx:"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo ""

print_warning "4. Verificar logs detallados:"
echo "   sudo journalctl -u nemesix -f"
echo "   sudo tail -f /var/log/nginx/nemesix_error.log"
echo ""

print_success "✅ Diagnóstico completado"
echo ""
echo "� Comandos útiles para solucionar problemas:"
echo "   Reiniciar todo: sudo systemctl restart nemesix nginx"
echo "   Ver logs en tiempo real: sudo journalctl -u nemesix -f"
echo "   Probar conectividad: curl http://localhost:8080/health"
echo "   Ver estado completo: sudo systemctl status nemesix"
echo ""
echo "� Comparte la salida de este script para ayuda adicional."
