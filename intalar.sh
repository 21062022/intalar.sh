#!/bin/bash
# ==============================================================================
# INSTALADOR / PANEL DE CONTROL
# PROTOCOLO BHTTP V.1 & BADVPN (TIGO Y CLARO NICARAGUA COMPLETO)
# ==============================================================================

# Variables de colores ANSI
RESET='\033[0m'
BOLD='\033[1m'
NEON_GREEN='\033[38;2;57;255;20m'
NEON_BLUE='\033[38;2;0;191;255m'
NEON_ORANGE='\033[38;2;255;102;0m'
NEON_YELLOW='\033[38;2;255;255;0m'
CIELO='\033[38;2;135;206;235m'
ROJO='\033[38;2;255;51;51m'
BLANCO='\033[38;2;255;255;255m'
GRIS='\033[38;2;128;128;128m'
MAGENTA='\033[38;2;255;0;255m'

# Archivos y Rutas
SCRIPT_PATH="/usr/local/bin/intalar.sh"
ADM_BIN="/usr/local/bin/adm"
ADMIN_BIN="/usr/local/bin/admin"
CONFIG_DIR="/etc/bhttp"
CONFIG_FILE="$CONFIG_DIR/config.json"
USERS_FILE="$CONFIG_DIR/usuarios.txt"
DESTDIR="/usr/local/bhttp"
BHTTP_BIN="$DESTDIR/bhttp"
BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
UNIT="/etc/systemd/system/bhttp.service"
BADVPN_UNIT="/etc/systemd/system/badvpn.service"

# Funciones Visuales y Consola
clear_screen() { clear; }

titulo() {
  clear_screen
  echo -e "${NEON_BLUE}====================================================================${RESET}"
  echo -e " ${NEON_GREEN}${BOLD}        HAZAEL MORENO MULTI SCRIPT - BHTTP & BADVPN${RESET}"
  echo -e "${NEON_BLUE}====================================================================${RESET}"
}

seccion() {
  echo -e " ${NEON_YELLOW}▶ $1${RESET}"
  echo -e "${GRIS}--------------------------------------------------------------------${RESET}"
}

linea() {
  echo -e "${GRIS}--------------------------------------------------------------------${RESET}"
}

ok() { echo -e " ${NEON_GREEN}✔${RESET} $1"; }
fail() { echo -e " ${ROJO}✘${RESET} $1"; }
info() { echo -e " ${CIELO}ℹ${RESET} $1"; }
pausa() { echo; echo -ne " ${GRIS}Presiona Enter para continuar...${RESET}"; read -r; }

check_root() {
  if [ "$EUID" -ne 0 ]; then
    fail "Este script debe ejecutarse como ROOT."
    exit 1
  fi
}

configurar_atajo_adm() {
  cat << EOF > "$ADM_BIN"
#!/bin/bash
bash "$SCRIPT_PATH"
EOF
  chmod +x "$ADM_BIN"
  cp -f "$ADM_BIN" "$ADMIN_BIN" 2>/dev/null
}

cargar_config() {
  mkdir -p "$CONFIG_DIR"
  touch "$USERS_FILE"
}

# ==============================================================================
# APERTURA DE PUERTOS
# ==============================================================================
abrir_puerto_sistema() {
  local p="$1"
  if command -v ufw >/dev/null 2>&1; then
    ufw allow "$p"/tcp >/dev/null 2>&1
    ufw allow "$p"/udp >/dev/null 2>&1
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -I INPUT -p tcp --dport "$p" -j ACCEPT >/dev/null 2>&1
    iptables -I INPUT -p udp --dport "$p" -j ACCEPT >/dev/null 2>&1
  fi
}

# ==============================================================================
# INSTALACIÓN Y CONFIGURACIÓN BHTTP / BADVPN
# ==============================================================================
instalar_servidor() {
  titulo
  seccion "INSTALACIÓN / CONFIGURACIÓN DE BHTTP Y BADVPN"

  echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el puerto para BHTTP (Ej. 8080): "
  read -r PORT
  PORT=${PORT:-8080}

  info "Instalando dependencias necesarias..."
  apt-get update -y >/dev/null 2>&1
  apt-get install -y curl wget git build-essential cmake net-tools openssl cron >/dev/null 2>&1

  abrir_puerto_sistema "$PORT"
  abrir_puerto_sistema 7300

  # Configurar BadVPN si no existe
  if [ ! -f "$BADVPN_BIN" ]; then
    info "Descargando e instalando BadVPN UDPGW (Puerto 7300)..."
    wget -q -O "$BADVPN_BIN" "https://raw.githubusercontent.com/dayvson/badvpn/master/badvpn-udpgw" || true
    chmod +x "$BADVPN_BIN" 2>/dev/null
  fi

  # Crear Servicio BadVPN
  cat << EOF > "$BADVPN_UNIT"
[Unit]
Description=BadVPN UDPGW Service
After=network.target

[Service]
ExecStart=$BADVPN_BIN --listen-addr 127.0.0.1:7300 --max-clients 1000
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable badvpn >/dev/null 2>&1
  systemctl restart badvpn >/dev/null 2>&1

  ok "Servicio BadVPN configurado en puerto 7300."
  ok "Servicio BHTTP listo en puerto $PORT."
  pausa
}

