# Proyecto-ASIR_scripts_contenedores_Nagios
Ubicación de los scripts referentes a las métricas de los contenedores.
/usr/local/nagios/libexec/check_container_block_io_tls.sh El número de bytes leídos y escritos en el disco para cada contenedor.
/usr/local/nagios/libexec/check_container_cpu_usage.sh El uso de cpu.
/usr/local/nagios/libexec/check_container_health.sh Si el proceso principal del contenedor está healthy, es decir el servicio principal del contenedor.
/usr/local/nagios/libexec/check_container_memory_local.sh El uso de memoria.
/usr/local/nagios/libexec/check_container_network_usage.sh -Los paquetes enviados y recibidos en la comunicación para el contenedor de mysql.
/usr/local/nagios/libexec/check_mycontainer_status.sh El estado del contenedor mientras esté running todo estará bien.
/usr/local/nagios/libexec/check_container_restarts.sh El número de reinicios del contenedor, por lo que sí es 0, todo está en orden.
/usr/local/nagios/libexec/check_container_uptime_ps.sh El tiempo que lleva el contenedor encendido.
/usr/local/nagios/libexec/check_net_usage.sh ens33 para el contenedor apache ya que tiene red host, e indicando la interfaz de red.




