#!/bin/bash

# Script de diagnóstico completo para Nemesix
# Versión: 1.0

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
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

echo "🔍 DIAGNÓSTICO COMPLETO DE NEMESIX"
echo "==================================="
echo ""

# 1. Información del sistema
print_header "1. INFORMACIÓN DEL SISTEMA"
echo "Usuario actual: $(whoami)"
echo "Directorio actual: $(pwd)"
echo "Fecha: $(date)"
echo "Uptime: $(uptime)"
echo ""

# 2. Estado de servicios
print_header "2. ESTADO DE SERVICIOS"
echo "=== Servicio Nemesix ==="
sudo systemctl status nemesix --no-pager -l || echo "Servicio no encontrado"
echo ""
echo "=== Servicio Nginx ==="
sudo systemctl status nginx --no-pager -l || echo "Servicio no encontrado"
echo ""

# 3. Procesos corriendo
print_header "3. PROCESOS CORRIENDO"
echo "=== Procesos Gunicorn ==="
ps aux | grep gunicorn | grep -v grep || echo "No se encontraron procesos gunicorn"
echo ""
echo "=== Procesos Nginx ==="
ps aux | grep nginx | grep -v grep || echo "No se encontraron procesos nginx"
echo ""

# 4. Puertos abiertos
print_header "4. PUERTOS ABIERTOS"
echo "=== Puerto 8080 (Gunicorn) ==="
netstat -tlnp 2>/dev/null | grep 8080 || ss -tlnp 2>/dev/null | grep 8080 || echo "Puerto 8080 no encontrado"
echo ""
echo "=== Puerto 80 (Nginx) ==="
netstat -tlnp 2>/dev/null | grep :80 || ss -tlnp 2>/dev/null | grep :80 || echo "Puerto 80 no encontrado"
echo ""

# 5. Archivos de configuración
print_header "5. ARCHIVOS DE CONFIGURACIÓN"
echo "=== Archivo de servicio systemd ==="
if [ -f "/etc/systemd/system/nemesix.service" ]; then
    echo "✅ /etc/systemd/system/nemesix.service existe"
    ls -la /etc/systemd/system/nemesix.service
else
    echo "❌ /etc/systemd/system/nemesix.service no existe"
fi
echo ""
echo "=== Configuración de Nginx ==="
if [ -f "/etc/nginx/sites-available/nemesix" ]; then
    echo "✅ /etc/nginx/sites-available/nemesix existe"
    ls -la /etc/nginx/sites-available/nemesix
else
    echo "❌ /etc/nginx/sites-available/nemesix no existe"
fi
echo ""

# 6. Directorio del proyecto
print_header "6. DIRECTORIO DEL PROYECTO"
PROJECT_DIR="/var/www/nemesix"
if [ -d "$PROJECT_DIR" ]; then
    echo "✅ Directorio $PROJECT_DIR existe"
    ls -la $PROJECT_DIR
    echo ""
    echo "=== Archivos Python principales ==="
    ls -la $PROJECT_DIR/*.py 2>/dev/null || echo "No se encontraron archivos .py"
    echo ""
    echo "=== Entorno virtual ==="
    if [ -d "$PROJECT_DIR/venv" ]; then
        echo "✅ Entorno virtual existe"
        ls -la $PROJECT_DIR/venv/bin/python* 2>/dev/null | head -3
    else
        echo "❌ Entorno virtual no existe"
    fi
else
    echo "❌ Directorio $PROJECT_DIR no existe"
fi
echo ""

# 7. Pruebas de conectividad
print_header "7. PRUEBAS DE CONECTIVIDAD"
echo "=== Health check local ==="
if command -v curl &> /dev/null; then
    echo "Probando http://localhost:8080/health..."
    curl -v http://localhost:8080/health 2>&1 | head -10 || echo "❌ Error conectando a localhost:8080"
    echo ""
    echo "Probando http://127.0.0.1:8080/health..."
    curl -v http://127.0.0.1:8080/health 2>&1 | head -10 || echo "❌ Error conectando a 127.0.0.1:8080"
else
    echo "❌ curl no está instalado"
fi
echo ""

# 8. Logs del sistema
print_header "8. LOGS DEL SISTEMA"
echo "=== Últimas 10 líneas del log de Nemesix ==="
sudo journalctl -u nemesix --no-pager -n 10 || echo "No se pudo acceder al log de nemesix"
echo ""
echo "=== Últimas 10 líneas del log de Nginx ==="
sudo tail -10 /var/log/nginx/nemesix_error.log 2>/dev/null || echo "No se pudo acceder al log de nginx"
echo ""

# 9. Permisos
print_header "9. PERMISOS Y USUARIO"
echo "=== Usuario actual ==="
id
echo ""
echo "=== Grupos del usuario ==="
groups
echo ""
echo "=== Permisos del directorio del proyecto ==="
if [ -d "$PROJECT_DIR" ]; then
    ls -ld $PROJECT_DIR
    echo ""
    echo "=== Propietario de archivos importantes ==="
    ls -l $PROJECT_DIR/app.py 2>/dev/null || echo "app.py no encontrado"
    ls -l $PROJECT_DIR/venv/bin/gunicorn 2>/dev/null || echo "gunicorn no encontrado"
else
    echo "Directorio del proyecto no existe"
fi
echo ""

# 10. Firewall
print_header "10. FIREWALL"
echo "=== Estado de UFW ==="
sudo ufw status || echo "UFW no está disponible"
echo ""

print_header "11. RESUMEN Y RECOMENDACIONES"
echo "🔍 Diagnóstico completado. Revisa los resultados arriba."
echo ""
echo "📋 Comandos útiles para solucionar problemas:"
echo "   - Reiniciar servicios: sudo systemctl restart nemesix nginx"
echo "   - Ver logs en tiempo real: sudo journalctl -u nemesix -f"
echo "   - Probar configuración nginx: sudo nginx -t"
echo "   - Ver procesos: ps aux | grep gunicorn"
echo ""
echo "💡 Si encuentras errores, comparte la salida de este script."