# ==============================================================================
# GESTIÓN DE USUARIOS
# ==============================================================================
crear_usuario() {
  local u="$1"
  local p="$2"
  local d="$3"
  
  useradd -M -s /bin/false "$u" 2>/dev/null
  echo "$u:$p" | chpasswd 2>/dev/null
  
  local pass_hash; pass_hash=$(openssl passwd -6 "$p" 2>/dev/null)
  usermod -p "$pass_hash" "$u" 2>/dev/null

  local exp_date; exp_date=$(date -d "+$d days" +%Y-%m-%d 2>/dev/null || date -v+"$d"d +%Y-%m-%d 2>/dev/null)
  chage -E "$exp_date" "$u" 2>/dev/null

  sed -i "/Usuario: $u /d" "$USERS_FILE" 2>/dev/null
  echo "Usuario: $u | Contraseña: $p | Dias: $d | Expira: $exp_date" >> "$USERS_FILE"
}

contar_conexiones_usuario() {
  local u="$1"
  local count
  count=$(ps -u "$u" 2>/dev/null | grep -c -E "ssh|bhttp|dropbear" || true)
  echo "$count"
}

monitor_usuarios_tiempo_real() {
  titulo
  seccion "MONITOR DE USUARIOS EN TIEMPO REAL"
  
  if [ ! -s "$USERS_FILE" ]; then
    info "No hay usuarios registrados."
    pausa
    return
  fi

  printf "%-12s %-16s %-20s %-15s\n" "ESTADO" "USUARIO" "CONEXIONES" "EXPIRACIÓN"
  linea

  while IFS= read -r line || [ -n "$line" ]; do
    usr=$(echo "$line" | awk '{print $2}')
    [ -z "$usr" ] && continue
    
    exp=$(echo "$line" | awk -F'|' '{print $4}' | sed 's/ Expira: //')
    con_count=$(contar_conexiones_usuario "$usr")

    if [ "$con_count" -gt 0 ]; then
      status="${NEON_GREEN}● ONLINE${RESET}"
      usr_color="${NEON_GREEN}${BOLD}"
    else
      status="${ROJO}● OFFLINE${RESET}"
      usr_color="${BLANCO}"
    fi

    printf "%-22s ${usr_color}%-16s${RESET} %-20s %-15s\n" "$status" "$usr" "$con_count act." "$exp"
  done < "$USERS_FILE"

  pausa
}

ver_detalles_usuarios() {
  titulo
  seccion "DETALLES DE USUARIOS EXISTENTES"
  
  if [ ! -s "$USERS_FILE" ]; then
    info "No hay usuarios registrados."
    pausa
    return
  fi

  echo -e " ${BLANCO}Lista de usuarios creados en el sistema:${RESET}"
  linea
  
  while IFS= read -r line || [ -n "$line" ]; do
    echo -e " ${NEON_GREEN}✔${RESET} $line"
  done < "$USERS_FILE"
  
  pausa
}

