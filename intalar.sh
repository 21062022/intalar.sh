#!/usr/bin/env bash
# ==============================================================================
# PARCHE HAZAEL v2
# Repara las opciones 6, 7, 8, 9 y 11 de intalar.sh (faltaban sus funciones)
# y reemplaza el menú principal por un panel profesional con estado en vivo.
#
# USO:   sudo bash parche_hazael.sh [/ruta/a/intalar.sh]
#
# Seguridad:
#   - Hace un respaldo automático:  intalar.sh.bak-FECHA
#   - Valida la sintaxis (bash -n) antes de aplicar. Si algo falla NO modifica nada.
#   - No toca el servidor BHTTP, usuarios, BadVPN, BBR ni el resto de tu script.
# ==============================================================================
set -u

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  for c in /usr/local/bin/intalar.sh ./intalar.sh; do
    [ -f "$c" ] && { TARGET="$c"; break; }
  done
fi
[ -f "$TARGET" ] || { echo "✖ No encontré intalar.sh. Uso: sudo bash $0 /ruta/intalar.sh"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "✖ Se necesita python3."; exit 1; }

BACKUP="${TARGET}.bak-$(date +%Y%m%d-%H%M%S)"
cp -p "$TARGET" "$BACKUP" || { echo "✖ No pude crear el respaldo."; exit 1; }
TMPB="$(mktemp)"; TMPN="$(mktemp)"
trap 'rm -f "$TMPB" "$TMPN"' EXIT

cat > "$TMPB" <<'BLOQUE_NUEVO_EOF'
# === PARCHE HAZAEL v2 (opciones 6,7,8,9,11 + panel profesional) ===============

AUTOSTART_MARK_INI="# >>> BHTTP-AUTOSTART >>>"
AUTOSTART_MARK_FIN="# <<< BHTTP-AUTOSTART <<<"
CRON_FILE="/etc/cron.d/bhttp-optimizer"
OPT_BIN="/usr/local/bin/bhttp-optimize.sh"
OPT_LOG="/var/log/bhttp-optimize.log"

# ------------------------------------------------------------------------------
# UTILIDADES DE PANEL
# ------------------------------------------------------------------------------
ram_info(){
  free -m 2>/dev/null | awk '/^Mem:/{t=$2; a=$7; if(a=="")a=$4; u=t-a; p=(t>0)?u*100/t:0; printf "%d %d %d", u, t, p}'
}

barra_uso(){
  local pct="${1:-0}" n i out="" color
  [[ "$pct" =~ ^[0-9]+$ ]] || pct=0
  [ "$pct" -gt 100 ] && pct=100
  n=$((pct/10))
  if [ "$pct" -lt 60 ]; then color="$NEON_GREEN"
  elif [ "$pct" -lt 85 ]; then color="$NEON_ORANGE"
  else color="$RED"; fi
  for ((i=0; i<10; i++)); do
    if [ "$i" -lt "$n" ]; then out+="█"; else out+="░"; fi
  done
  echo -e "${color}${out}${RESET} ${WHITE}${pct}%${RESET}"
}

estado_servicio(){
  if systemctl is-active --quiet "$1" 2>/dev/null; then
    echo "${NEON_GREEN}● ACTIVO${RESET}"
  else
    echo "${RED}○ DETENIDO${RESET}"
  fi
}

onoff(){
  if [ "$1" = "ON" ]; then echo "${NEON_GREEN}● ACTIVADO${RESET}"; else echo "${RED}○ DESACTIVADO${RESET}"; fi
}

fila_panel(){
  printf "  ${NEON_BLUE}│${RESET} ${GRAY}%-18s${RESET} %b\n" "$1" "$2"
}

autostart_activo(){ grep -qs "BHTTP-AUTOSTART >>>" /root/.bashrc; }
cron_activo(){ [ -f "$CRON_FILE" ]; }

refrescar_estados(){
  if autostart_activo; then AUTOSTART_STATUS="ON"; else AUTOSTART_STATUS="OFF"; fi
  if cron_activo; then CRON_STATUS="ON"; else CRON_STATUS="OFF"; fi
  if systemctl is-active --quiet "$BADVPN_SERVICE" 2>/dev/null; then BADVPN_STATE="ON"; else BADVPN_STATE="OFF"; fi
}

