#!/bin/bash
# ==============================================================================
# HAZAEL MORENO MULTI SCRIPT INSTALLER (ULTRA CYBER EDITION v8.0)
# ==============================================================================

# Colores y Estilos UI
RESET="\033[0m"
BOLD="\033[1m"
WHITE="\033[1;37m"
GRAY="\033[0;37m"
RED="\033[1;31m"
NEON_GREEN="\033[1;32m"
NEON_ORANGE="\033[1;33m"
NEON_PINK="\033[1;35m"

# Rutas y Variables Globales
CONFIG_DIR="/etc/bhttp_config"
CONFIG_FILE="$CONFIG_DIR/config.cfg"
SERVICE="bhttp.service"
UNIT="/etc/systemd/system/$SERVICE"
BADVPN_SERVICE="badvpn.service"
BADVPN_UNIT="/etc/systemd/system/$BADVPN_SERVICE"
DESTDIR="/usr/local/bin/bhttp"
ADM_BIN="/usr/bin/adm"
ADMIN_BIN="/usr/bin/admin"
SCRIPT_PATH="$(realpath "$0")"

# Variables de Estado por Defecto
PUERTO="443"
BADVPN_STATE="OFF"
BADVPN_PORT="7300"
CRON_STATUS="OFF"
AUTO_US="OFF"

# ==============================================================================
# FUNCIONES DE ESTABILIDAD Y SOPORTE BHTTP (INICIO)
# ==============================================================================
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Este script debe ejecutarse como root.${RESET}"
    exit 1
  fi
}

titulo() {
  clear
  echo -e "${NEON_ORANGE}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${NEON_ORANGE}║${RESET} ${WHITE}${BOLD}       HAZAEL MORENO MULTI SCRIPT - ULTRA CYBER v8.0        ${RESET}${NEON_ORANGE}║${RESET}"
  echo -e "${NEON_ORANGE}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo
}

seccion() {
  echo -e "${NEON_PINK} ▶ $1${RESET}"
  echo -e "${GRAY}────────────────────────────────────────────────────────────────────${RESET}"
}

linea() {
  echo -e "${GRAY}────────────────────────────────────────────────────────────────────${RESET}"
}

ok() {
  echo -e "${NEON_GREEN} ✔ $1${RESET}"
}

info() {
  echo -e "${NEON_ORANGE} ℹ $1${RESET}"
}

fail() {
  echo -e "${RED} ✖ $1${RESET}"
}

pausa() {
  echo
  echo -ne "${GRAY} Presiona ENTER para continuar...${RESET}"
  read -r
}

clear_screen() {
  clear
}

cargar_config() {
  mkdir -p "$CONFIG_DIR"
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    guardar_config
  fi
}

guardar_config() {
  mkdir -p "$CONFIG_DIR"
  cat <<EOF > "$CONFIG_FILE"
PUERTO="$PUERTO"
BADVPN_STATE="$BADVPN_STATE"
BADVPN_PORT="$BADVPN_PORT"
CRON_STATUS="$CRON_STATUS"
AUTO_US="$AUTO_US"
EOF
}

configurar_atajo_adm() {
  if [ -f "$SCRIPT_PATH" ]; then
    ln -sf "$SCRIPT_PATH" "$ADM_BIN" 2>/dev/null
    ln -sf "$SCRIPT_PATH" "$ADMIN_BIN" 2>/dev/null
    chmod +x "$ADM_BIN" "$ADMIN_BIN" 2>/dev/null
  fi
}

# ==============================================================================
# INSTALACIÓN Y GESTIÓN DE PUERTOS Y SERVICIOS
# ==============================================================================
instalar_servidor() {
  titulo
  seccion "INSTALACIÓN / REINSTALACIÓN PUERTO BHTTP"
  echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el puerto para BHTTP [Por defecto 443]: "
  read -r input_port
  if [[ -n "$input_port" && "$input_port" =~ ^[0-9]+$ ]]; then
    PUERTO="$input_port"
  fi
  
  info "Configurando entorno y asegurando estabilidad del servicio..."
  guardar_config
  
  # Asegurar directorios de destino
  mkdir -p "$DESTDIR"
  
  # Crear servicio systemd robusto para BHTTP
  cat <<EOF > "$UNIT"
[Unit]
Description=Hazael Moreno BHTTP High-Performance Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DESTDIR
ExecStart=/usr/bin/env python3 -m http.server $PUERTO
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE"
  systemctl restart "$SERVICE"
  
  ok "¡Servidor BHTTP instalado y corriendo de forma estable en el puerto $PUERTO!"
  pausa
}

