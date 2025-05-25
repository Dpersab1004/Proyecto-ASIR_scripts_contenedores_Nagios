#!/bin/bash
#
# check_container_network_usage_tls.sh
#
# Descripción:
#   Este plugin de Nagios consulta el uso de red (Net I/O) de un contenedor Docker
#   utilizando "docker stats --no-stream" y se conecta al Docker daemon de forma segura
#   mediante TLS.
#
# Uso:
#   check_container_network_usage_tls.sh <nombre_del_contenedor>
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

# Validación del parámetro: se espera como argumento el nombre del contenedor
if [ -z "$1" ]; then
    echo "UNKNOWN: Uso: $0 <nombre_del_contenedor>"
    exit 3
fi
CONTAINER="$1"

# Función para convertir valores con sufijo (B, KB, MB, GB) a bytes
convert_to_bytes() {
    local VALUE="$1"
    # Extrae la parte numérica (por ejemplo, "11.4")
    local number
    number=$(echo "$VALUE" | sed -E 's/([0-9.]+).*/\1/')
    # Extrae la unidad (por ejemplo, kB, MB, GB) y la convierte a mayúsculas
    local unit
    unit=$(echo "$VALUE" | sed -E 's/[0-9.]+(.*)/\1/' | tr -d ' ' | tr '[:lower:]' '[:upper:]')
    local multiplier=1
    case "$unit" in
        KB) multiplier=1024 ;;
        MB) multiplier=$((1024*1024)) ;;
        GB) multiplier=$((1024*1024*1024)) ;;
        *) multiplier=1 ;;  # Se asume "B" o sin sufijo
    esac
    # Calcula el valor en bytes, redondeado a entero
    local bytes
    bytes=$(awk -v n="$number" -v m="$multiplier" 'BEGIN {printf "%.0f", n*m}')
    echo "$bytes"
}

# Definir la ruta absoluta al comando docker (esto es esencial al ejecutar con sudo)
DOCKER_BIN="/usr/bin/docker"

# Obtener el Net I/O (tráfico de red) utilizando docker stats vía TLS
RAW_NET_IO=$($DOCKER_BIN --tlsverify -H "$DOCKER_HOST" \
    --tlscacert "$DOCKER_CERT_PATH/new-ca.pem" \
    --tlscert "$DOCKER_CERT_PATH/new-client-cert.pem" \
    --tlskey "$DOCKER_CERT_PATH/new-client-key.pem" \
    stats --no-stream --format "{{.NetIO}}" "$CONTAINER" 2>/dev/null)

# Si ocurre algún error o no se obtiene salida, se marca CRITICAL
if [ $? -ne 0 ] || [ -z "$RAW_NET_IO" ]; then
    echo "CRITICAL: No se pudo obtener el uso de red para el contenedor '$CONTAINER'"
    exit 2
fi

# Se asume que RAW_NET_IO tiene el formato "RECIBIDO / TRANSMITIDO" 
# (por ejemplo, "11.4kB / 126B")
RX_RAW=$(echo "$RAW_NET_IO" | awk -F'/' '{print $1}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
TX_RAW=$(echo "$RAW_NET_IO" | awk -F'/' '{print $2}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

if [ -z "$RX_RAW" ] || [ -z "$TX_RAW" ]; then
    echo "CRITICAL: Formato inesperado en Net I/O ('$RAW_NET_IO') para el contenedor '$CONTAINER'"
    exit 2
fi

# Convertir los valores obtenidos a bytes
RX_BYTES=$(convert_to_bytes "$RX_RAW")
TX_BYTES=$(convert_to_bytes "$TX_RAW")

# Salida final en formato Nagios, especificando claramente Rx (recibido) y Tx (transmitido)
echo "OK: Network usage for $CONTAINER - Received (Rx): ${RX_BYTES} bytes, Transmitted (Tx): ${TX_BYTES} bytes | rx_bytes=${RX_BYTES} tx_bytes=${TX_BYTES}"
exit 0
