#!/bin/bash

# Script COMPLETO para eliminar TODAS las configuraciones conflictivas de Nginx
# Fecha: 28 de agosto de 2025

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}[DETAIL]${NC} $1"
}

echo "🔧 LIMPIEZA COMPLETA DE CONFIGURACIONES CONFLICTIVAS DE NGINX"
echo "============================================================"

# 1. Buscar TODAS las referencias al socket Unix en el sistema
print_status "Buscando TODAS las referencias al socket Unix en el sistema..."

echo "Archivos que contienen referencias al socket Unix:"
SOCKET_FILES=$(find /etc/nginx -type f -exec grep -l "unix:/root/myapp/myapp.sock" {} \; 2>/dev/null || true)

if [ -n "$SOCKET_FILES" ]; then
    print_error "¡ENCONTRADOS ARCHIVOS CON SOCKET UNIX!"
    echo "$SOCKET_FILES" | sed 's/^/   /'
    echo ""
else
    print_success "No se encontraron archivos con socket Unix en /etc/nginx"
fi

# 2. Buscar en todo el sistema de archivos
print_status "Buscando en todo el sistema de archivos..."
SYSTEM_SOCKET_FILES=$(find /etc -name "*.conf" -exec grep -l "unix:/root/myapp/myapp.sock" {} \; 2>/dev/null || true)

if [ -n "$SYSTEM_SOCKET_FILES" ]; then
    print_error "¡ENCONTRADOS ARCHIVOS CON SOCKET UNIX EN TODO EL SISTEMA!"
    echo "$SYSTEM_SOCKET_FILES" | sed 's/^/   /'
    echo ""
fi