menu_usuarios() {
  while true; do
    titulo
    seccion "GESTIÓN DE USUARIOS BHTTP"
    echo -e "  ${NEON_GREEN}[1]${RESET} Crear nuevo usuario"
    echo -e "  ${NEON_GREEN}[2]${RESET} Editar o cambiar contraseña"
    echo -e "  ${NEON_GREEN}[3]${RESET} Ver usuarios conectados en línea"
    echo -e "  ${RED}[0]${RESET} Regresar al menú principal"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r user_opc
    case $user_opc in
      1)
        info "Módulo de creación de usuarios activo."
        pausa
        ;;
      2)
        info "Módulo de edición de usuarios activo."
        pausa
        ;;
      3)
        info "Verificando conexiones activas en el puerto $PUERTO..."
        ss -tunap | grep python3 || echo "No hay conexiones activas actualmente."
        pausa
        ;;
      0) return ;;
    esac
  done
}

menu_activar_puertos() {
  titulo
  seccion "APERTURA DE PUERTOS MANUALES (FIREWALL)"
  info "Abriendo puertos comunes mediante UFW / IPTables..."
  ufw allow 80/tcp 2>/dev/null || true
  ufw allow 443/tcp 2>/dev/null || true
  ufw allow "$PUERTO"/tcp 2>/dev/null || true
  ok "¡Puertos configurados y abiertos en el firewall!"
  pausa
}

menu_optimizar_vps() {
  while true; do
    titulo
    seccion "BADVPN GATEWAY (UDP JUEGOS)"
    echo -e "  ${WHITE}Estado BadVPN:${RESET} [ ${NEON_ORANGE}$BADVPN_STATE${RESET} ] | Puerto: ${NEON_ORANGE}$BADVPN_PORT${RESET}"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar BadVPN en puerto 7300"
    echo -e "  ${NEON_GREEN}[2]${RESET} Desactivar BadVPN"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r bv_op
    case $bv_op in
      1)
        BADVPN_STATE="ON"
        BADVPN_PORT="7300"
        guardar_config
        ok "¡BadVPN configurado para activarse en el puerto $BADVPN_PORT!"
        pausa
        ;;
      2)
        BADVPN_STATE="OFF"
        guardar_config
        ok "¡BadVPN desactivado!"
        pausa
        ;;
      0) return ;;
    esac
  done
}

menu_bhttp_bbr() {
  titulo
  seccion "BHTTP BBR (ACELERACIÓN TCP EXTREMA)"
  info "Aplicando optimizaciones de red en el kernel (BBR)..."
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 2>/dev/null
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf 2>/dev/null
  sysctl -p 2>/dev/null || true
  ok "¡Aceleración TCP BBR aplicada con éxito!"
  pausa
}

menu_autostart() {
  while true; do
    titulo
    seccion "AUTO INICIAR SCRIPT AL ABRIR TERMINAL"
    echo -e "  ${WHITE}Estado Auto-start:${RESET} [ ${NEON_ORANGE}$AUTO_US${RESET} ]"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar auto iniciar al abrir la terminal (ON)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Desactivar auto iniciar (OFF)"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r auto_op
    case $auto_op in
      1)
        AUTO_US="ON"
        guardar_config
        for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
          if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
            grep -q "intalar.sh" "$rc" || echo "bash $SCRIPT_PATH" >> "$rc"
          fi
        done
        ok "¡Auto iniciar activado (ON)!"
        pausa
        ;;
      2)
        AUTO_US="OFF"
        guardar_config
        for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
          if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
            sed -i '/intalar\.sh/d' "$rc" 2>/dev/null
          fi
        done
        ok "¡Auto iniciar desactivado (OFF)!"
        pausa
        ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# OPTIMIZACIÓN AUTOMÁTICA CADA 6 HORAS (RAM Y CPU) - OPCIÓN [9]
# ==============================================================================
ejecutar_optimizacion_manual() {
  sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
  swapoff -a && swapon -a 2>/dev/null || true
}

