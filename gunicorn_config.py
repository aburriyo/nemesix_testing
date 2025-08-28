# Configuración de Gunicorn para producción
import os
import multiprocessing

# Configuración del servidor
bind = "0.0.0.0:8080"
backlog = 2048

# Configuración de workers
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 50

# Configuración de timeout
timeout = 30
keepalive = 2
graceful_timeout = 30

# Configuración de logging
loglevel = "info"
accesslog = "-"
errorlog = "-"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Configuración de proceso
pidfile = "/tmp/gunicorn.pid"
user = os.environ.get('USER', 'www-data')
group = os.environ.get('GROUP', 'www-data')
tmp_upload_dir = None

# Configuración de SSL (si es necesario)
# keyfile = "/path/to/ssl/private.key"
# certfile = "/path/to/ssl/certificate.crt"

# Configuración de recarga automática en desarrollo
reload = os.environ.get('FLASK_ENV') == 'development'
