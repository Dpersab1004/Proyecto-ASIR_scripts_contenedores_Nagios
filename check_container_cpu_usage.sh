#!/bin/bash
#
# check_container_cpu_usage_tls.sh
#
# Descripción:
#   Este plugin de Nagios consulta el uso de CPU de un contenedor Docker
#   utilizando "docker stats --no-stream" y conectándose al daemon mediante TLS.
#   Devuelve un mensaje compatible con Nagios.
#
# Uso:
#   check_container_cpu_usage_tls.sh <nombre_del_contenedor>
#
# Códigos de salida:
#   0 = OK, 1 = WARNING, 2 = CRITICAL, 3 = UNKNOWN
#
# Variables de configuración TLS:
: ${DOCKER_HOST:="tcp://192.168.1.138:2376"}
: ${DOCKER_CERT_PATH:="/etc/docker"}
: ${DOCKER_TLS_VERIFY:="1"}
export DOCKER_TLS_VERIFY

# Validar que se ha pasado el nombre del contenedor
CONTAINER="$1"
if [ -z "$CONTAINER" ]; then
    echo "UNKNOWN: Uso: $0 <nombre_del_contenedor>"
    exit 3
fi

# Obtener el uso de CPU utilizando docker stats con TLS y los certificados actualizados.
CPU_RAW=$(docker --tlsverify -H "$DOCKER_HOST" \
    --tlscacert "$DOCKER_CERT_PATH/new-ca.pem" \
    --tlscert "$DOCKER_CERT_PATH/new-client-cert.pem" \
    --tlskey "$DOCKER_CERT_PATH/new-client-key.pem" \
    stats --no-stream --format "{{.CPUPerc}}" "$CONTAINER" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$CPU_RAW" ]; then
    echo "CRITICAL: No se pudo obtener el uso de CPU para el contenedor '$CONTAINER'"
    exit 2
fi

# Procesar la salida para eliminar el símbolo de porcentaje y espacios extra
CPU_USAGE=$(echo "$CPU_RAW" | sed 's/%//g' | tr -d ' ')

if [ -z "$CPU_USAGE" ]; then
    echo "CRITICAL: Error al procesar el valor de CPU para el contenedor '$CONTAINER'"
    exit 2
fi

# Aquí se podría implementar la evaluación de umbrales para warning y critical.
# Para este ejemplo, se retorna siempre OK junto con el valor obtenido.
echo "OK: CPU Usage for $CONTAINER is ${CPU_USAGE}% | cpu_usage=${CPU_USAGE}"
exit 0
