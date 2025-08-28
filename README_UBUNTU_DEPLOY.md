# 🚀 Guía de Despliegue - Nemesix en Ubuntu

## 📋 Requisitos Previos

- Ubuntu 20.04 o superior
- Usuario con permisos sudo
- Conexión a internet

## ⚡ Despliegue Rápido (Recomendado)

### Paso 1: Clonar el repositorio
```bash
cd ~
git clone https://github.com/aburriyo/nemesix_testing.git
cd nemesix_testing
```

### Paso 2: Ejecutar despliegue automático
```bash
sudo ./deploy_simple.sh
```

### Paso 3: Verificar funcionamiento
```bash
curl http://localhost/health
```

Si ves `{"status": "healthy", "timestamp": "..."}`, ¡está funcionando!

## 🔧 Solución de Problemas

### Si obtienes Error 502 Bad Gateway:

1. **Ejecutar diagnóstico completo:**
```bash
sudo ./diagnose.sh
```

2. **Aplicar solución automática:**
```bash
sudo ./fix_502.sh
```

3. **Verificar logs en tiempo real:**
```bash
sudo journalctl -u nemesix -f
```

## 📊 Verificación del Estado

### Servicios activos:
```bash
sudo systemctl status nemesix
sudo systemctl status nginx
```

### Logs importantes:
```bash
# Logs de la aplicación
sudo journalctl -u nemesix -f

# Logs de Nginx
sudo tail -f /var/log/nginx/nemesix_error.log
```

### Conectividad:
```bash
# Backend (Gunicorn)
curl http://localhost:8080/health

# Frontend (Nginx)
curl http://localhost/health
```

## 🔑 Credenciales de Acceso

Después del despliegue, puedes acceder con:

- **Admin:** `admin@nemesix.com` / `admin123`
- **Usuario de prueba:** `test1@nemesix.com` / `test123`

## 🌐 URLs Disponibles

- **Aplicación principal:** `http://tu-ip-o-dominio`
- **Health check:** `http://localhost/health`
- **Login:** `http://tu-ip-o-dominio/login`

## 🛠️ Comandos Útiles

```bash
# Reiniciar servicios
sudo systemctl restart nemesix nginx

# Ver estado de servicios
sudo systemctl status nemesix nginx

# Ver logs en tiempo real
sudo journalctl -u nemesix -f

# Recargar configuración de Nginx
sudo nginx -t && sudo systemctl reload nginx
```

## 📁 Estructura de Archivos

```
/var/www/nemesix/          # Directorio principal
├── app.py                 # Aplicación Flask
├── gunicorn_config.py     # Configuración de Gunicorn
├── nginx.conf            # Configuración de Nginx
├── requirements.txt      # Dependencias Python
├── database/             # Base de datos SQLite
├── static/               # Archivos estáticos
├── templates/            # Plantillas HTML
└── logs/                 # Logs de la aplicación
```

## ⚠️ Solución de Problemas Comunes

### 1. Puerto 8080 ocupado
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

### 2. Permisos insuficientes
```bash
sudo chown -R $USER:$USER /var/www/nemesix
```

### 3. Base de datos corrupta
```bash
cd /var/www/nemesix
rm database/nemesix_db.db
python3 -c "from config.mysqlconnection import connectToMySQL; connectToMySQL('nemesix_db')"
```

### 4. Entorno virtual roto
```bash
cd /var/www/nemesix
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 📞 Soporte

Si después de seguir esta guía sigues teniendo problemas:

1. Ejecuta `./diagnose.sh` y comparte la salida
2. Revisa los logs: `sudo journalctl -u nemesix -f`
3. Verifica la conectividad: `curl http://localhost:8080/health`

¡La aplicación debería funcionar sin problemas siguiendo estos pasos!
