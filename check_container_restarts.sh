#!/bin/bash
# check_container_restarts.sh
#
# Este script se conecta al Docker daemon remoto (usando TLS) para obtener
# la cantidad de reinicios (Restart Count) de un contenedor.
#
# Variables por defecto (ajusta según tu entorno):
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
export DOCKER_TLS_VERIFY=1

# Convertir DOCKER_HOST de tcp:// a https:// para usarlo con curl.
API_BASE=$(echo "$DOCKER_HOST" | sed 's|tcp://|https://|')

# Se espera como argumento el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
  echo "UNKNOWN: Usage: $0 <container_name>"
  exit 3
fi

# Construir la URL para consultar la información del contenedor vía API
URL="$API_BASE/containers/$CONTAINER/json"

# Obtener los datos del contenedor con curl usando el almacén de certificados del sistema.
# Se asume que ya has instalado tu CA (new-ca.pem) en /etc/ssl/certs
DATA=$(curl --silent --fail --show-error \
  --capath "/etc/ssl/certs" \
  --cert "$DOCKER_CERT_PATH/new-client-cert.pem" \
  --key "$DOCKER_CERT_PATH/new-client-key.pem" \
  "$URL")

if [ -z "$DATA" ]; then
  echo "CRITICAL: Unable to retrieve data for container $CONTAINER"
  exit 2
fi

# Extraer Restart Count y el estado global del contenedor
RESTART_COUNT=$(echo "$DATA" | jq -r '.State.RestartCount // 0')
STATE=$(echo "$DATA" | jq -r '.State.Status // empty')

# El script solo se evaluará si el contenedor está corriendo
if [ "$STATE" != "running" ]; then
  echo "CRITICAL: Container $CONTAINER is not running (State: $STATE)"
  exit 2
fi

# Mostrar el Restart Count:
if [ "$RESTART_COUNT" -eq 0 ]; then
    echo "OK: Restart Count for $CONTAINER is 0 (not restarted) | restart_count=0"
else
    echo "OK: Restart Count for $CONTAINER is $RESTART_COUNT (restarted) | restart_count=$RESTART_COUNT"
fi

exit 0
