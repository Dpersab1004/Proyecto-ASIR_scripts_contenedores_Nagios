#!/bin/bash
# check_mycontainer_status.sh
#
# Script para verificar el estado de un contenedor Docker en un host remoto
# usando la API de Docker con TLS.
#
# Variables por defecto (ajusta según tu entorno):
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
export DOCKER_TLS_VERIFY=1

# Convertir DOCKER_HOST de tcp:// a https:// para usar con curl.
API_BASE=$(echo "$DOCKER_HOST" | sed 's|tcp://|https://|')

# Se espera como argumento el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
  echo "UNKNOWN: Usage: $0 <container_name>"
  exit 3
fi

# Construir la URL a consultar.
URL="$API_BASE/containers/$CONTAINER/json"

# Solicitar información JSON del contenedor mediante la API remota de Docker
DATA=$(curl --silent --fail --show-error \
    --cacert "$DOCKER_CERT_PATH/new-ca.pem" \
    --cert "$DOCKER_CERT_PATH/new-client-cert.pem" \
    --key "$DOCKER_CERT_PATH/new-client-key.pem" \
    "$URL")

if [ -z "$DATA" ]; then
  echo "CRITICAL: Unable to retrieve data for container $CONTAINER"
  exit 2
fi

# Extraer el estado del contenedor usando jq
STATE=$(echo "$DATA" | jq -r '.State.Status // empty')

# Si no se obtuvo ningún estado, se marca como CRITICAL
if [ -z "$STATE" ]; then
  echo "CRITICAL: Container $CONTAINER is not running (State: )"
  exit 2
fi

# Si el estado es "running" se devuelve OK; de lo contrario, CRITICAL
if [ "$STATE" == "running" ]; then
  echo "OK: Container $CONTAINER is running (State: $STATE)"
  exit 0
else
  echo "CRITICAL: Container $CONTAINER is not running (State: $STATE)"
  exit 2
fi