resumen_usuarios(){
  local -A con=()
  local u c
  TOTAL_U=0; ONLINE_U=0; TOTAL_C=0
  while read -r u c; do
    [ -n "$u" ] || continue
    [[ "$c" =~ ^[0-9]+$ ]] || continue
    con["$u"]="$c"
  done < <(obtener_conexiones_ssh)
  while read -r u; do
    [ -n "$u" ] || continue
    TOTAL_U=$((TOTAL_U+1))
    if [ "${con[$u]:-0}" -gt 0 ]; then
      ONLINE_U=$((ONLINE_U+1))
      TOTAL_C=$((TOTAL_C+${con[$u]}))
    fi
  done < <(obtener_usuarios_panel | sort -u)
}

panel_estado(){
  local up load cpu_n cpu_p ram_u ram_t ram_p disco_p disco_t perf cron_lbl=""
  up="$(uptime -p 2>/dev/null | sed -E 's/^up //; s/ weeks?/ sem/; s/ days?/ d/; s/ hours?/ h/; s/ minutes?/ min/')"
  [ -n "$up" ] || up="N/D"
  load="$(cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo 0)"
  cpu_n="$(nproc 2>/dev/null || echo 1)"
  cpu_p="$(awk -v l="$load" -v n="$cpu_n" 'BEGIN{p=l*100/n; if(p>100)p=100; printf "%d",p}')"
  read -r ram_u ram_t ram_p <<< "$(ram_info)"
  : "${ram_u:=0}"; : "${ram_t:=0}"; : "${ram_p:=0}"
  disco_p="$(df -P / 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')"
  disco_t="$(df -hP / 2>/dev/null | awk 'NR==2{print $3"/"$2}')"
  : "${disco_p:=0}"; : "${disco_t:=N/D}"

  case "$(cat "$CONFIG_DIR/bhttp-performance.state" 2>/dev/null)" in
    speed)  perf="${NEON_GREEN}VELOCIDAD PURA${RESET}" ;;
    stable) perf="${NEON_GREEN}ESTABILIDAD${RESET}" ;;
    *)      perf="${RED}APAGADO${RESET}" ;;
  esac
  if [ "$CRON_STATUS" = "ON" ]; then
    cron_lbl="$(grep -oP 'INTERVALO: \K.*' "$CRON_FILE" 2>/dev/null | head -n1)"
  fi

  resumen_usuarios

  echo -e "  ${NEON_BLUE}┌─ ${WHITE}${BOLD}SISTEMA${RESET} ${NEON_BLUE}──────────────────────────────────────────────────${RESET}"
  fila_panel "Tiempo activo" "${WHITE}${up}${RESET}"
  fila_panel "CPU" "$(barra_uso "$cpu_p") ${GRAY}carga ${load} • ${cpu_n} núcleo(s)${RESET}"
  fila_panel "Memoria RAM" "$(barra_uso "$ram_p") ${GRAY}${ram_u}/${ram_t} MB${RESET}"
  fila_panel "Disco" "$(barra_uso "$disco_p") ${GRAY}${disco_t}${RESET}"
  echo -e "  ${NEON_BLUE}├─ ${WHITE}${BOLD}SERVICIOS${RESET} ${NEON_BLUE}────────────────────────────────────────────────${RESET}"
  fila_panel "BHTTP" "$(estado_servicio "$SERVICE")  ${GRAY}Puerto${RESET} ${NEON_GREEN}${PUERTO}${RESET}"
  fila_panel "BadVPN UDP" "$(estado_servicio "$BADVPN_SERVICE")  ${GRAY}Puerto${RESET} ${NEON_GREEN}${BADVPN_PORT}${RESET}"
  fila_panel "SSH backend" "${GRAY}Puerto${RESET} ${NEON_GREEN}${SSHPORT}${RESET}"
  echo -e "  ${NEON_BLUE}├─ ${WHITE}${BOLD}USUARIOS${RESET} ${NEON_BLUE}─────────────────────────────────────────────────${RESET}"
  fila_panel "Registrados" "${WHITE}${BOLD}${TOTAL_U}${RESET}   ${NEON_GREEN}🟢 En línea:${RESET} ${WHITE}${BOLD}${ONLINE_U}${RESET}   ${NEON_ORANGE}📱 Dispositivos:${RESET} ${WHITE}${BOLD}${TOTAL_C}${RESET}"
  echo -e "  ${NEON_BLUE}├─ ${WHITE}${BOLD}AUTOMATIZACIÓN${RESET} ${NEON_BLUE}───────────────────────────────────────────${RESET}"
  fila_panel "Auto inicio" "$(onoff "$AUTOSTART_STATUS")"
  fila_panel "Auto optimización" "$(onoff "$CRON_STATUS") ${GRAY}${cron_lbl}${RESET}"
  fila_panel "Rendimiento red" "$perf"
  echo -e "  ${NEON_BLUE}└──────────────────────────────────────────────────────────────${RESET}"
  echo
}

