#!/usr/bin/env bash
# ==============================================================================
# Agrega la OPCIÓN 12 (Proxy WebSocket -> SSH) a tu HAZAEL MORENO MULTI SCRIPT
#
# Uso:   sudo bash agregar-opcion12.sh [ruta_del_script]
# Por defecto parchea: /usr/local/bin/intalar.sh
#
# - Hace respaldo antes de tocar nada (<script>.bak-pre12)
# - Verifica la sintaxis al final; si algo falla, restaura el respaldo
# - No toca tus usuarios (/etc/bhttp/cuentas.txt) ni tu configuración
# ==============================================================================

TARGET="${1:-/usr/local/bin/intalar.sh}"

if [ "$(id -u)" -ne 0 ]; then echo "Ejecuta como root: sudo bash $0"; exit 2; fi
if [ ! -f "$TARGET" ]; then echo "No encuentro $TARGET (pásame la ruta: sudo bash $0 /ruta/script.sh)"; exit 1; fi
if grep -q 'menu_ws_ssh()' "$TARGET"; then echo "La opción 12 ya está instalada en $TARGET"; exit 0; fi

BLOCK="$(mktemp /tmp/bloque12.XXXXXX)"
BAK="${TARGET}.bak-pre12"
cp -a "$TARGET" "$BAK" || { echo "No pude crear el respaldo"; exit 1; }

cat > "$BLOCK" <<'BLOQUE_EOF'
# ==============================================================================
# OPCIÓN 12: PROXY WEBSOCKET -> SSH  (HTTP Custom y similares)
# Usa las MISMAS cuentas del panel que BHTTP: ambos terminan en el sshd local.
# ==============================================================================
WS_SERVICE="bhttp-ws"
WS_UNIT="/etc/systemd/system/${WS_SERVICE}.service"
WS_PY="$DESTDIR/ws-ssh-proxy.py"
WS_CONF="$CONFIG_DIR/ws.conf"
WSPORT=80
SSHD_DROPIN="/etc/ssh/sshd_config.d/00-bhttp-ssh.conf"
SSHD_MARK="# BHTTP-SSH-OPTS"

ws_cargar(){
  WSPORT=80
  [ -f "$WS_CONF" ] && source "$WS_CONF"
  [[ "$WSPORT" =~ ^[0-9]+$ ]] || WSPORT=80
}
ws_guardar(){ mkdir -p "$CONFIG_DIR"; printf 'WSPORT=%s\n' "$WSPORT" > "$WS_CONF"; }
ws_instalado(){ [ -f "$WS_UNIT" ]; }

ws_estado_txt(){
  if ! ws_instalado; then echo "${GRAY}○ NO INSTALADO${RESET}"; else estado_servicio "$WS_SERVICE"; fi
}

ws_fila_panel(){
  ws_cargar
  fila_panel "WebSocket SSH" "$(ws_estado_txt)  ${GRAY}Puerto${RESET} ${NEON_GREEN}${WSPORT}${RESET}"
}

# Devuelve 0 si el puerto lo usa OTRO programa (no nuestro proxy).
ws_puerto_ocupado(){
  local p="$1" l mp
  l="$(ss -Hltnp "( sport = :$p )" 2>/dev/null)"
  [ -z "$l" ] && return 1
  mp="$(systemctl show -p MainPID --value "$WS_SERVICE" 2>/dev/null)"
  if [[ "$mp" =~ ^[0-9]+$ ]] && [ "$mp" -gt 0 ] && grep -q "pid=$mp," <<< "$l"; then
    return 1
  fi
  return 0
}

