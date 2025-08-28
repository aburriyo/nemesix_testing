#!/bin/bash

# Script para configurar SSL con Let's Encrypt en Digital Ocean
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

# Verificar si tenemos un dominio
if [ $# -eq 0 ]; then
    print_error "Uso: $0 <tu-dominio.com>"
    echo "Ejemplo: $0 nemesix.com"
    exit 1
fi

DOMAIN=$1
EMAIL="admin@$DOMAIN"

print_status "🔒 Configurando SSL para $DOMAIN"

# Paso 1: Verificar que Nginx esté funcionando
print_status "Verificando configuración de Nginx..."
if ! sudo systemctl is-active --quiet nginx; then
    print_error "Nginx no está corriendo. Ejecuta primero el despliegue principal."
    exit 1
fi

# Paso 2: Instalar certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    print_status "Instalando Certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Paso 3: Obtener certificado SSL
print_status "Obteniendo certificado SSL de Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

if [ $? -eq 0 ]; then
    print_success "✅ Certificado SSL obtenido exitosamente"
else
    print_error "❌ Error al obtener el certificado SSL"
    exit 1
fi

# Paso 4: Verificar renovación automática
print_status "Verificando renovación automática..."
sudo certbot renew --dry-run

if [ $? -eq 0 ]; then
    print_success "✅ Renovación automática configurada correctamente"
else
    print_warning "⚠️  Puede haber un problema con la renovación automática"
fi

# Paso 5: Configurar redirección HTTP a HTTPS
print_status "Configurando redirección HTTPS..."
sudo tee /etc/nginx/sites-available/nemesix-redirect > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}
EOF

# Paso 6: Actualizar configuración principal de Nginx
print_status "Actualizando configuración de Nginx..."

# Backup de la configuración actual
sudo cp /etc/nginx/sites-available/nemesix /etc/nginx/sites-available/nemesix.backup

# Actualizar configuración para forzar HTTPS
sudo tee /etc/nginx/sites-available/nemesix > /dev/null <<EOF
# Configuración de Nginx para Nemesix con SSL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Logs
    access_log /var/log/nginx/nemesix_access.log;
    error_log /var/log/nginx/nemesix_error.log;

    # Configuración de archivos estáticos
    location /static {
        alias /var/www/nemesix/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
    }

    # Configuración del proxy para la aplicación Flask
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

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
EOF

# Paso 7: Probar y recargar Nginx
print_status "Probando configuración de Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    print_success "✅ Nginx configurado con SSL correctamente"
else
    print_error "❌ Error en configuración de Nginx"
    # Restaurar backup
    sudo cp /etc/nginx/sites-available/nemesix.backup /etc/nginx/sites-available/nemesix
    sudo systemctl reload nginx
    exit 1
fi

# Paso 8: Configurar cron para renovación automática
print_status "Configurando renovación automática de certificados..."
sudo crontab -l | grep -q certbot || (sudo crontab -l ; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -

print_success "🎉 ¡SSL configurado exitosamente!"
echo ""
echo "📋 Información importante:"
echo "   🔒 URL segura: https://$DOMAIN"
echo "   🔒 URL www: https://www.$DOMAIN"
echo "   📅 Renovación automática: Todos los días a las 12:00"
echo "   📄 Certificados: /etc/letsencrypt/live/$DOMAIN/"
echo ""
print_status "💡 Comandos útiles:"
echo "   Verificar certificado: sudo certbot certificates"
echo "   Renovar manualmente: sudo certbot renew"
echo "   Ver logs de renovación: sudo journalctl -u certbot"
echo ""
print_warning "⚠️  Recuerda:"
echo "   - Los certificados se renuevan automáticamente"
echo "   - Nginx se recarga automáticamente después de la renovación"
echo "   - Revisa los logs si hay problemas"

# Verificación final
print_status "🔍 Verificando configuración SSL..."
if curl -I https://$DOMAIN | grep -q "HTTP/2 200"; then
    print_success "✅ SSL funcionando correctamente en https://$DOMAIN"
else
    print_warning "⚠️  Puede haber un problema con la configuración SSL"
    echo "Revisa: sudo nginx -t && sudo systemctl status nginx"
fi
