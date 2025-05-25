#!/bin/bash
# check_container_uptime_local.sh
#
# Este script se conecta al Docker daemon mediante TLS (sin verificación),
# obtiene la hora de inicio del contenedor (en formato UTC),
# la convierte a hora local y calcula el uptime en horas y minutos.
#
# Variables de configuración TLS:
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
# Para pruebas: deshabilitamos la verificación de TLS
export DOCKER_TLS_VERIFY=0

# Se espera como argumento el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
    echo "UNKNOWN: Uso: $0 <nombre_contenedor>"
    exit 3
fi

# Obtener la hora de inicio del contenedor mediante docker inspect
RAW_STARTED_AT=$(docker --tlsverify -H "$DOCKER_HOST" \
    --tlscacert "$DOCKER_CERT_PATH/new-ca.pem" \
    --tlscert "$DOCKER_CERT_PATH/new-client-cert.pem" \
    --tlskey "$DOCKER_CERT_PATH/new-client-key.pem" \
    inspect --format '{{.State.StartedAt}}' "$CONTAINER")

if [ -z "$RAW_STARTED_AT" ]; then
    echo "CRITICAL: Contenedor $CONTAINER no está en ejecución o no se pudo obtener la hora de inicio."
    exit 2
fi

# Eliminar la parte decimal y conservar la 'Z'
# Asumiendo un formato como: 2025-05-05T06:12:27.826945644Z
# Nos quedamos con "2025-05-05T06:12:27Z"
STARTED_AT=$(echo "$RAW_STARTED_AT" | awk -F'.' '{print $1}')Z

# Convertir la hora de inicio (UTC) a hora local
LOCAL_STARTED=$(date -d "$STARTED_AT" +"%Y-%m-%d %H:%M:%S %Z")

# Obtener el timestamp de inicio y el timestamp actual (en UTC)
START_TIMESTAMP=$(date -u -d "$STARTED_AT" +%s)
CURRENT_TIMESTAMP=$(date -u +%s)

# Calcular la diferencia en segundos y convertir a horas y minutos
DIFF_SECONDS=$((CURRENT_TIMESTAMP - START_TIMESTAMP))
HOURS=$((DIFF_SECONDS / 3600))
MINUTES=$(((DIFF_SECONDS % 3600) / 60))

# Mostrar el resultado final de manera legible
echo "OK: Uptime for $CONTAINER is $HOURS hours, $MINUTES minutes | uptime=$DIFF_SECONDS; started_at_local='$LOCAL_STARTED'"
exit 0