# ------------------------------------------------------------------------------
# sshd: login por contraseña + reenvío TCP habilitados (causa #1 de "SSH no conecta").
# Se usa un archivo 00-* porque sshd respeta el PRIMER valor leído y
# 50-cloud-init.conf suele traer "PasswordAuthentication no".
# ------------------------------------------------------------------------------
ws_preparar_sshd(){
  local cfg="/etc/ssh/sshd_config" sshd_bin tmp svc restr
  local opts=$'PasswordAuthentication yes\nAllowTcpForwarding yes\nUseDNS no'
  mkdir -p /run/sshd "$CONFIG_DIR"

  sshd_bin="$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)"
  if [ ! -x "$sshd_bin" ]; then
    info "Instalando openssh-server..."
    apt-get install -y openssh-server >/dev/null 2>&1 || { fail "No se pudo instalar openssh-server."; return 1; }
    sshd_bin="$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)"
  fi
  [ -f "$CONFIG_DIR/sshd_config.bak" ] || cp -a "$cfg" "$CONFIG_DIR/sshd_config.bak" 2>/dev/null || true

  if grep -qiE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/' "$cfg"; then
    mkdir -p /etc/ssh/sshd_config.d
    printf '%s\n' "$opts" > "$SSHD_DROPIN"
    if ! "$sshd_bin" -t 2>/dev/null; then
      rm -f "$SSHD_DROPIN"; fail "sshd rechazó la configuración; no se aplicó."; return 1
    fi
  elif ! grep -q "$SSHD_MARK" "$cfg"; then
    cp -a "$cfg" "$cfg.pre-bhttp"
    tmp="$(mktemp)"
    sed -E 's/^[[:space:]]*(PasswordAuthentication|AllowTcpForwarding|UseDNS)\b/#\1/I' "$cfg" > "$tmp"
    { echo "$SSHD_MARK"; printf '%s\n' "$opts"; echo "# ---"; cat "$tmp"; } > "$cfg"
    rm -f "$tmp"
    if ! "$sshd_bin" -t 2>/dev/null; then
      cp -a "$cfg.pre-bhttp" "$cfg"; fail "sshd rechazó la configuración; se restauró la original."; return 1
    fi
  fi

  grep -qx '/bin/bash' /etc/shells 2>/dev/null || echo '/bin/bash' >> /etc/shells
  systemctl enable ssh >/dev/null 2>&1 || systemctl enable sshd >/dev/null 2>&1 || true
  systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null || \
    systemctl start ssh >/dev/null 2>&1 || systemctl start sshd >/dev/null 2>&1 || true
  systemctl reload ssh >/dev/null 2>&1 || systemctl reload sshd >/dev/null 2>&1 || true

  restr="$("$sshd_bin" -T 2>/dev/null | grep -E '^(allowusers|allowgroups|denyusers|denygroups) ' || true)"
  if [ -n "$restr" ]; then
    echo -e "  ${NEON_ORANGE}⚠ sshd tiene restricciones de usuarios (pueden bloquear cuentas nuevas):${RESET}"
    echo "$restr" | sed 's/^/    /'
  fi
  return 0
}

# ------------------------------------------------------------------------------
# Sincroniza las cuentas del panel con el sistema: existen, contraseña igual a la
# guardada, no bloqueadas. Así el mismo usuario sirve para BHTTP y WebSocket SSH.
# ------------------------------------------------------------------------------
ws_sincronizar_usuarios(){
  local linea_u u p total=0 creados=0 st exp t
  local -a expirados=()
  if [ ! -s "$USERS_FILE" ]; then info "No hay usuarios registrados en el panel."; return 0; fi
  while IFS= read -r linea_u; do
    u="$(extraer_usuario "$linea_u")"
    [ -n "$u" ] || continue
    [ "$u" = "root" ] && continue
    [[ "$u" =~ ^[a-zA-Z0-9._-]+$ ]] || continue
    p="${linea_u#*| Pass: }"; p="${p% | Dias: *}"
    if ! id "$u" >/dev/null 2>&1; then
      useradd -M -s /bin/bash "$u" 2>/dev/null && creados=$((creados+1)) || continue
    fi
    if [ -n "$p" ]; then
      usermod -p "$(printf '%s' "$p" | openssl passwd -6 -stdin 2>/dev/null)" "$u" 2>/dev/null || true
    fi
    st="$(passwd -S "$u" 2>/dev/null | awk '{print $2}')"
    [ "$st" = "L" ] && usermod -U "$u" 2>/dev/null || true
    exp="$(chage -l "$u" 2>/dev/null | awk -F': ' '/Account expires/{print $2}')"
    if [ -n "$exp" ] && [ "$exp" != "never" ]; then
      t="$(date -d "$exp" +%s 2>/dev/null || echo 0)"
      if [ "$t" -gt 0 ] && [ "$t" -lt "$(date +%s)" ]; then expirados+=("$u"); fi
    fi
    total=$((total+1))
  done < "$USERS_FILE"
  ok "Usuarios verificados: $total (recreados: $creados)."
  if [ "${#expirados[@]}" -gt 0 ]; then
    echo -e "  ${NEON_ORANGE}⚠ Cuentas con vigencia vencida (no podrán entrar):${RESET} ${WHITE}${expirados[*]}${RESET}"
    echo -e "  ${GRAY}Renueva los días en: Gestionar usuarios → Editar usuario.${RESET}"
  fi
}

