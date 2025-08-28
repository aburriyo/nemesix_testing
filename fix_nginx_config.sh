#!/bin/bash

# Script para corregir configuración de Nginx en Ubuntu
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

echo "🔧 CORRIENDO CONFIGURACIÓN DE NGINX PARA UBUNTU"
echo "==============================================="

# 1. Actualizar configuración de Nginx con rutas correctas
print_status "Actualizando configuración de Nginx..."

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

# 2. Crear enlace simbólico si no existe
print_status "Verificando enlace simbólico..."
if [ ! -L /etc/nginx/sites-enabled/nemesix ]; then
    sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/
    print_success "Enlace simbólico creado"
else
    print_success "Enlace simbólico ya existe"
fi

# 3. Remover configuración por defecto
print_status "Removiendo configuración por defecto..."
sudo rm -f /etc/nginx/sites-enabled/default

# 4. Probar configuración
print_status "Probando configuración de Nginx..."
if sudo nginx -t; then
    print_success "Configuración de Nginx correcta"
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

# 5. Reiniciar Nginx
print_status "Reiniciando Nginx..."
sudo systemctl reload nginx

# 6. Verificar estado
print_status "Verificando estado de servicios..."
sleep 2

if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx funcionando correctamente"
else
    print_error "Nginx no está activo"
    exit 1
fi

# 7. Probar conectividad
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

print_success "✅ Configuración completada"
echo ""
echo "�� URLs disponibles:"
echo "   Local: http://localhost"
echo "   Health check: http://localhost/health"
echo ""
echo "🔧 Si aún tienes problemas, ejecuta:"
echo "   sudo ./diagnose.sh"

