#!/bin/bash

# Script para eliminar configuraciones conflictivas de Nginx
# Fecha: 28 de agosto de 2025

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "�� ELIMINANDO CONFIGURACIONES CONFLICTIVAS DE NGINX"
echo "=================================================="

# 1. Verificar configuraciones activas
print_status "Verificando configuraciones activas de Nginx..."

echo "Configuraciones activas:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "Contenido de configuraciones activas:"
for config in /etc/nginx/sites-enabled/*; do
    if [ -f "$config" ]; then
        echo "=== $(basename $config) ==="
        cat "$config" | head -20
        echo ""
    fi
done

# 2. Buscar configuraciones que usen socket Unix
print_status "Buscando configuraciones con socket Unix..."

SOCKET_CONFIGS=$(grep -r "unix:/root/myapp/myapp.sock" /etc/nginx/sites-enabled/ 2>/dev/null || true)

if [ -n "$SOCKET_CONFIGS" ]; then
    print_error "¡ENCONTRADAS CONFIGURACIONES CONFLICTIVAS!"
    echo "$SOCKET_CONFIGS"
    echo ""
    
    # 3. Eliminar configuraciones conflictivas
    print_status "Eliminando configuraciones conflictivas..."
    
    # Buscar archivos que contengan la configuración problemática
    for config_file in /etc/nginx/sites-enabled/*; do
        if [ -f "$config_file" ] && grep -q "unix:/root/myapp/myapp.sock" "$config_file"; then
            print_warning "Eliminando configuración conflictiva: $(basename $config_file)"
            sudo rm -f "$config_file"
        fi
    done
    
    # También buscar en sites-available
    for config_file in /etc/nginx/sites-available/*; do
        if [ -f "$config_file" ] && grep -q "unix:/root/myapp/myapp.sock" "$config_file"; then
            print_warning "Eliminando configuración conflictiva: $(basename $config_file)"
            sudo rm -f "$config_file"
        fi
    done
    
else
    print_success "No se encontraron configuraciones con socket Unix"
fi

# 4. Verificar que solo quede la configuración correcta
print_status "Verificando configuraciones restantes..."

if [ -L /etc/nginx/sites-enabled/nemesix ]; then
    print_success "Configuración nemesix está activa"
else
    print_error "Configuración nemesix no está activa"
    print_status "Reactivando configuración nemesix..."
    sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/
fi

# 5. Verificar configuración por defecto
print_status "Verificando configuración por defecto..."

if [ -L /etc/nginx/sites-enabled/default ]; then
    print_warning "Configuración por defecto aún existe - eliminándola..."
    sudo rm -f /etc/nginx/sites-enabled/default
else
    print_success "Configuración por defecto ya eliminada"
fi

# 6. Probar configuración
print_status "Probando configuración de Nginx..."
if sudo nginx -t; then
    print_success "Configuración de Nginx correcta"
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

# 7. Reiniciar Nginx
print_status "Reiniciando Nginx..."
sudo systemctl reload nginx

# 8. Verificar estado
print_status "Verificando estado de Nginx..."
sleep 2

if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx funcionando correctamente"
else
    print_error "Nginx no está activo"
    exit 1
fi

# 9. Probar conectividad
print_status "Probando conectividad...")
sleep 1

echo -n "Backend (puerto 8080): "
if curl -s http://localhost:8080/health > /dev/null; then
    echo -e "${GREEN}✅ FUNCIONANDO${NC}"
else
    echo -e "${RED}❌ NO RESPONDE${NC}"
fi

echo -n "Frontend (puerto 80): "
if curl -s http://localhost/health > /dev/null; then
    echo -e "${GREEN}✅ FUNCIONANDO${NC}"
else
    echo -e "${RED}❌ ERROR 502${NC}"
fi

# 10. Verificar logs
print_status "Verificando logs de Nginx..."
sleep 1

if [ -f /var/log/nginx/nemesix_error.log ]; then
    LAST_ERRORS=$(tail -5 /var/log/nginx/nemesix_error.log 2>/dev/null | grep -i "unix:/root/myapp" || true)
    if [ -n "$LAST_ERRORS" ]; then
        print_error "Aún hay errores de socket Unix en los logs:"
        echo "$LAST_ERRORS"
    else
        print_success "No hay errores de socket Unix en los logs recientes"
    fi
fi

print_success "✅ Limpieza completada"
echo ""
echo "🔧 Si aún tienes problemas, ejecuta:"
echo "   sudo ./diagnose.sh"
echo ""
echo "📋 Resumen de cambios:"
echo "   - Eliminadas configuraciones con socket Unix conflictivas"
echo "   - Verificada configuración nemesix correcta"
echo "   - Reiniciado Nginx"
echo "   - Probada conectividad"