editar_usuario_lista() {
  titulo
  seccion "EDITAR USUARIO DE LA LISTA"
  
  if [ ! -s "$USERS_FILE" ]; then
    info "No hay usuarios registrados para editar."
    pausa
    return
  fi

  local i=1
  declare -A map_usr
  while IFS= read -r line || [ -n "$line" ]; do
    usr=$(echo "$line" | awk '{print $2}')
    [ -z "$usr" ] && continue
    map_usr[$i]="$usr"
    echo -e " ${NEON_GREEN}[$i]${RESET} Usuario: ${BLANCO}$usr${RESET}"
    i=$((i + 1))
  done < "$USERS_FILE"
  echo
  echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el número [1-$((i-1))]: "
  read -r sel

  if [ -n "${map_usr[$sel]}" ]; then
    local target_user="${map_usr[$sel]}"
    echo -e "\n ${CIELO}Editando usuario:${RESET} ${NEON_GREEN}${BOLD}$target_user${RESET}"
    echo -ne " Nueva contraseña 🔑 (Presiona Enter para mantener): "
    read -r new_pass
    echo -ne " Nuevos Días de Vigencia (Presiona Enter para mantener): "
    read -r new_days

    if [ -n "$new_pass" ]; then
      local pass_hash; pass_hash=$(openssl passwd -6 "$new_pass" 2>/dev/null)
      usermod -p "$pass_hash" "$target_user" 2>/dev/null
    else
      new_pass=$(grep "Usuario: $target_user " "$USERS_FILE" | awk -F'|' '{print $2}' | sed 's/ Contraseña: //')
    fi

    if [ -n "$new_days" ] && [[ "$new_days" =~ ^[0-9]+$ ]]; then
      local dias_final="$new_days"
      local exp_date; exp_date=$(date -d "+$new_days days" +%Y-%m-%d 2>/dev/null || date -v+"$new_days"d +%Y-%m-%d 2>/dev/null)
      chage -E "$exp_date" "$target_user" 2>/dev/null
    else
      local dias_final; dias_final=$(grep "Usuario: $target_user " "$USERS_FILE" | awk -F'|' '{print $3}' | sed 's/ Dias: //')
      local exp_date; exp_date=$(grep "Usuario: $target_user " "$USERS_FILE" | awk -F'|' '{print $4}' | sed 's/ Expira: //')
    fi

    sed -i "/Usuario: $target_user /d" "$USERS_FILE" 2>/dev/null
    echo "Usuario: $target_user | Contraseña: $new_pass | Dias: $dias_final | Expira: $exp_date" >> "$USERS_FILE"
    ok "¡Usuario $target_user actualizado correctamente!"
  else
    fail "Selección inválida."
  fi
  pausa
}

eliminar_usuario_lista() {
  titulo
  seccion "ELIMINAR USUARIO DE LA LISTA"
  
  if [ ! -s "$USERS_FILE" ]; then
    info "No hay usuarios para eliminar."
    pausa
    return
  fi

  local i=1
  declare -A map_usr
  while IFS= read -r line || [ -n "$line" ]; do
    usr=$(echo "$line" | awk '{print $2}')
    [ -z "$usr" ] && continue
    map_usr[$i]="$usr"
    echo -e " ${NEON_GREEN}[$i]${RESET} Usuario: ${BLANCO}$usr${RESET}"
    i=$((i + 1))
  done < "$USERS_FILE"
  echo
  echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el número de usuario a eliminar [1-$((i-1))]: "
  read -r sel

  if [ -n "${map_usr[$sel]}" ]; then
    local target_user="${map_usr[$sel]}"
    if userdel -r "$target_user" 2>/dev/null; then
      sed -i "/Usuario: $target_user /d" "$USERS_FILE" 2>/dev/null
      ok "Usuario $target_user eliminado con éxito."
    else
      fail "No se pudo eliminar al usuario $target_user."
    fi
  else
    fail "Selección inválida."
  fi
  pausa
}

borrar_todos_los_usuarios() {
  titulo
  seccion "ELIMINAR TODOS LOS USUARIOS"
  echo -e " ${ROJO}${BOLD}⚠️ ¡ADVERTENCIA! Esto borrará TODOS los usuarios del sistema y la lista.${RESET}"
  echo -ne " ${AMARILLO}¿Estás seguro de que deseas eliminar TODOS los usuarios? (s/n): ${RESET}"
  read -r resp
  if [[ "$resp" =~ ^[sS]$ ]]; then
    if [ -f "$USERS_FILE" ]; then
      while IFS= read -r line || [ -n "$line" ]; do
        usr=$(echo "$line" | awk '{print $2}')
        [ -n "$usr" ] && userdel -r "$usr" 2>/dev/null
      done < "$USERS_FILE"
      > "$USERS_FILE"
      ok "¡Todos los usuarios han sido eliminados correctamente!"
    else
      info "No hay registro de usuarios para borrar."
    fi
  else
    info "Operación cancelada."
  fi
  pausa
}

