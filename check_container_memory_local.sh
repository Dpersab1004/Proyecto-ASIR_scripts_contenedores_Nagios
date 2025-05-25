#!/bin/bash
# check_container_memory_local.sh
#
# Este script se conecta al Docker daemon mediante TLS,
# obtiene el uso de memoria actual del contenedor usando "docker stats --no-stream"
# y lo muestra en formato Nagios.
#
# Variables de configuración TLS:
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
# Cambia a 1 para habilitar TLS verification o a 0 para deshabilitarla según tus necesidades
export DOCKER_TLS_VERIFY=1

# Se espera como argumento el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
    echo "UNKNOWN: Uso: $0 <nombre_contenedor>"
    exit 3
fi

# Obtener el uso de memoria mediante docker stats.
# Se espera una salida con formato similar a: "441.9MiB / 1.952GiB"
MEM_OUTPUT=$(docker --tlsverify -H "$DOCKER_HOST" \
    --tlscacert "$DOCKER_CERT_PATH/new-ca.pem" \
    --tlscert "$DOCKER_CERT_PATH/new-client-cert.pem" \
    --tlskey "$DOCKER_CERT_PATH/new-client-key.pem" \
    stats "$CONTAINER" --no-stream --format '{{.MemUsage}}')

if [ -z "$MEM_OUTPUT" ]; then
    echo "CRITICAL: No se pudo obtener el uso de memoria para el contenedor $CONTAINER."
    exit 2
fi

# Extraer la parte de memoria usada y la memoria total usando awk y sed para limpiar espacios
MEM_USED=$(echo "$MEM_OUTPUT" | awk -F'/' '{print $1}' | sed 's/^ *//; s/ *$//')
MEM_TOTAL=$(echo "$MEM_OUTPUT" | awk -F'/' '{print $2}' | sed 's/^ *//; s/ *$//')

# Mostrar el resultado final en formato legible para Nagios, incluyendo performance data.
# Ejemplo:
# OK: Memory usage for mysql-container is 441.9MiB / 1.952GiB | mem_used=441.9MiB mem_total=1.952GiB
echo "OK: Memory usage for $CONTAINER is $MEM_USED / $MEM_TOTAL | mem_used=$MEM_USED mem_total=$MEM_TOTAL"
exit 0
