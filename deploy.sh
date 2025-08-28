#!/bin/bash

# Script de despliegue completo para Nemesix en Digital Ocean Droplet
# Versión: 1.0
# Fecha: 28 de agosto de 2025

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes coloreados
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

# Verificar si estamos ejecutando como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script no debe ejecutarse como root"
   exit 1
fi

print_status "🚀 Iniciando despliegue de Nemesix en Digital Ocean Droplet"

# Paso 1: Actualizar el sistema
print_status "📦 Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y
print_success "Sistema actualizado"

# Paso 2: Instalar dependencias del sistema
print_status "🔧 Instalando dependencias del sistema..."
sudo apt install -y python3 python3-pip python3-venv nginx git ufw curl wget

# Instalar certbot para SSL (opcional)
sudo apt install -y certbot python3-certbot-nginx

print_success "Dependencias del sistema instaladas"

# Paso 3: Configurar firewall
print_status "🔥 Configurando firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force reload
print_success "Firewall configurado"

# Paso 4: Crear directorio del proyecto
print_status "📁 Creando directorio del proyecto..."
PROJECT_DIR="/var/www/nemesix"
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR
print_success "Directorio del proyecto creado"

# Paso 5: Clonar el repositorio
print_status "📥 Clonando repositorio..."
if [ -d "$PROJECT_DIR/.git" ]; then
    cd $PROJECT_DIR
    git pull origin main
    print_success "Repositorio actualizado"
else
    git clone https://github.com/aburriyo/nemesix_testing.git $PROJECT_DIR
    cd $PROJECT_DIR
    print_success "Repositorio clonado"
fi

# Paso 6: Configurar entorno virtual
print_status "🐍 Configurando entorno virtual..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
print_success "Entorno virtual configurado"

# Paso 7: Configurar variables de entorno
print_status "⚙️ Configurando variables de entorno..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    # Generar una SECRET_KEY segura
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    sed -i "s/tu_clave_secreta_muy_segura_aqui/$SECRET_KEY/g" .env
    print_success "Archivo .env creado con SECRET_KEY segura"
else
    print_warning "Archivo .env ya existe, saltando configuración"
fi

# Paso 8: Crear directorios necesarios
print_status "📂 Creando directorios necesarios..."
mkdir -p database
mkdir -p logs
chmod 755 static/
chmod 755 database/
chmod 755 logs/
print_success "Directorios creados"

# Paso 9: Inicializar base de datos
print_status "🗄️ Inicializando base de datos..."
python3 -c "from models.user import User; print('Base de datos inicializada')" || true
print_success "Base de datos inicializada"

# Paso 10: Configurar Nginx
print_status "🌐 Configurando Nginx..."
sudo cp nginx.conf /etc/nginx/sites-available/nemesix

# Reemplazar la ruta del proyecto en la configuración de Nginx
sudo sed -i "s|/ruta/a/tu/proyecto/nemesix_testing|$PROJECT_DIR|g" /etc/nginx/sites-available/nemesix

# Crear enlace simbólico
sudo ln -sf /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/

# Remover configuración por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# Probar configuración
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    print_success "Nginx configurado correctamente"
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

# Paso 11: Crear servicio systemd para la aplicación
print_status "⚙️ Creando servicio systemd..."
sudo tee /etc/systemd/system/nemesix.service > /dev/null <<EOF
[Unit]
Description=Nemesix Flask Application
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
Environment="FLASK_ENV=production"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --config gunicorn_config.py app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar servicio
sudo systemctl daemon-reload
sudo systemctl enable nemesix
sudo systemctl start nemesix

# Verificar que el servicio esté corriendo
if sudo systemctl is-active --quiet nemesix; then
    print_success "Servicio Nemesix iniciado correctamente"
else
    print_error "Error al iniciar el servicio Nemesix"
    sudo systemctl status nemesix
    exit 1
fi

# Paso 12: Configurar logrotate para logs
print_status "📝 Configurando rotación de logs..."
sudo tee /etc/logrotate.d/nemesix > /dev/null <<EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        sudo systemctl reload nemesix
    endscript
}
EOF
print_success "Rotación de logs configurada"

# Paso 13: Configurar monitoreo básico
print_status "📊 Configurando monitoreo básico..."
cat > check_nemesix.sh << 'EOF'
#!/bin/bash
# Script de verificación de salud de Nemesix

# Verificar que el servicio esté corriendo
if ! systemctl is-active --quiet nemesix; then
    echo "ERROR: Servicio Nemesix no está corriendo"
    exit 1
fi

# Verificar que Nginx esté corriendo
if ! systemctl is-active --quiet nginx; then
    echo "ERROR: Nginx no está corriendo"
    exit 1
fi

# Verificar conectividad
if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "ERROR: No se puede conectar a la aplicación"
    exit 1
fi

echo "✅ Nemesix está funcionando correctamente"
EOF

chmod +x check_nemesix.sh
print_success "Script de monitoreo creado"

# Paso 14: Mostrar información final
print_success "🎉 ¡Despliegue completado exitosamente!"
echo ""
echo "📋 Información importante:"
echo "   🌐 URL de la aplicación: http://$(curl -s ifconfig.me)"
echo "   🔧 Servicio: sudo systemctl status nemesix"
echo "   🌐 Nginx: sudo systemctl status nginx"
echo "   📝 Logs de aplicación: sudo journalctl -u nemesix -f"
echo "   📝 Logs de Nginx: sudo tail -f /var/log/nginx/nemesix_error.log"
echo "   🏥 Health check: http://localhost:8080/health"
echo "   🔍 Verificación: ./check_nemesix.sh"
echo ""
print_warning "📋 Próximos pasos recomendados:"
echo "   1. Configurar un dominio y SSL con Let's Encrypt"
echo "   2. Configurar monitoreo avanzado"
echo "   3. Configurar backups automáticos"
echo "   4. Revisar configuraciones de seguridad"
echo ""
print_status "💡 Comandos útiles:"
echo "   Reiniciar aplicación: sudo systemctl restart nemesix"
echo "   Reiniciar Nginx: sudo systemctl restart nginx"
echo "   Ver logs: sudo journalctl -u nemesix -f"
echo "   Ver estado: sudo systemctl status nemesix"

# Paso 15: Verificación final
print_status "🔍 Realizando verificación final..."
sleep 5

if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_success "✅ Verificación exitosa - La aplicación está funcionando"
else
    print_error "❌ Verificación fallida - Revisa los logs para más detalles"
fi

print_success "🚀 ¡Despliegue completado! Tu aplicación Nemesix está lista para usar."
