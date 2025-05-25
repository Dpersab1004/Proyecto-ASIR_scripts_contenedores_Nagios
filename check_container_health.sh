#!/bin/bash
# check_container_health.sh
#
# Este script conecta al Docker daemon remoto (usando TLS) para obtener 
# la información de un contenedor y evaluar su Health Status.
#
# Si el contenedor tiene definido healthcheck, se devuelve su estado
# (por ejemplo, "healthy" o "unhealthy"). Si no existe healthcheck y el
# contenedor está corriendo, se devuelve "running".
#
# Variables por defecto (ajusta según tu entorno):
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
export DOCKER_TLS_VERIFY=1

# Convertir DOCKER_HOST de tcp:// a https:// para usarlo con curl
API_BASE=$(echo "$DOCKER_HOST" | sed 's|tcp://|https://|')

# Se espera como argumento el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
  echo "UNKNOWN: Usage: $0 <container_name>"
  exit 3
fi

# Consultar la información JSON del contenedor vía API
URL="$API_BASE/containers/$CONTAINER/json"
DATA=$(curl --silent --fail --show-error \
  --cacert "$DOCKER_CERT_PATH/new-ca.pem" \
  --cert "$DOCKER_CERT_PATH/new-client-cert.pem" \
  --key "$DOCKER_CERT_PATH/new-client-key.pem" \
  "$URL")
  
if [ -z "$DATA" ]; then
  echo "CRITICAL: Unable to retrieve data for container $CONTAINER"
  exit 2
fi

# Intentar extraer el Health Status; si no existe, se usará el estado general.
HEALTH_STATUS=$(echo "$DATA" | jq -r '.State.Health.Status // empty')

if [ -n "$HEALTH_STATUS" ]; then
  echo "OK: Health Status for $CONTAINER is $HEALTH_STATUS"
  exit 0
else
  # No existe healthcheck definido; se consulta el estado general
  STATE=$(echo "$DATA" | jq -r '.State.Status // empty')
  if [ "$STATE" == "running" ]; then
    echo "OK: Health Status for $CONTAINER is running"
    exit 0
  else
    echo "CRITICAL: Container $CONTAINER is not running (State: $STATE)"
    exit 2
  fi
fi