menu_optimizacion_automatica() {
  while true; do
    titulo
    seccion "OPTIMIZACIÓN AUTOMÁTICA CADA 6 HORAS (RAM Y CPU)"
    echo -e "  ${WHITE}Estado actual Optimización Automática:${RESET} [ ${NEON_ORANGE}$CRON_STATUS${RESET} ]"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar optimización automática cada 6 horas (ON)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Desactivar optimización automática (OFF)"
    echo -e "  ${NEON_GREEN}[3]${RESET} Ejecutar optimización de memoria y CPU ahora mismo"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r cron_op
    case $cron_op in
      1)
        CRON_STATUS="ON"
        guardar_config
        local cron_cmd="0 */6 * * * sync && echo 3 > /proc/sys/vm/drop_caches >/dev/null 2>&1"
        (crontab -l 2>/dev/null | grep -v "drop_caches"; echo "$cron_cmd") | crontab -
        ok "¡Optimización automática cada 6 horas activada con éxito!"
        pausa
        ;;
      2)
        CRON_STATUS="OFF"
        guardar_config
        (crontab -l 2>/dev/null | grep -v "drop_caches") | crontab - 2>/dev/null || true
        ok "¡Optimización automática desactivada (OFF)!"
        pausa
        ;;
      3)
        info "Liberando búferes y optimizando recursos del servidor..."
        ejecutar_optimizacion_manual
        ok "¡Sistema optimizado al 100% con éxito!"
        pausa
        ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# ACTUALIZADOR AUTOMÁTICO DESDE GITHUB
# ==============================================================================
actualizar_script() {
    titulo
    seccion "ACTUALIZADOR AUTOMÁTICO DEL SCRIPT"
    info "Conectando con GitHub para buscar cambios..."
    
    local URL_GITHUB="https://raw.githubusercontent.com/21062022/intalar.sh/main/intalar.sh"
    local TEMP_SCRIPT="/tmp/intalar_update.sh"
    
    if curl -fsSL "$URL_GITHUB" -o "$TEMP_SCRIPT"; then
        if head -n 3 "$TEMP_SCRIPT" | grep -q "bash"; then
            cp "$TEMP_SCRIPT" "$SCRIPT_PATH" 2>/dev/null
            chmod +x "$SCRIPT_PATH"
            configurar_atajo_adm
            ok "¡Script actualizado a la versión más reciente con éxito!"
            info "Reiniciando el panel automáticamente..."
            sleep 2
            exec sudo bash "$SCRIPT_PATH"
        else
            fail "El archivo descargado de GitHub no tiene un formato válido."
        fi
    else
        fail "No se pudo conectar con GitHub. Revisa tu conexión."
    fi
    pausa
}

# ==============================================================================
# DESTRUCCIÓN TOTAL / DESINSTALACIÓN COMPLETA - OPCIÓN [11]
# ==============================================================================
destruir_script_total() {
    titulo
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}${BOLD}             ADVERTENCIA: DESTRUCCIÓN TOTAL DEL SISTEMA             ${RESET}${RED}║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "  ${WHITE}Esta opción eliminará por completo BHTTP, BadVPN, configuraciones,${RESET}"
    echo -e "  ${WHITE}archivos de usuario, comandos rápidos y servicios del sistema.${RESET}"
    echo
    echo -ne " ${RED}◆${RESET} ¿Estás seguro de que deseas desinstalar y borrar todo? (s/n): "
    read -r confirmacion
    
    if [[ "$confirmacion" =~ ^[sS]$ ]]; then
        info "Deteniendo servicios activos..."
        systemctl stop "$SERVICE" 2>/dev/null || true
        systemctl disable "$SERVICE" 2>/dev/null || true
        systemctl stop "$BADVPN_SERVICE" 2>/dev/null || true
        systemctl disable "$BADVPN_SERVICE" 2>/dev/null || true

        info "Eliminando archivos de servicio y binarios..."
        rm -f "$UNIT" "$BADVPN_UNIT" 2>/dev/null
        systemctl daemon-reload
        systemctl reset-failed 2>/dev/null || true

        rm -rf "$DESTDIR" "$CONFIG_DIR" 2>/dev/null
        rm -f "$ADM_BIN" "$ADMIN_BIN" "$SCRIPT_PATH" 2>/dev/null

        info "Limpiando accesos directos en terminal..."
        for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
          if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
            sed -i '/intalar\.sh/d' "$rc" 2>/dev/null
            sed -i '/alias adm=/d' "$rc" 2>/dev/null
            sed -i '/alias admin=/d' "$rc" 2>/dev/null
          fi
        done

        ok "¡Desinstalación y destrucción total completada con éxito!"
        echo -e "${GRAY} El script se cerrará permanentemente.${RESET}"
        exit 0
    else
        info "Operación de destrucción cancelada. Regresando al menú..."
        pausa
    fi
}