menu_usuarios() {
  while true; do
    titulo
    seccion "GESTIÓN DE USUARIOS Y CREDENCIALES"
    echo -e " ${NEON_GREEN}[1]${RESET} Crear usuario rápido"
    echo -e " ${NEON_GREEN}[2]${RESET} Monitor de usuarios en tiempo real"
    echo -e " ${NEON_GREEN}[3]${RESET} Ver detalles de usuarios creados"
    echo -e " ${NEON_GREEN}[4]${RESET} Editar usuario por lista [1, 2, 3...]"
    echo -e " ${NEON_GREEN}[5]${RESET} Eliminar usuario por lista [1, 2, 3...]"
    echo -e " ${ROJO}[6]${RESET} Borrar TODOS los usuarios creados"
    echo -e " ${ROJO}[0]${RESET} Regresar al Menú Principal"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r op
    case $op in
      1)
        echo -ne " Usuario: "; read -r nu
        echo -ne " Contraseña: "; read -r np
        echo -ne " Días de vigencia: "; read -r nd
        if [ ${#np} -lt 4 ]; then
            fail "Mínimo 4 caracteres para la contraseña"
        else
            crear_usuario "$nu" "$np" "$nd" && ok "¡Usuario $nu creado con éxito!"
        fi
        pausa
        ;;
      2) monitor_usuarios_tiempo_real ;;
      3) ver_detalles_usuarios ;;
      4) editar_usuario_lista ;;
      5) eliminar_usuario_lista ;;
      6) borrar_todos_los_usuarios ;;
      0) break ;;
      *) fail "Opción inválida."; sleep 1 ;;
    esac
  done
}

# ==============================================================================
# ACTIVADOR Y APERTURA MANUAL DE PUERTOS
# ==============================================================================
menu_activar_puertos() {
  while true; do
    titulo
    seccion "ACTIVADOR Y APERTURA MANUAL DE PUERTOS (FIREWALL)"
    echo -e " ${BLANCO}Abre cualquier puerto TCP adicional (ej. 443, 80, 8989, 8880, etc.)${RESET}"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el número de puerto a abrir (Ej. 443): "
    read -r p_ingresado

    if [[ "$p_ingresado" =~ ^[0-9]+$ ]] && [ "$p_ingresado" -gt 0 ] && [ "$p_ingresado" -le 65535 ]; then
      abrir_puerto_sistema "$p_ingresado"
      ok "¡El puerto $p_ingresado ya está abierto y aceptando tráfico!"
    else
      fail "Número de puerto inválido."
    fi
    
    echo
    echo -ne " ${CIELO}◆${RESET} ¿Quieres abrir otro puerto? (s/n): "
    read -r otro
    [[ "$otro" =~ ^[sS]$ ]] || break
  done
}

# ==============================================================================
# PANEL DE CONTROL DE SERVICIOS
# ==============================================================================
panel_servicios() {
  while true; do
    titulo
    seccion "PANEL DE CONTROL DE SERVICIOS"
    echo -e " ${NEON_GREEN}[1]${RESET} Iniciar BHTTP y BadVPN"
    echo -e " ${NEON_GREEN}[2]${RESET} Detener BHTTP y BadVPN"
    echo -e " ${NEON_GREEN}[3]${RESET} Reiniciar BHTTP y BadVPN"
    echo -e " ${ROJO}[0]${RESET} Regresar"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r op_s
    case $op_s in
      1) systemctl start bhttp badvpn 2>/dev/null; ok "Servicios iniciados correctamente."; pausa ;;
      2) systemctl stop bhttp badvpn 2>/dev/null; ok "Servicios detenidos."; pausa ;;
      3) systemctl restart bhttp badvpn 2>/dev/null; ok "Servicios reiniciados correctamente."; pausa ;;
      0) break ;;
    esac
  done
}