# ------------------------------------------------------------------------------
# OPCIÓN 7: LIBERAR RAM / OPTIMIZACIÓN MANUAL
# No reinicia servicios ni corta usuarios conectados.
# ------------------------------------------------------------------------------
optimizar_sistema(){
  sync
  echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
  if command -v journalctl >/dev/null 2>&1; then
    journalctl --vacuum-size=64M >/dev/null 2>&1 || true
  fi
  apt-get clean >/dev/null 2>&1 || true
  find /var/log -type f \( -name '*.gz' -o -name '*.old' -o -name '*.[0-9]' \) -delete 2>/dev/null || true
}

ejecutar_optimizacion_manual(){
  local antes despues liberado
  antes="$(free -m 2>/dev/null | awk '/^Mem:/{a=$7; if(a=="")a=$4; print $2-a}')"
  : "${antes:=0}"
  optimizar_sistema
  despues="$(free -m 2>/dev/null | awk '/^Mem:/{a=$7; if(a=="")a=$4; print $2-a}')"
  : "${despues:=0}"
  liberado=$((antes-despues)); [ "$liberado" -lt 0 ] && liberado=0
  info "RAM en uso antes:   ${antes} MB"
  info "RAM en uso después: ${despues} MB"
  ok "Optimización completada. Liberado aprox.: ${liberado} MB"
}

# ------------------------------------------------------------------------------
# OPCIÓN 9: OPTIMIZACIÓN AUTOMÁTICA (cron)
# ------------------------------------------------------------------------------
crear_script_optimizador(){
  cat > "$OPT_BIN" <<'OPTEOF'
#!/usr/bin/env bash
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
journalctl --vacuum-size=64M >/dev/null 2>&1
apt-get clean >/dev/null 2>&1
find /var/log -type f \( -name '*.gz' -o -name '*.old' -o -name '*.[0-9]' \) -delete 2>/dev/null
echo "$(date '+%F %T') optimizacion ejecutada" >> /var/log/bhttp-optimize.log
tail -n 200 /var/log/bhttp-optimize.log > /var/log/bhttp-optimize.log.tmp 2>/dev/null && mv -f /var/log/bhttp-optimize.log.tmp /var/log/bhttp-optimize.log
exit 0
OPTEOF
  chmod +x "$OPT_BIN"
}

asegurar_cron(){
  if ! systemctl is-active --quiet cron 2>/dev/null && ! systemctl is-active --quiet crond 2>/dev/null; then
    info "Instalando/iniciando el servicio cron..."
    apt-get install -y cron >/dev/null 2>&1 || true
    systemctl enable cron >/dev/null 2>&1 || systemctl enable crond >/dev/null 2>&1 || true
    systemctl start cron >/dev/null 2>&1 || systemctl start crond >/dev/null 2>&1 || true
  fi
  systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null
}