# 3. Verificar configuraciones activas actuales
print_status "Verificando configuraciones activas actuales..."
echo "Configuraciones en sites-enabled:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "Contenido de todas las configuraciones activas:"
for config in /etc/nginx/sites-enabled/*; do
    if [ -f "$config" ]; then
        echo "=== $(basename $config) ==="
        if grep -q "unix:/root/myapp/myapp.sock" "$config" 2>/dev/null; then
            print_error "¡CONFIGURACIÓN CONFLICTIVA ENCONTRADA!"
            cat "$config" | sed 's/^/   /'
        else
            print_success "Configuración parece correcta"
            head -10 "$config" | sed 's/^/   /'
        fi
        echo ""
    fi
done

# 4. Backup de configuraciones actuales
print_status "Creando backup de configuraciones actuales..."
BACKUP_DIR="/tmp/nginx_backup_$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p $BACKUP_DIR
sudo cp -r /etc/nginx/sites-available $BACKUP_DIR/
sudo cp -r /etc/nginx/sites-enabled $BACKUP_DIR/
print_success "Backup creado en: $BACKUP_DIR"

# 5. Eliminar TODAS las configuraciones conflictivas
print_status "Eliminando TODAS las configuraciones conflictivas..."

# Eliminar enlaces simbólicos conflictivos
for config in /etc/nginx/sites-enabled/*; do
    if [ -f "$config" ] && grep -q "unix:/root/myapp/myapp.sock" "$config" 2>/dev/null; then
        print_warning "Eliminando enlace simbólico conflictivo: $(basename $config)"
        sudo rm -f "$config"
    fi
done

# Eliminar archivos de configuración conflictivos
for config in /etc/nginx/sites-available/*; do
    if [ -f "$config" ] && grep -q "unix:/root/myapp/myapp.sock" "$config" 2>/dev/null; then
        print_warning "Eliminando archivo de configuración conflictivo: $(basename $config)"
        sudo rm -f "$config"
    fi
done

# 6. Verificar que la configuración correcta existe
print_status "Verificando configuración nemesix correcta..."

if [ ! -f /etc/nginx/sites-available/nemesix ]; then
    print_error "Configuración nemesix no existe, recreándola..."
    sudo tee /etc/nginx/sites-available/nemesix > /dev/null << 'NGINX_CONFIG'
# Configuración de Nginx para Nemesix - Ubuntu Server
# Ubicación: /etc/nginx/sites-available/nemesix

server {
    listen 80;
    server_name _;  # Acepta cualquier nombre de dominio
    
    # Logs
    access_log /var/log/nginx/nemesix_access.log;
    error_log /var/log/nginx/nemesix_error.log;
    
    # Configuración de archivos estáticos
    location /static {
        alias /var/www/nemesix/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Configuración del proxy para la aplicación Flask
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Configuración de timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Configuración de buffers
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Configuración de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
NGINX_CONFIG
else
    print_success "Configuración nemesix existe"
fi

# 7. Crear enlace simbólico correcto
print_status "Creando enlace simbólico correcto..."
if [ ! -L /etc/nginx/sites-enabled/nemesix ]; then
    sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/
    print_success "Enlace simbólico creado"
else
    print_success "Enlace simbólico ya existe"
fi

# 8. Eliminar configuración por defecto
if [ -L /etc/nginx/sites-enabled/default ]; then
    print_warning "Eliminando configuración por defecto..."
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# 9. Verificar configuración final
print_status "Verificando configuración final..."
echo "Configuraciones activas finales:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "Contenido de configuración nemesix:"
if [ -f /etc/nginx/sites-enabled/nemesix ]; then
    cat /etc/nginx/sites-enabled/nemesix | sed 's/^/   /'
else
    print_error "Configuración nemesix no encontrada"
fi

# 10. Probar configuración
print_status "Probando configuración de Nginx..."
if sudo nginx -t; then
    print_success "Configuración de Nginx correcta"
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

# 11. Reiniciar servicios completamente
print_status "Reiniciando servicios completamente..."
sudo systemctl stop nginx
sudo systemctl stop nemesix
sleep 2
sudo systemctl start nemesix
sleep 2
sudo systemctl start nginx

# 12. Verificar estado de servicios
print_status "Verificando estado de servicios..."
sleep 3

if sudo systemctl is-active --quiet nemesix; then
    print_success "Servicio Nemesix activo"
else
    print_error "Servicio Nemesix no está activo"
    sudo systemctl status nemesix
    exit 1
fi

if sudo systemctl is-active --quiet nginx; then
    print_success "Servicio Nginx activo"
else
    print_error "Servicio Nginx no está activo"
    sudo systemctl status nginx
    exit 1
fi

# 13. Probar conectividad
print_status "Probando conectividad...")
sleep 2

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

# 14. Verificar logs finales
print_status "Verificando logs finales..."
sleep 1

if [ -f /var/log/nginx/nemesix_error.log ]; then
    LAST_ERRORS=$(tail -3 /var/log/nginx/nemesix_error.log 2>/dev/null | grep -i "unix:/root/myapp" || true)
    if [ -n "$LAST_ERRORS" ]; then
        print_error "Aún hay errores de socket Unix:"
        echo "$LAST_ERRORS"
    else
        print_success "No hay errores de socket Unix en logs recientes"
    fi
fi

# 15. Verificación final de procesos
print_status "Verificación final de procesos..."
echo "Procesos de Nginx:"
ps aux | grep nginx | grep -v grep | sed 's/^/   /'

echo ""
echo "Procesos de Gunicorn:"
ps aux | grep gunicorn | grep -v grep | sed 's/^/   /'

print_success "✅ LIMPIEZA COMPLETA FINALIZADA"
echo ""
echo "📋 RESUMEN DE CAMBIOS:"
echo "   - Backup creado en: $BACKUP_DIR"
echo "   - Eliminadas todas las configuraciones con socket Unix"
echo "   - Configuración nemesix correcta aplicada"
echo "   - Servicios reiniciados completamente"
echo "   - Conectividad verificada"
echo ""
echo "🌐 URLs disponibles:"
echo "   Local: http://localhost"
echo "   Health check: http://localhost/health"
echo ""
echo "🔧 Si aún tienes problemas, revisa el backup en: $BACKUP_DIR"
echo ""
echo "📞 Para soporte adicional, ejecuta: sudo ./diagnose.sh"