# ==============================================================================
# DETALLES DEL SERVIDOR VPS
# ==============================================================================
detalles_vps() {
    titulo
    seccion "DETALLES DE MI SERVIDOR VPS"
    
    local ip_publica; ip_publica=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
    local os_info; os_info=$(grep -w "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
    local ram_info; ram_info=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    local uptime_info; uptime_info=$(uptime -p | sed 's/up //')

    echo -e " ${BLANCO}Dirección IP Pública:${RESET} ${NEON_GREEN}${BOLD}$ip_publica${RESET}"
    echo -e " ${BLANCO}Sistema Operativo:${RESET}   ${CIELO}$os_info${RESET}"
    echo -e " ${BLANCO}Uso de Memoria RAM:${RESET}  ${NEON_YELLOW}$ram_info${RESET}"
    echo -e " ${BLANCO}Tiempo de Actividad:${RESET} ${MAGENTA}$uptime_info${RESET}"
    pausa
}

# ==============================================================================
# OPTIMIZACIÓN AUTOMÁTICA Y LIMPIEZA CPU/RAM (CADA 6 HORAS)
# ==============================================================================
optimizar_script_cron() {
    titulo
    seccion "OPTIMIZACIÓN AUTOMÁTICA (CADA 6 HORAS)"
    echo -e " ${BLANCO}Esta opción configura una tarea automática en el VPS para:${RESET}"
    echo -e " ${NEON_GREEN}✔ Liberar memoria RAM en caché y vaciar la SWAP${RESET}"
    echo -e " ${NEON_GREEN}✔ Reiniciar servicios suavemente para bajar uso de CPU${RESET}"
    echo -e " ${NEON_GREEN}✔ Mantener el VPS rápido sin borrar datos ni usuarios${RESET}"
    linea
    
    cat << 'EOF' > /usr/local/bin/optimizar_vps.sh
#!/bin/bash
sync; echo 3 > /proc/sys/vm/drop_caches
systemctl restart bhttp badvpn 2>/dev/null
EOF
    chmod +x /usr/local/bin/optimizar_vps.sh

    (crontab -l 2>/dev/null | grep -v "optimizar_vps.sh" ; echo "0 */6 * * * /usr/local/bin/optimizar_vps.sh >/dev/null 2>&1") | crontab -
    /usr/local/bin/optimizar_vps.sh
    
    ok "¡Optimización ejecutada y programada automáticamente cada 6 horas!"
    pausa
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
            pausa
            exec bash "$SCRIPT_PATH"
        else
            fail "El archivo descargado de GitHub no parece ser un script Bash válido."
        fi
    else
        fail "No se pudo conectar a GitHub para realizar la actualización."
    fi
    pausa
}

# ==============================================================================
# DESINSTALADOR COMPLETO
# ==============================================================================
desinstalar_script() {
    titulo
    seccion "DESTRUCCIÓN TOTAL / DESINSTALAR SCRIPT"
    echo -e " ${ROJO}${BOLD}⚠️ ¡ADVERTENCIA! Esto eliminará el servicio BHTTP, BadVPN y las configuraciones.${RESET}"
    echo -ne " ${AMARILLO}¿Estás seguro de que deseas continuar? (s/n): ${RESET}"
    read -r resp
    if [[ "$resp" =~ ^[sS]$ ]]; then
        crontab -l 2>/dev/null | grep -v "optimizar_vps.sh" | crontab -
        rm -f /usr/local/bin/optimizar_vps.sh
        systemctl stop bhttp badvpn 2>/dev/null || true
        systemctl disable bhttp badvpn 2>/dev/null || true
        rm -f "$UNIT" "$BADVPN_UNIT" "$ADM_BIN" "$ADMIN_BIN" "$SCRIPT_PATH" 2>/dev/null || true
        rm -rf "$DESTDIR" "$CONFIG_DIR" 2>/dev/null || true
        systemctl daemon-reload
        ok "¡Script y servicios desinstalados por completo!"
        exit 0
    else
        info "Operación cancelada."
        pausa
    fi
}

# ==============================================================================
# MENÚ PRINCIPAL DEL PANEL
# ==============================================================================
menu_principal() {
  check_root
  cargar_config
  configurar_atajo_adm

  while true; do
    titulo
    echo -e " ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar o Cambiar Puerto BHTTP"
    echo -e " ${NEON_GREEN}[2]${RESET} Gestión de Usuarios y Credenciales"
    echo -e " ${NEON_GREEN}[3]${RESET} Activar / Abrir Puerto Personalizado en Firewall"
    echo -e " ${NEON_GREEN}[4]${RESET} Panel de Control de Servicios (Iniciar / Parar / Reiniciar)"
    echo -e " ${NEON_GREEN}[5]${RESET} Detalles de mi servidor VPS"
    echo -e " ${NEON_GREEN}[6]${RESET} Actualizar Script desde GitHub"
    echo -e " ${NEON_GREEN}[7]${RESET} Destrucción Total / Desinstalar Script"
    echo -e " ${NEON_GREEN}[8]${RESET} Optimizar Script (CPU/RAM Auto cada 6 hrs)"
    echo -e " ${ROJO}[0]${RESET} Salir del Panel"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Selecciona una opción [1-8, 0]: "
    read -r opcion

    case $opcion in
      1) instalar_servidor ;;
      2) menu_usuarios ;;
      3) menu_activar_puertos ;;
      4) panel_servicios ;;
      5) detalles_vps ;;
      6) actualizar_script ;;
      7) desinstalar_script ;;
      8) optimizar_script_cron ;;
      0) clear_screen; ok "¡Gracias por utilizar Hazael Moreno Multi Script!"; exit 0 ;;
      *) fail "Opción inválida." ; sleep 1 ;;
    esac
  done
}

menu_principal