activar_cron(){
  local expr="$1" etiqueta="$2"
  if ! asegurar_cron; then fail "No se pudo activar el servicio cron."; return 1; fi
  crear_script_optimizador
  cat > "$CRON_FILE" <<CRONEOF
# INTERVALO: $etiqueta
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
$expr root $OPT_BIN >/dev/null 2>&1
CRONEOF
  chmod 644 "$CRON_FILE"
  CRON_STATUS="ON"; guardar_config
  ok "Optimización automática activada: $etiqueta."
}

menu_optimizacion_automatica(){
  while true; do
    refrescar_estados
    titulo; seccion "OPTIMIZACIÓN AUTOMÁTICA"
    local lbl=""
    if cron_activo; then lbl="$(grep -oP 'INTERVALO: \K.*' "$CRON_FILE" 2>/dev/null | head -n1)"; fi
    echo -e "  ${WHITE}Estado:${RESET} $(onoff "$CRON_STATUS") ${GRAY}${lbl}${RESET}"
    echo -e "  ${GRAY}Libera caché de RAM, limpia logs viejos y caché de apt.${RESET}"
    echo -e "  ${GRAY}No reinicia BHTTP ni corta a los usuarios conectados.${RESET}"; linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Cada 30 minutos"
    echo -e "  ${NEON_GREEN}[2]${RESET} Cada hora"
    echo -e "  ${NEON_GREEN}[3]${RESET} Cada 6 horas"
    echo -e "  ${NEON_GREEN}[4]${RESET} Cada 24 horas (4:00 AM)"
    echo -e "  ${NEON_GREEN}[5]${RESET} Ejecutar optimización ahora"
    echo -e "  ${RED}[6]${RESET} Desactivar optimización automática"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Opción: ")" op
    case "$op" in
      1) activar_cron "*/30 * * * *" "Cada 30 minutos"; pausa ;;
      2) activar_cron "0 * * * *" "Cada hora"; pausa ;;
      3) activar_cron "0 */6 * * *" "Cada 6 horas"; pausa ;;
      4) activar_cron "0 4 * * *" "Cada 24 horas (4:00 AM)"; pausa ;;
      5) ejecutar_optimizacion_manual; pausa ;;
      6)
        rm -f "$CRON_FILE"
        CRON_STATUS="OFF"; guardar_config
        ok "Optimización automática desactivada."; pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# OPCIÓN 8: AUTO INICIAR
#   - Servicios BHTTP/BadVPN se habilitan en el arranque del VPS.
#   - El panel se abre solo al entrar por SSH como root (solo sesiones interactivas).
# ------------------------------------------------------------------------------
menu_autostart(){
  while true; do
    refrescar_estados
    titulo; seccion "AUTO INICIAR SCRIPT"
    echo -e "  ${WHITE}Estado:${RESET} $(onoff "$AUTOSTART_STATUS")"
    echo -e "  ${GRAY}ACTIVAR: BHTTP/BadVPN arrancan con el VPS y el panel se abre${RESET}"
    echo -e "  ${GRAY}automáticamente cuando entras por SSH como root.${RESET}"; linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar auto inicio"
    echo -e "  ${RED}[2]${RESET} Desactivar apertura automática del panel"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Opción: ")" op
    case "$op" in
      1)
        systemctl enable "$SERVICE" >/dev/null 2>&1 || true
        [ -f "$BADVPN_UNIT" ] && [ "$BADVPN_STATE" = "ON" ] && systemctl enable "$BADVPN_SERVICE" >/dev/null 2>&1
        touch /root/.bashrc
        sed -i '/BHTTP-AUTOSTART >>>/,/BHTTP-AUTOSTART <<</d' /root/.bashrc 2>/dev/null || true
        cat >> /root/.bashrc <<'AEOF'
# >>> BHTTP-AUTOSTART >>>
if [ -t 0 ] && [ -t 1 ] && [ -z "$BHTTP_PANEL" ] && [ -f /usr/local/bin/intalar.sh ]; then
  export BHTTP_PANEL=1
  bash /usr/local/bin/intalar.sh