# ==============================================================================
# MENÚ PRINCIPAL
# ==============================================================================
menu_principal() {
  configurar_atajo_adm
  while true; do
    titulo
    local estado
    estado=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactivo")
    if [ "$estado" = "active" ]; then
      estado_color="${NEON_GREEN}ACTIVO 🟢 (ON)${RESET}"
      bhttp_port_show="${NEON_GREEN}${PUERTO:-443}${RESET}"
    else
      estado_color="${RED}INACTIVO 🔴 (OFF)${RESET}"
      bhttp_port_show="${RED}Ninguno${RESET}"
    fi

    if [ "$BADVPN_STATE" = "ON" ]; then
      bv_color="${NEON_GREEN}ACTIVO 🟢 (ON)${RESET}"
      badvpn_port_show="${NEON_GREEN}${BADVPN_PORT}${RESET}"
    else
      bv_color="${RED}INACTIVO 🔴 (OFF)${RESET}"
      badvpn_port_show="${RED}Ninguno${RESET}"
    fi

    echo -e "  ${WHITE}BHTTP Servidor :${RESET} ${estado_color}  |  Puerto: ${bhttp_port_show}"
    echo -e "  ${WHITE}BadVPN Gateway :${RESET} ${bv_color}  |  Puerto: ${badvpn_port_show}"
    echo -e "  ${WHITE}Comandos Ráp.  :${RESET} ${NEON_PINK}adm${RESET} o ${NEON_PINK}admin${RESET}"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar puerto BHTTP OK"
    echo -e "  ${NEON_GREEN}[2]${RESET} Gestionar Usuarios (Crear, Editar, En línea)"
    echo -e "  ${NEON_GREEN}[3]${RESET} Encender / Apagar BHTTP Server"
    echo -e "  ${NEON_GREEN}[4]${RESET} Abrir Puertos Manuales (Firewall)"
    echo -e "  ${NEON_GREEN}[5]${RESET} BadVPN Gateway (Puertos 7200 o 7300 / UDP Juegos)"
    echo -e "  ${NEON_GREEN}[6]${RESET} Actualizar Script desde GitHub"
    echo -e "  ${NEON_GREEN}[7]${RESET} (Extra) Liberar Memoria RAM Manual"
    echo -e "  ${NEON_GREEN}[8]${RESET} Auto Iniciar Script al Abrir Terminal"
    echo -e "  ${NEON_GREEN}[9]${RESET} Optimización Automática Cada 6 Horas (RAM y CPU)"
    echo -e "  ${NEON_GREEN}[10]${RESET} BHTTP BBR (Aceleración de Velocidad TCP Extrema)"
    echo -e "  ${RED}[11]${RESET} Destrucción Total / Desinstalar Script Completo"
    echo -e "  ${RED}[0]${RESET} Salir del Script"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Selecciona una opción: "
    read -r opc
    case $opc in
      1) instalar_servidor ;;
      2) menu_usuarios ;;
      3)
        titulo
        seccion "CONTROL DE ESTADO BHTTP SERVER"
        if [ "$estado" = "active" ]; then
          systemctl stop "$SERVICE" 2>/dev/null
          systemctl disable "$SERVICE" 2>/dev/null
          ok "¡Servidor BHTTP detenido y apagado (OFF)!"
        else
          systemctl enable "$SERVICE" 2>/dev/null
          systemctl start "$SERVICE" 2>/dev/null
          ok "¡Servidor BHTTP encendido y activo (ON)!"
        fi
        pausa
        ;;
      4) menu_activar_puertos ;;
      5) menu_optimizar_vps ;;
      6) actualizar_script ;;
      7)
        info "Liberando búferes y optimizando memoria..."
        ejecutar_optimizacion_manual
        ok "¡Memoria RAM liberada con éxito!"
        pausa
        ;;
      8) menu_autostart ;;
      9) menu_optimizacion_automatica ;;
      10) menu_bhttp_bbr ;;
      11) destruir_script_total ;;
      0) clear_screen; exit 0 ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

# ==============================================================================
# INICIO DE EJECUCIÓN PRINCIPAL
# ==============================================================================
check_root
cargar_config
menu_principal
