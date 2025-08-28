#!/bin/bash

# Script de solución rápida para Error 502 Bad Gateway
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

echo -e "${CYAN}🔧 SOLUCIÓN RÁPIDA PARA ERROR 502 BAD GATEWAY${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# Función para verificar conectividad
check_connectivity() {
    local host=$1
    local port=$2
    local timeout=${3:-5}

    if command -v nc >/dev/null 2>&1; then
        if nc -z -w$timeout $host $port >/dev/null 2>&1; then
            return 0
        fi
    elif command -v timeout >/dev/null 2>&1 && command -v bash >/dev/null 2>&1; then
        if timeout $timeout bash -c "echo >/dev/tcp/$host/$port" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# 1. Verificar estado actual
print_header "1. VERIFICACIÓN DEL ESTADO ACTUAL"

echo "Verificando servicios..."
echo -n "Servicio Nemesix: "
if systemctl is-active --quiet nemesix; then
    print_success "ACTIVO"
else
    print_error "INACTIVO"
fi

echo -n "Servicio Nginx: "
if systemctl is-active --quiet nginx; then
    print_success "ACTIVO"
else
    print_error "INACTIVO"
fi

echo -n "Puerto 8080 (Gunicorn): "
if check_connectivity localhost 8080; then
    print_success "CONECTADO"
else
    print_error "NO CONECTADO"
fi

# 2. Solución 1: Reiniciar servicios
print_header "2. SOLUCIÓN 1: REINICIAR SERVICIOS"

print_status "Reiniciando servicios en orden correcto..."

echo "1. Deteniendo servicios..."
sudo systemctl stop nemesix 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

echo "2. Iniciando Gunicorn (Nemesix)..."
sudo systemctl start nemesix
sleep 3

echo "3. Iniciando Nginx..."
sudo systemctl start nginx
sleep 2

# Verificar si funcionó
echo -n "Verificando puerto 8080: "
if check_connectivity localhost 8080; then
    print_success "¡CONECTADO! Solución 1 funcionó"
else
    print_error "Aún no conectado, intentando siguiente solución..."
fi

# 3. Solución 2: Verificar y corregir configuración
print_header "3. SOLUCIÓN 2: VERIFICAR CONFIGURACIÓN"

# Verificar configuración de Nginx
print_status "Verificando configuración de Nginx..."
if sudo nginx -t >/dev/null 2>&1; then
    print_success "Configuración de Nginx es válida"
else
    print_error "Configuración de Nginx inválida"
    sudo nginx -t
    exit 1
fi

# Verificar archivo de configuración del sitio
if [ -f "/etc/nginx/sites-available/nemesix" ]; then
    print_success "Archivo de configuración existe"
else
    print_error "Archivo de configuración no existe"
    exit 1
fi

# Verificar enlace simbólico
if [ -L "/etc/nginx/sites-enabled/nemesix" ]; then
    print_success "Enlace simbólico existe"
else
    print_warning "Creando enlace simbólico..."
    sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/
    sudo systemctl reload nginx
fi

# 4. Solución 3: Reiniciar con daemon-reload
print_header "4. SOLUCIÓN 3: RECARGAR SYSTEMD"

print_status "Recargando configuración de systemd..."
sudo systemctl daemon-reload

print_status "Reiniciando servicios con configuración actualizada..."
sudo systemctl restart nemesix
sleep 3
sudo systemctl restart nginx

# Verificar nuevamente
echo -n "Verificación final del puerto 8080: "
if check_connectivity localhost 8080; then
    print_success "¡PROBLEMA RESUELTO!"
else
    print_error "El problema persiste, revisando logs..."
fi

# 5. Solución 4: Verificar logs y dar recomendaciones
print_header "5. VERIFICACIÓN DE LOGS Y RECOMENDACIONES"

# Verificar logs de systemd
echo "Últimas líneas del log de Nemesix:"
sudo journalctl -u nemesix --no-pager -n 5 | sed 's/^/   /' || print_warning "No se pudieron obtener logs"

echo ""
echo "Últimas líneas del log de Nginx:"
sudo tail -5 /var/log/nginx/nemesix_error.log 2>/dev/null | sed 's/^/   /' || print_warning "No se pudieron obtener logs de Nginx"

# 6. Prueba final
print_header "6. PRUEBA FINAL"

echo "Probando conectividad HTTP:"
if command -v curl >/dev/null 2>&1; then
    echo -n "Endpoint principal: "
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
    if [ "$response" = "200" ]; then
        print_success "OK (200) - ¡TODO FUNCIONANDO!"
    elif [ "$response" = "502" ]; then
        print_error "AÚN ERROR 502 - Necesitas ayuda adicional"
    else
        print_warning "Código HTTP: $response"
    fi

    echo -n "Health check: "
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null)
    if [ "$response" = "200" ]; then
        print_success "OK (200)"
    else
        print_warning "Código HTTP: $response"
    fi
else
    print_warning "curl no disponible para pruebas HTTP"
fi

# 7. Recomendaciones finales
print_header "7. RECOMENDACIONES FINALES"

if check_connectivity localhost 8080 && systemctl is-active --quiet nemesix && systemctl is-active --quiet nginx; then
    print_success "🎉 ¡PROBLEMA RESUELTO EXITOSAMENTE!"
    echo ""
    echo "Tu aplicación Nemesix debería estar funcionando correctamente."
    echo "Accede a: http://tu-ip-del-droplet"
else
    print_error "❌ El problema no se pudo resolver automáticamente"
    echo ""
    echo "🔧 Pasos manuales recomendados:"
    echo "1. Ejecuta el diagnóstico completo: ./diagnose.sh"
    echo "2. Revisa los logs detallados: sudo journalctl -u nemesix -f"
    echo "3. Verifica la configuración de Gunicorn"
    echo "4. Comprueba los permisos de archivos"
    echo ""
    echo "💡 Si necesitas ayuda adicional, comparte la salida del diagnóstico."
fi

echo ""
print_status "Comandos útiles para monitoreo:"
echo "   Ver estado: sudo systemctl status nemesix"
echo "   Ver logs: sudo journalctl -u nemesix -f"
echo "   Reiniciar: sudo systemctl restart nemesix nginx"
echo "   Probar: curl http://localhost/health"