fi
# <<< BHTTP-AUTOSTART <<<
AEOF
        AUTOSTART_STATUS="ON"; guardar_config
        ok "Auto inicio activado (servicios al arranque + panel al entrar)."
        pausa ;;
      2)
        sed -i '/BHTTP-AUTOSTART >>>/,/BHTTP-AUTOSTART <<</d' /root/.bashrc 2>/dev/null || true
        AUTOSTART_STATUS="OFF"; guardar_config
        ok "El panel ya no se abre solo. (Los servicios siguen activos al arranque)"
        pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# OPCIÓN 6: ACTUALIZAR DESDE GITHUB
# Descarga a un temporal, valida, hace respaldo y reemplaza de forma atómica.
# Tus usuarios y configuración NO se tocan (viven en /etc/bhttp).
# ------------------------------------------------------------------------------
actualizar_script(){
  titulo; seccion "ACTUALIZAR SCRIPT DESDE GITHUB"
  local tmp url fn faltan="" resp
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    info "Instalando curl..."
    apt-get install -y curl >/dev/null 2>&1 || true
  fi
  tmp="$(mktemp /tmp/intalar.XXXXXX)" || { fail "No se pudo crear archivo temporal."; pausa; return 1; }
  url="${GITHUB_URL}?nocache=$(date +%s)"
  info "Descargando última versión..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 10 --max-time 60 -H 'Cache-Control: no-cache' "$url" -o "$tmp" 2>/dev/null
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 30 --no-cache -O "$tmp" "$url" 2>/dev/null
  else
    fail "No hay curl ni wget disponibles."; rm -f "$tmp"; pausa; return 1
  fi
  if [ $? -ne 0 ] || [ ! -s "$tmp" ]; then
    fail "No se pudo descargar. Revisa internet y que exista: $GITHUB_URL"
    rm -f "$tmp"; pausa; return 1
  fi
  sed -i 's/\r$//' "$tmp" 2>/dev/null || true
  if ! head -n1 "$tmp" | grep -q '^#!.*bash'; then
    fail "El archivo descargado no parece un script bash (¿repo privado o URL incorrecta?)."
    rm -f "$tmp"; pausa; return 1
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    fail "La versión de GitHub tiene errores de sintaxis. No se aplicó."
    rm -f "$tmp"; pausa; return 1
  fi
  if [ -f "$SCRIPT_PATH" ] && cmp -s "$tmp" "$SCRIPT_PATH"; then
    ok "Ya tienes la última versión."
    rm -f "$tmp"; pausa; return 0
  fi
  for fn in actualizar_script menu_autostart menu_optimizacion_automatica ejecutar_optimizacion_manual destruir_script_total; do
    grep -qE "^${fn}\(\)" "$tmp" || faltan+=" $fn"
  done
  if [ -n "$faltan" ]; then
    echo -e "  ${NEON_ORANGE}⚠ La versión de GitHub NO incluye:${RESET}${WHITE}${faltan}${RESET}"
    echo -e "  ${GRAY}Si continúas, esas opciones volverán a fallar.${RESET}"
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} ¿Actualizar de todos modos? (s/N): ")" resp
    if [[ ! "$resp" =~ ^[sSyY]$ ]]; then
      info "Actualización cancelada. Tu script actual no cambió."
      rm -f "$tmp"; pausa; return 0
    fi
  fi
  mkdir -p "$CONFIG_DIR"
  [ -f "$SCRIPT_PATH" ] && cp -f "$SCRIPT_PATH" "$CONFIG_DIR/intalar.sh.bak" 2>/dev/null || true
  if cp -f "$tmp" "${SCRIPT_PATH}.new" && chmod +x "${SCRIPT_PATH}.new" && mv -f "${SCRIPT_PATH}.new" "$SCRIPT_PATH"; then
    rm -f "$tmp"
    ok "Script actualizado. Respaldo anterior: $CONFIG_DIR/intalar.sh.bak"
    info "Reiniciando panel..."
    sleep 1
    exec bash "$SCRIPT_PATH"
  else
    fail "No se pudo escribir $SCRIPT_PATH."
    rm -f "$tmp" "${SCRIPT_PATH}.new"; pausa; return 1
  fi
}