ws_escribir_proxy(){
  mkdir -p "$DESTDIR"
  cat > "$WS_PY" <<'WSPYEOF'
#!/usr/bin/env python3
# Proxy HTTP/"WebSocket" -> SSH. Tras responder 101/200 el tráfico va SIN frames
# (túnel crudo), que es lo que esperan HTTP Custom y clientes similares.
import argparse, asyncio, logging, re, socket

BUF = 65536
HTTP_VERBS = (b"GET ", b"POST ", b"HEAD ", b"PUT ", b"CONNECT ", b"OPTIONS ", b"DELETE ", b"PATCH ")
RE_UPGRADE = re.compile(rb"(?im)^upgrade:\s*websocket")
log = logging.getLogger("ws-ssh")

def limpiar(rest):
    while True:
        rest = rest.lstrip(b"\r\n")
        if rest.startswith(HTTP_VERBS) and b"\r\n\r\n" in rest:
            rest = rest.split(b"\r\n\r\n", 1)[1]
        else:
            return rest

async def leer_cabecera(reader):
    data = b""
    while b"\r\n\r\n" not in data:
        chunk = await asyncio.wait_for(reader.read(4096), timeout=15)
        if not chunk or len(data) > 16384:
            return None, b""
        data += chunk
    head, _, rest = data.partition(b"\r\n\r\n")
    return head, rest

async def bombear(r, w):
    try:
        while True:
            d = await r.read(BUF)
            if not d:
                break
            w.write(d)
            await w.drain()
    except (ConnectionError, OSError, asyncio.TimeoutError):
        pass
    finally:
        try:
            w.close()
        except Exception:
            pass

async def handle(cr, cw, ssh_host, ssh_port):
    peer = cw.get_extra_info("peername")
    sw = None
    try:
        head, rest = await leer_cabecera(cr)
        if head is None:
            return
        log.info("%s %s", peer[0] if peer else "?", head.split(b"\r\n", 1)[0][:80].decode("latin-1"))
        try:
            sr, sw = await asyncio.wait_for(asyncio.open_connection(ssh_host, ssh_port), 10)
        except Exception as e:
            log.error("SSH %s:%s no responde: %s", ssh_host, ssh_port, e)
            try:
                cw.write(b"HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                await cw.drain()
            except Exception:
                pass
            return
        if RE_UPGRADE.search(head):
            cw.write(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        else:
            # sin cuerpo ni Content-Length: si no, se pega al banner SSH
            cw.write(b"HTTP/1.1 200 Connection established\r\n\r\n")
        for w in (cw, sw):
            s = w.get_extra_info("socket")
            if s is not None:
                s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                s.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        rest = limpiar(rest)
        if rest:
            sw.write(rest)
        await cw.drain()
        t1 = asyncio.create_task(bombear(cr, sw))
        t2 = asyncio.create_task(bombear(sr, cw))
        await asyncio.wait({t1, t2}, return_when=asyncio.FIRST_COMPLETED)
        for t in (t1, t2):
            t.cancel()
        await asyncio.gather(t1, t2, return_exceptions=True)
    except (asyncio.TimeoutError, asyncio.IncompleteReadError, ConnectionError, OSError):
        pass
    except Exception as e:
        log.error("Error con %s: %s", peer, e)
    finally:
        for w in (cw, sw):
            try:
                if w is not None:
                    w.close()
            except Exception:
                pass

async def main_async(a):
    srv = await asyncio.start_server(
        lambda r, w: handle(r, w, a.ssh_host, a.ssh_port),
        a.host, a.port, backlog=512, limit=BUF)
    log.info("Escuchando en %s:%s -> SSH %s:%s", a.host, a.port, a.ssh_host, a.ssh_port)
    async with srv:
        await srv.serve_forever()

def main():
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, required=True)
    ap.add_argument("--ssh-host", default="127.0.0.1")
    ap.add_argument("--ssh-port", type=int, default=22)
    a = ap.parse_args()
    try:
        asyncio.run(main_async(a))
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
WSPYEOF
  chmod +x "$WS_PY"
  python3 -m py_compile "$WS_PY" 2>/dev/null
}

ws_escribir_unit(){
  local pybin; pybin="$(command -v python3)"
  cat > "$WS_UNIT" <<EOF
[Unit]
Description=BHTTP WebSocket to SSH Proxy (puerto $WSPORT)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$pybin $WS_PY --host 0.0.0.0 --port $WSPORT --ssh-host 127.0.0.1 --ssh-port $SSHPORT
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

# Prueba local: handshake WebSocket -> debe llegar el banner SSH-2.0-...
ws_probar(){
  local port="$1" l1="" h="" banner=""
  if ! (exec 9<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
    fail "No se puede conectar a 127.0.0.1:$port (¿servicio apagado?)"; return 1
  fi
  exec 9<>"/dev/tcp/127.0.0.1/$port"
  printf 'GET / HTTP/1.1\r\nHost: localhost\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n' >&9
  IFS= read -r -t 4 l1 <&9 || true
  while IFS= read -r -t 4 h <&9; do h="${h%$'\r'}"; [ -z "$h" ] && break; done
  IFS= read -r -t 4 banner <&9 || true
  exec 9<&- 9>&-
  l1="${l1%$'\r'}"; banner="${banner%$'\r'}"
  echo -e "  ${GRAY}Respuesta:${RESET} ${WHITE}${l1:-(vacía)}${RESET}"
  echo -e "  ${GRAY}Banner SSH:${RESET} ${WHITE}${banner:-(vacío)}${RESET}"
  if [[ "$l1" == *101* ]] && [[ "$banner" == SSH-* ]]; then
    ok "Prueba correcta: WebSocket → SSH funciona."
    return 0
  fi
  fail "La prueba falló. Revisa que sshd escuche en el puerto $SSHPORT y los logs (opción 6)."
  return 1
}

ws_instalar(){
  titulo; seccion "INSTALAR / REINSTALAR PROXY WEBSOCKET → SSH"
  command -v python3 >/dev/null 2>&1 || { fail "Python3 no está instalado."; pausa; return 1; }
  ws_cargar
  local nuevo
  echo -e "  ${WHITE}Puerto actual/sugerido:${RESET} ${NEON_GREEN}$WSPORT${RESET}  ${GRAY}(80 es el típico; 8080 si el 80 está ocupado)${RESET}"
  read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Puerto WebSocket (Enter mantiene $WSPORT): ")" nuevo
  if [ -n "$nuevo" ]; then
    if [[ "$nuevo" =~ ^[0-9]+$ ]] && [ "$nuevo" -ge 1 ] && [ "$nuevo" -le 65535 ]; then
      WSPORT="$nuevo"
    else
      fail "Puerto inválido."; pausa; return 1
    fi
  fi
  if [ "$WSPORT" = "$PUERTO" ]; then
    fail "El puerto $WSPORT ya lo usa BHTTP. Elige otro."; pausa; return 1
  fi
  if ws_puerto_ocupado "$WSPORT"; then
    fail "El puerto $WSPORT está en uso por otro programa:"
    ss -ltnp "( sport = :$WSPORT )" 2>/dev/null | sed 's/^/    /'
    info "Apaga ese servicio (nginx/apache) o elige otro puerto."
    pausa; return 1
  fi

  info "Escribiendo proxy..."
  ws_escribir_proxy || { fail "Error de sintaxis en el proxy Python."; pausa; return 1; }
  ws_escribir_unit
  systemctl enable "$WS_SERVICE" >/dev/null 2>&1 || true
  systemctl restart "$WS_SERVICE" >/dev/null 2>&1 || true
  abrir_puerto_sistema "$WSPORT"
  info "Preparando SSH (contraseñas + túneles)..."
  ws_preparar_sshd || true
  info "Sincronizando usuarios del panel..."
  ws_sincronizar_usuarios
  ws_guardar
  sleep 1

  if systemctl is-active --quiet "$WS_SERVICE"; then
    ok "Proxy WebSocket activo en el puerto $WSPORT → SSH $SSHPORT."
    ws_probar "$WSPORT" || true
    ws_mostrar_ayuda
  else
    fail "El servicio no arrancó. Últimos logs:"
    journalctl -u "$WS_SERVICE" -n 15 --no-pager 2>/dev/null
  fi
  pausa
}

ws_mostrar_ayuda(){
  local ip; ip="$(obtener_ip_publica)"
  echo
  echo -e "  ${NEON_BLUE}┌─ ${WHITE}${BOLD}DATOS PARA HTTP CUSTOM${RESET} ${NEON_BLUE}─────────────────────────────────${RESET}"
  echo -e "  ${NEON_BLUE}│${RESET} ${GRAY}SSH Host:${RESET} ${YELLOW}${ip}${RESET}   ${GRAY}Puerto:${RESET} ${NEON_GREEN}${WSPORT}${RESET}"
  echo -e "  ${NEON_BLUE}│${RESET} ${GRAY}Usuario/Clave:${RESET} los creados en «Gestionar usuarios»"
  echo -e "  ${NEON_BLUE}│${RESET} ${GRAY}Payload:${RESET} GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf]"
  echo -e "  ${NEON_BLUE}└──────────────────────────────────────────────────────────${RESET}"
}

ws_desinstalar(){
  local c
  read -r -p "$(echo -e " ${RED}◆${RESET} ¿Desinstalar el proxy WebSocket? (s/N): ")" c
  if [[ "$c" =~ ^[sSyY]$ ]]; then
    systemctl stop "$WS_SERVICE" >/dev/null 2>&1 || true
    systemctl disable "$WS_SERVICE" >/dev/null 2>&1 || true
    rm -f "$WS_UNIT" "$WS_PY" "$WS_CONF"
    systemctl daemon-reload >/dev/null 2>&1 || true
    ok "Proxy WebSocket desinstalado. (Ajustes de sshd y usuarios se conservan)"
  else
    info "Cancelado."
  fi
}

# Limpieza silenciosa para «Destrucción total».
ws_limpiar_total(){
  systemctl stop "$WS_SERVICE" >/dev/null 2>&1 || true
  systemctl disable "$WS_SERVICE" >/dev/null 2>&1 || true
  rm -f "$WS_UNIT" "$WS_PY" "$WS_CONF"
  if [ -f "$SSHD_DROPIN" ]; then
    rm -f "$SSHD_DROPIN"
  fi
  if grep -q "$SSHD_MARK" /etc/ssh/sshd_config 2>/dev/null && [ -f /etc/ssh/sshd_config.pre-bhttp ]; then
    cp -a /etc/ssh/sshd_config.pre-bhttp /etc/ssh/sshd_config
    rm -f /etc/ssh/sshd_config.pre-bhttp
  fi
  systemctl reload ssh >/dev/null 2>&1 || systemctl reload sshd >/dev/null 2>&1 || true
}

menu_ws_ssh(){
  while true; do
    ws_cargar
    titulo; seccion "PROXY WEBSOCKET → SSH  (HTTP Custom / injectors)"
    local conx=0
    if ws_instalado; then
      conx="$(ss -Hnt state established "( sport = :$WSPORT )" 2>/dev/null | wc -l)"
    fi
    echo -e "  ${WHITE}Estado:${RESET} $(ws_estado_txt)   ${WHITE}Puerto WS:${RESET} ${NEON_GREEN}${WSPORT}${RESET}   ${WHITE}SSH:${RESET} ${NEON_GREEN}${SSHPORT}${RESET}   ${WHITE}Conexiones:${RESET} ${NEON_ORANGE}${conx}${RESET}"
    echo -e "  ${GRAY}Los usuarios de «Gestionar usuarios» sirven para BHTTP y para WebSocket SSH.${RESET}"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar proxy WebSocket (cambia puerto)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Encender / Apagar"
    echo -e "  ${NEON_GREEN}[3]${RESET} Verificar y reparar SSH + usuarios"
    echo -e "  ${NEON_GREEN}[4]${RESET} Prueba local de conexión"
    echo -e "  ${NEON_GREEN}[5]${RESET} Datos para HTTP Custom (payload)"
    echo -e "  ${NEON_GREEN}[6]${RESET} Ver logs"
    echo -e "  ${RED}[7]${RESET} Desinstalar proxy WebSocket"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Opción: ")" op
    case "$op" in
      1) ws_instalar ;;
      2)
        if ! ws_instalado; then fail "Primero instala el proxy (opción 1)."
        elif systemctl is-active --quiet "$WS_SERVICE"; then
          systemctl stop "$WS_SERVICE" 2>/dev/null || true; systemctl disable "$WS_SERVICE" >/dev/null 2>&1 || true
          ok "Proxy WebSocket detenido."
        else
          if ws_puerto_ocupado "$WSPORT"; then fail "El puerto $WSPORT está ocupado por otro programa."
          else
            systemctl enable "$WS_SERVICE" >/dev/null 2>&1 || true; systemctl start "$WS_SERVICE" 2>/dev/null || true
            sleep 1
            systemctl is-active --quiet "$WS_SERVICE" && ok "Proxy WebSocket iniciado." || fail "No pudo iniciar (ver logs, opción 6)."
          fi
        fi
        pausa ;;
      3)
        titulo; seccion "VERIFICAR Y REPARAR SSH + USUARIOS"
        ws_preparar_sshd && ok "sshd listo (contraseñas y túneles habilitados)."
        ws_sincronizar_usuarios
        echo
        info "Valores efectivos de sshd:"
        "$(command -v sshd || echo /usr/sbin/sshd)" -T 2>/dev/null | grep -Ei '^(port|passwordauthentication|allowtcpforwarding|usepam) ' | sed 's/^/    /'
        if ss -tln "( sport = :$SSHPORT )" 2>/dev/null | grep -q LISTEN; then ok "SSH escuchando en el puerto $SSHPORT."
        else fail "Nada escucha en el puerto $SSHPORT: revisa SSHPORT o el servicio ssh."; fi
        echo -e "  ${GRAY}Si usas Oracle/AWS/Google/Azure abre también los puertos en el panel del proveedor.${RESET}"
        pausa ;;
      4)
        titulo; seccion "PRUEBA LOCAL"
        if ws_instalado && systemctl is-active --quiet "$WS_SERVICE"; then ws_probar "$WSPORT"; else fail "El proxy no está activo."; fi
        pausa ;;
      5) titulo; seccion "DATOS PARA HTTP CUSTOM"; ws_mostrar_ayuda; pausa ;;
      6)
        titulo; seccion "LOGS DEL PROXY WEBSOCKET"
        if ws_instalado; then journalctl -u "$WS_SERVICE" -n 40 --no-pager 2>/dev/null; else info "No instalado."; fi
        pausa ;;
      7) titulo; seccion "DESINSTALAR"; ws_desinstalar; pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

