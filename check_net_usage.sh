#!/bin/bash
# check_remote_net_usage.sh: Monitorea la tasa de uso de red (RX y TX) de la interfaz 'ens33'
# en la máquina remota con IP 192.168.1.138, midiendo el tráfico durante un intervalo.
#
# Uso:
#   ./check_remote_net_usage.sh [intervalo_segundos]
# Si no se especifica, se usa un intervalo de 5 segundos.
#
# Nota:
#   Asegúrate de tener configurada la autenticación SSH sin contraseña para el usuario 'usuario'
#   en la máquina remota y que el entorno (como PATH) esté correctamente definido.

REMOTE_HOST="usuario@192.168.1.138"
INTERFACE="ens33"
INTERVAL=${1:-5}

# Preparamos un comando que exporta un PATH completo en la sesión remota.
REMOTE_CMD="export PATH=\$PATH:/usr/local/sbin:/usr/sbin:/bin:/usr/bin;"

# Función para obtener los contadores (RX y TX) desde la máquina remota usando grep con expresión regular.
get_remote_counters() {
  ssh "$REMOTE_HOST" "$REMOTE_CMD /bin/grep -E '^[[:space:]]*$INTERFACE:' /proc/net/dev | /usr/bin/awk '{print \$2, \$10}'"
}

# Comprobamos que la interfaz existe en la máquina remota.
if ! ssh "$REMOTE_HOST" "$REMOTE_CMD /bin/grep -E '^[[:space:]]*$INTERFACE:' /proc/net/dev" > /dev/null; then
  echo "Interfaz $INTERFACE no encontrada en $REMOTE_HOST"
  exit 3
fi

# Obtener contador inicial (RX y TX) en bytes.
read RX1 TX1 < <(get_remote_counters)

# Esperar el intervalo definido.
sleep "$INTERVAL"

# Obtener contador final (RX y TX) en bytes.
read RX2 TX2 < <(get_remote_counters)

# Calcular la tasa en KiB/s.
RX_RATE=$(echo "scale=2; ($RX2 - $RX1) / 1024 / $INTERVAL" | /usr/bin/bc)
TX_RATE=$(echo "scale=2; ($TX2 - $TX1) / 1024 / $INTERVAL" | /usr/bin/bc)

# Salida formateada (compatible con Nagios, incluye performance data).
echo "OK - Red $INTERFACE en $REMOTE_HOST: RX = ${RX_RATE} KiB/s, TX = ${TX_RATE} KiB/s | rx=${RX_RATE}kB/s; tx=${TX_RATE}kB/s"
exit 0