# ------------------------------------------------------------------------------
# OPCIÓN 11: DESTRUCCIÓN TOTAL (con doble confirmación)
# ------------------------------------------------------------------------------
destruir_script_total(){
  titulo; seccion "DESTRUCCIÓN TOTAL"
  echo -e "  ${RED}⚠ Esto eliminará de este VPS:${RESET}"
  echo -e "  ${WHITE}• Servidor BHTTP y BadVPN (servicios y archivos)${RESET}"
  echo -e "  ${WHITE}• Configuración, optimización automática y auto inicio${RESET}"
  echo -e "  ${WHITE}• Comandos adm / admin y este script${RESET}"
  echo -e "  ${GRAY}Las reglas de firewall abiertas no se cierran.${RESET}"; linea
  local conf borrar="n" u uid
  read -r -p "$(echo -e " ${RED}◆${RESET} Escribe ${WHITE}DESTRUIR${RESET} para confirmar: ")" conf
  if [ "$conf" != "DESTRUIR" ]; then info "Operación cancelada."; pausa; return 0; fi
  if [ -s "$USERS_FILE" ]; then
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} ¿Eliminar TAMBIÉN las cuentas de usuario creadas en el panel? (s/N): ")" borrar
  fi

  info "Deteniendo servicios..."
  systemctl stop "$SERVICE" "$BADVPN_SERVICE" >/dev/null 2>&1 || true
  systemctl disable "$SERVICE" "$BADVPN_SERVICE" >/dev/null 2>&1 || true
  rm -f "$UNIT" "$BADVPN_UNIT"
  systemctl daemon-reload >/dev/null 2>&1 || true

  if [[ "$borrar" =~ ^[sSyY]$ ]]; then
    info "Eliminando cuentas de usuario del panel..."
    while read -r u; do
      [ -n "$u" ] || continue
      uid="$(id -u "$u" 2>/dev/null || echo 0)"
      if [ "$uid" -ge 1000 ]; then
        pkill -KILL -u "$u" >/dev/null 2>&1 || true
        userdel -r "$u" >/dev/null 2>&1 || true
      fi
    done < <(obtener_usuarios_panel | sort -u)
  fi

  info "Restaurando ajustes de red anteriores..."
  if [ -s "$CONFIG_DIR/bhttp-performance.backup" ]; then
    while IFS='=' read -r key value; do
      [ -n "$key" ] || continue
      sysctl -w "$key=$value" >/dev/null 2>&1 || true
    done < "$CONFIG_DIR/bhttp-performance.backup"
  fi
  rm -f /etc/sysctl.d/99-bhttp-performance.conf
  sysctl --system >/dev/null 2>&1 || true

  info "Quitando keepalive SSH, cron y auto inicio..."
  if [ -f /etc/ssh/sshd_config.d/99-bhttp-keepalive.conf ]; then
    rm -f /etc/ssh/sshd_config.d/99-bhttp-keepalive.conf
    systemctl reload ssh >/dev/null 2>&1 || systemctl reload sshd >/dev/null 2>&1 || true
  fi
  rm -f "$CRON_FILE" "$OPT_BIN" "$OPT_LOG"
  sed -i '/BHTTP-AUTOSTART >>>/,/BHTTP-AUTOSTART <<</d' /root/.bashrc 2>/dev/null || true
  for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
    [ -f "$rc" ] && sed -i '/alias adm=/d;/alias admin=/d' "$rc" 2>/dev/null
  done

  info "Eliminando archivos..."
  rm -rf "$DESTDIR" "$CONFIG_DIR"
  rm -f "$ADM_BIN" "$ADMIN_BIN"
  ok "Destrucción completada. Hasta pronto."
  rm -f "$SCRIPT_PATH"
  exit 0
}

