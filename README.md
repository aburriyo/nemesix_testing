# Nemesix - Aplicación Web

Una aplicación web moderna construida con Flask para el proyecto Nemesix.

## 🚀 Despliegue Automático en Digital Ocean Droplet

### Opción 1: Despliegue Automático (Recomendado)

#### Paso 1: Crear Droplet
1. Ve a [Digital Ocean](https://cloud.digitalocean.com/)
2. Crea un nuevo Droplet con Ubuntu 22.04 LTS
3. Elige el plan más económico (5$/mes está bien)
4. Agrega tu SSH key para acceso seguro

#### Paso 2: Conectar al Droplet
```bash
ssh root@TU_IP_DEL_DROPLET
```

#### Paso 3: Ejecutar despliegue automático
```bash
# Descargar y ejecutar el script de despliegue
wget https://raw.githubusercontent.com/aburriyo/nemesix_testing/main/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

¡Listo! Tu aplicación estará funcionando en `http://TU_IP_DEL_DROPLET`

#### Paso 4: Configurar SSL (Opcional pero recomendado)
```bash
# Una vez que tengas un dominio apuntando a tu Droplet
./setup_ssl.sh tu-dominio.com
```

## 🔧 Solución de Problemas

### Error: "Este script no debe ejecutarse como root"
**Problema:** El script detecta que estás ejecutando como usuario root.

**Solución:**
```bash
# Crear usuario dedicado
adduser nemesix
usermod -aG sudo nemesix
su - nemesix

# Ahora ejecutar el script
./deploy.sh
```

### Error: "fatal: destination path '/var/www/nemesix' already exists"
**Problema:** El directorio ya existe y no está vacío.

**Soluciones:**

#### Opción A: Usar el script auxiliar (Recomendado)
```bash
# Descargar y ejecutar el script auxiliar
wget https://raw.githubusercontent.com/aburriyo/nemesix_testing/main/fix_directory.sh
chmod +x fix_directory.sh
./fix_directory.sh
```

#### Opción B: Borrar y reclonar (Si no hay datos importantes)
```bash
sudo rm -rf /var/www/nemesix
./deploy.sh
```

#### Opción C: Respaldar y continuar
```bash
# Crear backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
sudo mkdir -p /var/backups
sudo mv /var/www/nemesix /var/backups/nemesix_$TIMESTAMP

# Ejecutar despliegue
./deploy.sh
```

### Verificar Estado del Servicio
```bash
# Verificar que el servicio esté corriendo
sudo systemctl status nemesix

# Ver logs en tiempo real
sudo journalctl -u nemesix -f

# Reiniciar servicio
sudo systemctl restart nemesix
```

### Verificar Nginx
```bash
# Probar configuración
sudo nginx -t

# Ver logs de Nginx
sudo tail -f /var/log/nginx/nemesix_error.log

# Reiniciar Nginx
sudo systemctl restart nginx
```

### Health Check
```bash
# Verificar que la aplicación responda
curl http://localhost:8080/health

# Verificar desde el navegador
curl http://TU_IP_DEL_DROPLET/health
```

### Comandos Útiles para Mantenimiento
```bash
# Ver estado completo del sistema
./check_nemesix.sh

# Actualizar aplicación
cd /var/www/nemesix
git pull origin main
sudo systemctl restart nemesix

# Ver logs de aplicación
sudo journalctl -u nemesix -f

# Ver logs de Nginx
sudo tail -f /var/log/nginx/nemesix_access.log
sudo tail -f /var/log/nginx/nemesix_error.log
```

### Problemas Comunes

#### La aplicación no carga estilos/CSS
- Verifica que Nginx esté sirviendo archivos estáticos correctamente
- Revisa los permisos de la carpeta `static/`
```bash
sudo chown -R nemesix:nemesix /var/www/nemesix/static
sudo chmod 755 /var/www/nemesix/static
```

#### Error 502 Bad Gateway
- La aplicación Flask no está corriendo
```bash
sudo systemctl status nemesix
sudo systemctl restart nemesix
```

#### Error 500 Internal Server Error
- Revisa los logs de la aplicación
```bash
sudo journalctl -u nemesix -f
```

#### Problemas de permisos
```bash
# Ajustar permisos correctos
sudo chown -R nemesix:nemesix /var/www/nemesix
sudo chmod 755 /var/www/nemesix
sudo chmod 644 /var/www/nemesix/*.py
```

### Opción 2: Despliegue Manual

#### Prerrequisitos

- Droplet de Ubuntu 20.04 o superior
- Python 3.8+
- Nginx
- Supervisor (opcional, para gestión de procesos)

#### Instalación Manual

1. **Conectar al Droplet:**
```bash
ssh root@TU_IP_DEL_DROPLET
```

2. **Actualizar el sistema:**
```bash
sudo apt update && sudo apt upgrade -y
```

3. **Instalar dependencias:**
```bash
sudo apt install -y python3 python3-pip python3-venv nginx git ufw
```

4. **Clonar el repositorio:**
```bash
cd /var/www
sudo mkdir nemesix
sudo chown -R $USER:$USER nemesix
git clone https://github.com/aburriyo/nemesix_testing.git nemesix
cd nemesix
```

5. **Configurar entorno virtual:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

6. **Configurar variables de entorno:**
```bash
cp .env.example .env
nano .env  # Configura tu SECRET_KEY
```

7. **Configurar Nginx:**
```bash
sudo cp nginx.conf /etc/nginx/sites-available/nemesix
sudo sed -i 's|/ruta/a/tu/proyecto/nemesix_testing|/var/www/nemesix|g' /etc/nginx/sites-available/nemesix
sudo ln -s /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

8. **Crear directorios necesarios:**
```bash
mkdir -p database logs
chmod 755 static/ database/ logs/
```

9. **Iniciar la aplicación:**
```bash
chmod +x start.sh
./start.sh
```

### Configuración de Dominio y SSL

#### Paso 1: Configurar DNS
1. Ve a tu registrador de dominios
2. Crea un registro A apuntando a la IP de tu Droplet
3. Espera a que se propague el DNS (puede tomar hasta 24 horas)

#### Paso 2: Configurar SSL
```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtener certificado
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com

# La renovación automática ya está configurada
```

### Monitoreo y Mantenimiento

#### Comandos útiles:
```bash
# Ver estado de servicios
sudo systemctl status nemesix
sudo systemctl status nginx

# Ver logs
sudo journalctl -u nemesix -f
sudo tail -f /var/log/nginx/nemesix_error.log

# Reiniciar servicios
sudo systemctl restart nemesix
sudo systemctl restart nginx

# Verificar salud
curl http://localhost:8080/health
```

#### Backup automático:
```bash
# Crear script de backup
sudo tee /usr/local/bin/backup_nemesix.sh > /dev/null <<EOF
#!/bin/bash
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/nemesix"
mkdir -p \$BACKUP_DIR

# Backup de base de datos
cp /var/www/nemesix/database/nemesix_db.db \$BACKUP_DIR/nemesix_db_\$DATE.db

# Backup de configuración
tar -czf \$BACKUP_DIR/config_\$DATE.tar.gz /var/www/nemesix/.env /etc/nginx/sites-available/nemesix

# Limpiar backups antiguos (mantener últimos 7)
find \$BACKUP_DIR -name "*.db" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completado: \$DATE"
EOF

sudo chmod +x /usr/local/bin/backup_nemesix.sh

# Configurar cron para backup diario
sudo crontab -l | { cat; echo "0 2 * * * /usr/local/bin/backup_nemesix.sh"; } | sudo crontab -
```

### Troubleshooting

#### Problema: Solo se muestra HTML sin estilos/CSS

**Solución:**
1. Verificar que Nginx esté sirviendo los archivos estáticos:
```bash
sudo nginx -t
sudo systemctl reload nginx
```
2. Revisar permisos:
```bash
sudo chown -R www-data:www-data /var/www/nemesix/static/
```
3. Verificar configuración de Nginx para archivos estáticos

#### Problema: Error 500

**Solución:**
1. Revisar logs de la aplicación:
```bash
sudo journalctl -u nemesix -f
```
2. Verificar base de datos:
```bash
ls -la /var/www/nemesix/database/
```
3. Revisar variables de entorno

#### Problema: Error de conexión

**Solución:**
1. Verificar que Gunicorn esté corriendo:
```bash
ps aux | grep gunicorn
```
2. Revisar configuración de firewall:
```bash
sudo ufw status
```
3. Verificar configuración de Nginx

### Escalado y Optimización

#### Para alto tráfico:
1. **Aumentar workers de Gunicorn:**
   - Edita `gunicorn_config.py`
   - Ajusta `workers = multiprocessing.cpu_count() * 2 + 1`

2. **Configurar Redis para sesiones:**
   - Instala Redis: `sudo apt install redis-server`
   - Configura Flask-Session

3. **Configurar CDN:**
   - Usa Cloudflare o AWS CloudFront
   - Configura para archivos estáticos

#### Monitoreo avanzado:
```bash
# Instalar Prometheus + Grafana
sudo apt install -y prometheus grafana

# Configurar monitoreo de la aplicación
# Agregar métricas personalizadas en app.py
```

## 📋 Características

- ✅ Autenticación de usuarios
- ✅ Dashboard administrativo
- ✅ Sistema de perfiles
- ✅ Interfaz responsiva
- ✅ Animaciones modernas
- ✅ Base de datos SQLite
- ✅ Configuración de producción
- ✅ Manejo de errores
- ✅ Logging integrado
- ✅ SSL automático
- ✅ Backups automáticos

## 🛠️ Tecnologías

- **Backend:** Flask 3.0.3
- **Base de datos:** SQLite
- **Servidor:** Gunicorn
- **Web Server:** Nginx
- **SSL:** Let's Encrypt
- **Frontend:** HTML5, CSS3, JavaScript
- **Animaciones:** Anime.js

## 📞 Soporte

Si encuentras problemas durante el despliegue, verifica:
1. Los logs de error
2. La configuración de Nginx
3. Los permisos de archivos
4. Las variables de entorno

**¿Necesitas ayuda?** Revisa los logs y la documentación de troubleshooting arriba.


## Make Changes to Your App

If you forked our repo, you can now make changes to your copy of the sample app. Pushing a new change to the forked repo automatically redeploys the app to App Platform with zero downtime.

Here's an example code change you can make for this app:

1. Edit `templates/index.html` and replace "Welcome to your new Flask App!" with a different greeting
1. Commit the change to the `main` branch. Normally it's a better practice to create a new branch for your change and then merge that branch to `main` after review, but for this demo you can commit to the `main` branch directly.
1. Visit the [control panel](https://cloud.digitalocean.com/apps) and navigate to your sample app.
1. You should see a "Building..." progress indicator, just like when you first created the app.
1. Once the build completes successfully, click the **Live App** link in the header and you should see your updated application running. You may need to force refresh the page in your browser (e.g. using **Shift** + **Reload**).

## Learn More

To learn more about App Platform and how to manage and update your application, see [our App Platform documentation](https://www.digitalocean.com/docs/app-platform/).

## Delete the App

When you no longer need this sample application running live, you can delete it by following these steps:
1. Visit the [Apps control panel](https://cloud.digitalocean.com/apps).
2. Navigate to the sample app.
3. In the **Settings** tab, click **Destroy**.

**Note**: If you do not delete your app, charges for using DigitalOcean services will continue to accrue.