BLOQUE_EOF

python3 - "$TARGET" "$BLOCK" <<'PATCH_PY'
import re, sys
target, block_path = sys.argv[1], sys.argv[2]
src = open(target, encoding="utf-8").read()
block = open(block_path, encoding="utf-8").read()

def sub_once(pattern, repl, text, name, flags=re.M):
    new, n = re.subn(pattern, repl, text, count=0, flags=flags)
    if n != 1:
        print(f"ERROR: ancla '{name}' encontrada {n} veces (se esperaba 1). No se modificó nada.")
        sys.exit(3)
    return new

# 1) Funciones nuevas, antes de fila_menu()
src = sub_once(r'^fila_menu\(\)\{', lambda m: block + 'fila_menu(){', src, 'fila_menu()')

# 2) Fila del menú principal
src = sub_once(
    r'^(\s*)fila_menu 11 "Destrucci.n total" 0 "Salir" "\$RED"\s*$',
    lambda m: (m.group(1) + 'printf "  ${NEON_GREEN}[12]${RESET} %-32s ${RED}[11]${RESET} Destrucción total\\n" "Proxy WebSocket SSH"\n'
               + m.group(1) + 'printf "  ${RED}[ 0]${RESET} Salir\\n"'),
    src, 'fila_menu 11')