# ------------------------------------------------------------------------------
# MENÚ PRINCIPAL PROFESIONAL
# ------------------------------------------------------------------------------
menu_principal(){
  configurar_atajo_adm
  while true; do
    refrescar_estados
    titulo
    panel_estado
    local estado_bhttp
    estado_bhttp="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"

    echo -e "  ${MAGENTA}${BOLD}MENÚ PRINCIPAL${RESET}  ${GRAY}• comandos: ${NEON_PINK}adm${GRAY} / ${NEON_PINK}admin${RESET}"
    linea
    printf "  ${NEON_GREEN}[%2s]${RESET} %-32s ${NEON_GREEN}[%2s]${RESET} %s\n" 1 "Instalar / Reinstalar BHTTP" 2 "Gestionar usuarios"
    printf "  ${NEON_GREEN}[%2s]${RESET} %-32s ${NEON_GREEN}[%2s]${RESET} %s\n" 3 "Encender / Apagar BHTTP" 4 "Abrir puertos manuales"
    printf "  ${NEON_GREEN}[%2s]${RESET} %-32s ${NEON_GREEN}[%2s]${RESET} %s\n" 5 "BadVPN Gateway" 6 "Actualizar desde GitHub"
    printf "  ${NEON_GREEN}[%2s]${RESET} %-32s ${NEON_GREEN}[%2s]${RESET} %s\n" 7 "Liberar memoria RAM" 8 "Auto iniciar script"
    printf "  ${NEON_GREEN}[%2s]${RESET} %-32s ${NEON_GREEN}[%2s]${RESET} %s\n" 9 "Optimización automática" 10 "BHTTP BBR (red)"
    printf "  ${RED}[%2s]${RESET} %-32s ${RED}[%2s]${RESET} %s\n" 11 "Destrucción total" 0 "Salir"
    linea
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Opción: ")" opc
    case "$opc" in
      1) instalar_servidor ;;
      2) menu_usuarios ;;
      3)
        titulo; seccion "CONTROL DE ESTADO BHTTP"
        if [ "$estado_bhttp" = "active" ]; then
          systemctl stop "$SERVICE" 2>/dev/null || true; systemctl disable "$SERVICE" 2>/dev/null || true; ok "BHTTP detenido."
        else
          systemctl enable "$SERVICE" 2>/dev/null || true; systemctl start "$SERVICE" 2>/dev/null || true; ok "BHTTP iniciado."
        fi
        pausa ;;
      4) menu_activar_puertos ;;
      5) menu_optimizar_vps ;;
      6) actualizar_script ;;
      7) titulo; seccion "LIBERAR MEMORIA RAM"; ejecutar_optimizacion_manual; pausa ;;
      8) menu_autostart ;;
      9) menu_optimizacion_automatica ;;
      10) menu_bhttp_bbr ;;
      11) destruir_script_total ;;
      0) clear_screen; exit 0 ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}
BLOQUE_NUEVO_EOF

python3 - "$TARGET" "$TMPB" "$TMPN" <<'PYEOF'
import sys
target, bloque, salida = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(target, encoding="utf-8", errors="surrogateescape").read().replace("\r\n", "\n")
if "# === PARCHE HAZAEL v2" in src:
    sys.exit(3)
ini = src.find("\nmenu_principal(){")
fin = src.rfind("\ncheck_root\ncargar_config\nmenu_principal")
if ini < 0 or fin < 0 or fin < ini:
    sys.exit(2)
nuevo = src[:ini + 1] + open(bloque, encoding="utf-8").read().rstrip("\n") + "\n" + src[fin:]
open(salida, "w", encoding="utf-8", errors="surrogateescape").write(nuevo)
PYEOF
rc=$?
case "$rc" in
  0) ;;
  3) echo "ℹ Este script ya tiene el parche aplicado. No se hizo nada."; rm -f "$BACKUP"; exit 0 ;;
  2) echo "✖ No reconocí la estructura de intalar.sh (menu_principal / llamada final). No se modificó nada."; exit 1 ;;
  *) echo "✖ Error aplicando el parche. No se modificó nada."; exit 1 ;;
esac

if ! bash -n "$TMPN" 2>/dev/null; then
  echo "✖ El resultado tenía errores de sintaxis. No se modificó nada."
  exit 1
fi

cp "$TMPN" "$TARGET" && chmod +x "$TARGET" || { echo "✖ No pude escribir $TARGET"; exit 1; }
echo "✔ Parche aplicado a: $TARGET"
echo "✔ Respaldo guardado en: $BACKUP"
echo "▶ Ejecuta:  sudo bash $TARGET   (o el comando adm)"
