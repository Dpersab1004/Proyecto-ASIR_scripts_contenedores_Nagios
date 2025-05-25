#!/bin/bash
# check_net_usage.sh: Chequea la tasa de uso de red (RX y TX) para una interfaz,
# midiendo el tráfico durante un intervalo mayor para obtener un promedio.

# Uso:
#   ./check_net_usage.sh <interfaz> [intervalo_segundos]
# Si no se especifica el intervalo, usará 5 segundos por defecto.

if [ -z "$1" ]; then
  echo "Usage: $0 interface [interval_seconds]"
  exit 3
fi

INTERFACE="$1"
INTERVAL=${2:-5}  # Intervalo por defecto de 5 segundos si no se pasa como argumento

# Verificar que la interfaz existe en /proc/net/dev:
if ! grep -q "$INTERFACE:" /proc/net/dev; then
  echo "Interfaz $INTERFACE no encontrada"
  exit 3
fi

# Obtener contadores iniciales en bytes
RX1=$(grep "$INTERFACE:" /proc/net/dev | awk '{print $2}')
TX1=$(grep "$INTERFACE:" /proc/net/dev | awk '{print $10}')

# Esperar el intervalo definido (por defecto 5 segundos)
sleep "$INTERVAL"

# Obtener contadores finales en bytes
RX2=$(grep "$INTERFACE:" /proc/net/dev | awk '{print $2}')
TX2=$(grep "$INTERFACE:" /proc/net/dev | awk '{print $10}')

# Calcular la diferencia, promediar sobre el intervalo y convertir a KiB/s
RX_RATE=$(echo "scale=2; ($RX2 - $RX1) / 1024 / $INTERVAL" | bc)
TX_RATE=$(echo "scale=2; ($TX2 - $TX1) / 1024 / $INTERVAL" | bc)

# Salida formateada para Nagios, con performance data
echo "OK - Red $INTERFACE: RX = ${RX_RATE} KiB/s, TX = ${TX_RATE} KiB/s | rx=${RX_RATE}kB/s; tx=${TX_RATE}kB/s"
exit 0
