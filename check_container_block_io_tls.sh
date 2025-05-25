#!/bin/bash
#
# check_container_block_io_tls.sh
#
# Descripción:
#   Este plugin de Nagios consulta la métrica de Block I/O (lectura y escritura)
#   de un contenedor Docker utilizando "docker stats --no-stream" y se conecta
#   al Docker daemon de forma segura mediante TLS.
#
# Uso:
#   check_container_block_io_tls.sh <nombre_del_contenedor>
#
# Códigos de salida:
#   0 = OK
#   2 = CRITICAL
#   3 = UNKNOWN
#

# Variables de configuración TLS (ajusta según tu entorno)
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
export DOCKER_TLS_VERIFY=1

# Definir la ruta absoluta al comando docker
DOCKER_BIN="/usr/bin/docker"

# Validar que se ha pasado el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
    echo "UNKNOWN: Uso: $0 <nombre_del_contenedor>"
    exit 3
fi

# Función para convertir valores con sufijo (B, KB, MB, GB) a bytes
convert_to_bytes() {
    local VALUE="$1"
    # Extrae la parte numérica (por ejemplo, "4.1")
    local number
    number=$(echo "$VALUE" | sed -E 's/([0-9.]+).*/\1/')
    # Extrae la unidad (por ejemplo, "kB", "MB", "GB") y la convierte a mayúsculas
    local unit
    unit=$(echo "$VALUE" | sed -E 's/[0-9.]+(.*)/\1/' | tr -d ' ' | tr '[:lower:]' '[:upper:]')
    local multiplier=1
    case "$unit" in
        KB) multiplier=1024 ;;
        MB) multiplier=$((1024*1024)) ;;
        GB) multiplier=$((1024*1024*1024)) ;;
        *) multiplier=1 ;;  # Se asume "B" o sin sufijo
    esac
    local bytes
    bytes=$(awk -v n="$number" -v m="$multiplier" 'BEGIN {printf "%.0f", n*m}')
    echo "$bytes"
}

# Obtener la métrica Block I/O utilizando docker stats vía TLS
# Se espera un formato del tipo "READ / WRITE", por ejemplo: "0B / 4.1kB"
RAW_BLOCK_IO=$($DOCKER_BIN --tlsverify -H "$DOCKER_HOST" \
    --tlscacert "$DOCKER_CERT_PATH/new-ca.pem" \
    --tlscert "$DOCKER_CERT_PATH/new-client-cert.pem" \
    --tlskey "$DOCKER_CERT_PATH/new-client-key.pem" \
    stats --no-stream --format "{{.BlockIO}}" "$CONTAINER" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$RAW_BLOCK_IO" ]; then
    echo "CRITICAL: No se pudo obtener el Block I/O para el contenedor '$CONTAINER'"
    exit 2
fi

# Extraer el valor de lectura (READ) y de escritura (WRITE)
READ_RAW=$(echo "$RAW_BLOCK_IO" | awk -F'/' '{print $1}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
WRITE_RAW=$(echo "$RAW_BLOCK_IO" | awk -F'/' '{print $2}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

if [ -z "$READ_RAW" ] || [ -z "$WRITE_RAW" ]; then
    echo "CRITICAL: Formato inesperado en Block I/O ('$RAW_BLOCK_IO') para el contenedor '$CONTAINER'"
    exit 2
fi

# Convertir los valores obtenidos a bytes
READ_BYTES=$(convert_to_bytes "$READ_RAW")
WRITE_BYTES=$(convert_to_bytes "$WRITE_RAW")

# Salida final en formato Nagios, especificando READ y WRITE
echo "OK: Block I/O for $CONTAINER - Read: ${READ_BYTES} bytes, Write: ${WRITE_BYTES} bytes | read_bytes=${READ_BYTES} write_bytes=${WRITE_BYTES}"
exit 0