# 3) case del menú
src = sub_once(r'^(\s*)11\) destruir_script_total ;;\s*$',
               lambda m: m.group(0).rstrip('\n') + '\n' + m.group(1) + '12) menu_ws_ssh ;;', src, 'case 11)')

# 4) Destrucción total también limpia el proxy WS
src = sub_once(r'^(\s*)rm -f "\$UNIT" "\$BADVPN_UNIT"\s*$',
               lambda m: m.group(0).rstrip('\n') + '\n' + m.group(1) + 'ws_limpiar_total', src, 'rm -f UNIT')

# 5) Fila en el panel de estado
src = sub_once(r'^(\s*fila_panel "SSH backend".*)$',
               lambda m: m.group(1) + '\n  ws_fila_panel', src, 'fila_panel SSH backend')

# 6) Al instalar BHTTP, dejar sshd listo también (contraseñas + túneles)
src = sub_once(r'^(\s*)instalar_badvpn \|\| true\s*$',
               lambda m: m.group(0).rstrip('\n') + '\n' + m.group(1) + 'ws_preparar_sshd >/dev/null 2>&1 || true', src, 'instalar_badvpn || true')

open(target, "w", encoding="utf-8").write(src)
print("OK: parche aplicado")
PATCH_PY
RC=$?
rm -f "$BLOCK"

if [ $RC -ne 0 ]; then
  cp -a "$BAK" "$TARGET"
  echo "Falló el parche; se restauró el original ($BAK)."
  exit 1
fi

if ! bash -n "$TARGET" 2>/tmp/parche12.err; then
  echo "El script resultante tiene errores de sintaxis:"; cat /tmp/parche12.err
  cp -a "$BAK" "$TARGET"
  echo "Se restauró el original."
  exit 1
fi

chmod +x "$TARGET"
# Si tu panel se ejecuta desde otra ruta, mantén sincronizada la copia que usan adm/admin
if [ "$TARGET" != "/usr/local/bin/intalar.sh" ] && [ -f /usr/local/bin/intalar.sh ]; then
  cp -f "$TARGET" /usr/local/bin/intalar.sh
fi

echo
echo "✔ Opción 12 agregada a: $TARGET"
echo "  Respaldo: $BAK"
echo "  Ábrelo con: adm   (o: sudo bash $TARGET)  y entra a la opción 12"
echo "  Nota: la opción 6 (Actualizar desde GitHub) sobrescribe el script y quita la 12,"
echo "        a menos que subas a tu GitHub la versión ya parchada."
