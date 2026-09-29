#!/usr/bin/env bash
# ==============================================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER - ULTRA CYBER EDITION
#        BHTTP V.1 & BADVPN PROTOCOL (TIGO Y CLARO NICARAGUA FULL)
#        PREMIUM SERVER EDITION v8.0 (Con Opción de Destrucción Total [11])
# ==============================================================================

set -o pipefail

# ==============================================================================
# PALETA DE COLORES VIBRANTES Y NEÓN
# ==============================================================================
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED="\e[1;91m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

SKY="\e[38;5;117m"
NEON_BLUE="\e[38;5;39m"
NEON_GREEN="\e[38;5;46m"
NEON_PINK="\e[38;5;198m"
NEON_ORANGE="\e[38;5;208m"

# ==============================================================================
# RUTAS Y DIRECTORIOS DEL SISTEMA
# ==============================================================================
DESTDIR="/usr/local/lib/bhttp"
SERVER_PY="$DESTDIR/bhttp-server.py"
UNIT="/etc/systemd/system/bhttp.service"
BADVPN_UNIT="/etc/systemd/system/badvpn.service"
SERVICE="bhttp"
BADVPN_SERVICE="badvpn"
CONFIG_DIR="/etc/bhttp"
CONFIG="$CONFIG_DIR/nullcore.conf"
USERS_FILE="$CONFIG_DIR/cuentas.txt"
SCRIPT_PATH="/usr/local/bin/intalar.sh"
ADM_BIN="/usr/local/bin/adm"
ADMIN_BIN="/usr/local/bin/admin"

PUERTO="443"
SSHPORT=22
BADVPN_PORT=7300
BADVPN_STATE="OFF"
AUTOSTART_STATUS="OFF"
CRON_STATUS="OFF"
BBR_STATUS="OFF"

# ==============================================================================
# CONFIGURACIÓN BLINDADA DE COMANDOS RÁPIDOS ("adm" / "admin")
# ==============================================================================
configurar_atajo_adm() {
  if [ "$0" != "$SCRIPT_PATH" ] && [ -f "$0" ]; then
    cp "$0" "$SCRIPT_PATH" 2>/dev/null || true
  fi
  chmod +x "$SCRIPT_PATH" 2>/dev/null || true

  cat > "$ADM_BIN" << 'EOF'
#!/usr/bin/env bash
exec sudo bash /usr/local/bin/intalar.sh "$@"
EOF
  chmod +x "$ADM_BIN"

  cat > "$ADMIN_BIN" << 'EOF'
#!/usr/bin/env bash
exec sudo bash /usr/local/bin/intalar.sh "$@"
EOF
  chmod +x "$ADMIN_BIN"

  for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
    if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
      touch "$rc" 2>/dev/null
      sed -i '/alias adm=/d' "$rc" 2>/dev/null
      sed -i '/alias admin=/d' "$rc" 2>/dev/null
      echo "alias adm='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
      echo "alias admin='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
    fi
  done
}

# ==============================================================================
# GESTIÓN GLOBAL DE FIREWALL (TCP Y UDP)
# ==============================================================================
abrir_puerto_sistema() {
    local p_custom="$1"
    info "Aplicando reglas de red y firewall para el puerto $p_custom..."

    if command -v ufw >/dev/null 2>&1; then
        ufw allow "$p_custom"/tcp >/dev/null 2>&1
        ufw allow "$p_custom"/udp >/dev/null 2>&1
        ufw allow "$BADVPN_PORT"/tcp >/dev/null 2>&1
        ufw allow "$BADVPN_PORT"/udp >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1 || true
    fi

    if command -v iptables >/dev/null 2>&1; then
        iptables -A INPUT -p tcp --dport "$p_custom" -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p udp --dport "$p_custom" -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport "$BADVPN_PORT" -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p udp --dport "$BADVPN_PORT" -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
        
        if command -v netfilter-persistent >/dev/null 2>&1; then
            netfilter-persistent save >/dev/null 2>&1 || true
        elif [ -d /etc/iptables ]; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
    fi
    ok "Puertos y firewall actualizados correctamente."
}

# ==============================================================================
# INTERFAZ VISUAL CYBERPUNK
# ==============================================================================
clear_screen() { clear 2>/dev/null || true; }
linea() { echo -e "${NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

obtener_ip_publica() {
    local ip_pub
    ip_pub=$(curl -fsS --max-time 2 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
    [ -z "$ip_pub" ] && ip_pub="127.0.0.1"
    echo "$ip_pub"
}

titulo() {
    clear_screen
    local ip_maquina
    ip_maquina=$(obtener_ip_publica)
    echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_GREEN}${BOLD}                   HAZAEL MORENO MULTI SCRIPT${RESET}              ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_BLUE}${BOLD}            BHTTP V.1 & BADVPN PROTOCOL v8.0${RESET}             ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${SKY}     🚀 ${NEON_ORANGE}TIGO Y CLARO NICARAGUA${RESET} ${SKY}• IP: ${YELLOW}${BOLD}$ip_maquina${RESET} 🚀${RESET}"
    echo
}

seccion() {
    echo
    echo -e "${MAGENTA}┌──────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${RESET} ${WHITE}${BOLD} $1${RESET}"
    echo -e "${MAGENTA}└──────────────────────────────────────────────────────────────────┘${RESET}"
    echo
}

ok() { echo -e " ${NEON_GREEN}✔ [ÉXITO]${RESET} ${WHITE}$1${RESET}"; }
info() { echo -e " ${SKY}◆ [INFO]${RESET} ${WHITE}$1${RESET}"; }
fail() { echo -e " ${RED}✖ [ERROR]${RESET} ${WHITE}$1${RESET}"; }

pausa() {
    echo
    echo -e "${GRAY} Presiona ${NEON_GREEN}[Enter]${GRAY} para regresar...${RESET}"
    read -r
}

check_root() {
  if [ "$(id -u 2>/dev/null || echo 0)" != 0 ]; then
    fail "Este script debe ejecutarse como root: sudo bash $0"
    exit 2
  fi
}

cargar_config() {
  mkdir -p "$CONFIG_DIR"
  [ -f "$CONFIG" ] && source "$CONFIG"
  [ -z "${PUERTO:-}" ] && PUERTO="443"
  [ -z "${SSHPORT:-}" ] && SSHPORT=22
  [ -z "${BADVPN_PORT:-}" ] && BADVPN_PORT=7300
  [ -z "${BADVPN_STATE:-}" ] && BADVPN_STATE="OFF"
  [ -z "${AUTOSTART_STATUS:-}" ] && AUTOSTART_STATUS="OFF"
  [ -z "${CRON_STATUS:-}" ] && CRON_STATUS="OFF"
  [ -z "${BBR_STATUS:-}" ] && BBR_STATUS="OFF"
}

guardar_config() {
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG" <<EOF
PUERTO=${PUERTO}
SSHPORT=${SSHPORT}
BADVPN_PORT=${BADVPN_PORT}
BADVPN_STATE=${BADVPN_STATE}
AUTOSTART_STATUS=${AUTOSTART_STATUS}
CRON_STATUS=${CRON_STATUS}
BBR_STATUS=${BBR_STATUS}
EOF
}

# ==============================================================================
# INSTALACIÓN Y CONFIGURACIÓN DE BADVPN
# ==============================================================================
instalar_badvpn() {
    apt-get update -y >/dev/null 2>&1
    apt-get install -y cmake g++ make wget curl badvpn iptables-persistent 2>/dev/null || true

    local bin_badvpn=""
    if [ -f /usr/bin/badvpn-udpgw ]; then
        bin_badvpn="/usr/bin/badvpn-udpgw"
    elif [ -f /usr/local/bin/badvpn-udpgw ]; then
        bin_badvpn="/usr/local/bin/badvpn-udpgw"
    else
        bin_badvpn="$(which badvpn-udpgw 2>/dev/null || echo "/usr/bin/badvpn-udpgw")"
    fi

    cat > "$BADVPN_UNIT" <<EOF
[Unit]
Description=BadVPN UDP Gateway (Estabilidad de Llamadas y Juegos)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$bin_badvpn --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 1000 --max-connections 2000
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable badvpn >/dev/null 2>&1
    systemctl restart badvpn >/dev/null 2>&1
}

# ==============================================================================
# INSTALACIÓN DE BHTTP SERVER (FIXED ENGINE v8.0)
# ==============================================================================
instalar_servidor() {
  titulo
  seccion "INSTALACIÓN Y CONFIGURACIÓN DE PUERTO BHTTP"
  
  command -v python3 >/dev/null 2>&1 || { fail "Python3 no está instalado."; pausa; return 1; }
  
  local sugerido="${PUERTO:-443}"
  echo -e "  ${WHITE}Puerto BHTTP actual/sugerido:${RESET} ${NEON_GREEN}$sugerido${RESET}"
  echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el nuevo puerto BHTTP (Presiona Enter para mantener $sugerido): "
  read -r nuevo_puerto
  
  if [ -n "$nuevo_puerto" ]; then
    if [[ "$nuevo_puerto" =~ ^[0-9]+$ ]] && [ "$nuevo_puerto" -gt 0 ] && [ "$nuevo_puerto" -le 65535 ]; then
      PUERTO="$nuevo_puerto"
    else
      fail "Puerto inválido. Se mantendrá el puerto anterior: $sugerido"
    fi
  else
    PUERTO="$sugerido"
  fi

  abrir_puerto_sistema "$PUERTO"

  mkdir -p "$DESTDIR"
  cat > "$SERVER_PY" << 'PYEOF'
#!/usr/bin/env python3
import argparse, asyncio, hashlib, sys

MAGIC = b"BHP1"
LONGPOLL = 2.5

def keystream(sess, mode, seq, d, n):
    base = hashlib.sha256(sess + bytes([mode]) + seq.to_bytes(8, "big") + bytes([d]))
    out = bytearray()
    c = 0
    while len(out) < n:
        h = base.copy()
        h.update(c.to_bytes(4, "big"))
        out += h.digest()
        c += 1
    return bytes(out[:n])

def mask(data, sess, mode, seq, d):
    return bytes(a ^ b for a, b in zip(data, keystream(sess, mode, seq, d, len(data))))

def probe_reply(mode, size):
    n = size if (mode == 2 and size >= 10) else 10
    out = bytearray(MAGIC + bytes([1, mode]) + size.to_bytes(4, "big"))
    for i in range(10, n):
        out.append((i * 31) & 255)
    return bytes(out)

class Session:
    def __init__(self, sess, backend):
        self.sess = sess
        self.backend = backend
        self.queue = asyncio.Queue()
        self.write_lock = asyncio.Lock()
        self.down_raw = bytearray()
        self.closed = False
        self.br = None
        self.bw = None

    async def connect(self):
        host, port = self.backend
        self.br, self.bw = await asyncio.open_connection(host, port)
        asyncio.create_task(self._reader())

    async def _reader(self):
        try:
            while not self.closed:
                data = await self.br.read(65536)
                if not data:
                    break
                self.down_raw.extend(data)
                self.queue.put_nowait(True)
        except Exception:
            pass
        finally:
            self.closed = True
            self.queue.put_nowait(False)

    async def upload(self, data):
        if not data or self.closed:
            return
        async with self.write_lock:
            try:
                self.bw.write(data)
                await self.bw.drain()
            except Exception:
                self.closed = True

    async def download(self, maxlen, deadline):
        if maxlen <= 0:
            maxlen = 1399
        loop = asyncio.get_running_loop()
        
        while True:
            if self.down_raw:
                take = bytes(self.down_raw[:maxlen])
                del self.down_raw[:maxlen]
                return take
            if self.closed:
                return b""
            
            timeout = deadline - loop.time()
            if timeout <= 0:
                return b""
            
            try:
                await asyncio.wait_for(self.queue.get(), timeout=max(0.01, timeout))
            except asyncio.TimeoutError:
                return b""

    async def close(self):
        self.closed = True
        try:
            self.bw.close()
            await self.bw.wait_closed()
        except Exception:
            pass

class Server:
    def __init__(self, host, port, backend):
        self.host = host
        self.port = port
        self.backend = backend
        self.sessions = {}
        self.slock = asyncio.Lock()

    async def get_session(self, sess):
        async with self.slock:
            s = self.sessions.get(sess)
            if s is None or s.closed:
                # Limpiar solo sesiones inactivas/cerradas sin destruir activas
                dead = [sid for sid, obj in self.sessions.items() if obj.closed]
                for sid in dead:
                    del self.sessions[sid]
                
                s = Session(sess, self.backend)
                await s.connect()
                self.sessions[sess] = s
            return s

    async def handle(self, reader, writer):
        try:
            while True:
                hdr = await reader.readexactly(29)
                mode = hdr[0]
                sess = hdr[1:17]
                seq = int.from_bytes(hdr[17:25], "big")
                ln = int.from_bytes(hdr[25:29], "big")

                payload = b""
                if ln and mode in (0, 1, 2, 3):
                    raw = await reader.readexactly(ln)
                    payload = mask(raw, sess, mode, seq, 0)

                if payload[:4] == MAGIC:
                    size = int.from_bytes(payload[6:10], "big") if len(payload) >= 10 else 0
                    pmode = payload[5] if len(payload) >= 6 else mode
                    body = mask(probe_reply(pmode, size), sess, mode, seq, 1)
                    writer.write(bytes([0]) + len(body).to_bytes(4, "big") + body)
                    await writer.drain()
                    continue

                s = await self.get_session(sess)

                if mode == 1:
                    await s.upload(payload)
                    writer.write(bytes([0]) + (0).to_bytes(4, "big"))
                    await writer.drain()

                elif mode == 2:
                    chunk = await s.download(ln if ln > 0 else 1399, asyncio.get_running_loop().time() + LONGPOLL)
                    self._send_data(writer, sess, mode, seq, chunk)
                    await writer.drain()

                elif mode == 3:
                    chunk_size = 1399
                    count = 1
                    if len(payload) >= 6:
                        chunk_size = int.from_bytes(payload[0:4], "big")
                        count = payload[5]
                    deadline = asyncio.get_running_loop().time() + LONGPOLL
                    for i in range(count):
                        chunk = await s.download(chunk_size, deadline)
                        self._send_data(writer, sess, mode, seq + i, chunk)
                    await writer.drain()

                elif mode == 4:
                    writer.write(bytes([0]) + (0).to_bytes(4, "big"))
                    await writer.drain()

                else:
                    return

        except Exception:
            pass
        finally:
            try:
                writer.close()
            except Exception:
                pass

    def _send_data(self, writer, sess, mode, seq, data):
        real = len(data)
        masked = mask(data, sess, mode, seq, 1) if data else b""
        body = real.to_bytes(4, "big") + masked
        writer.write(bytes([2]) + len(body).to_bytes(4, "big") + body)

    async def serve(self):
        srv = await asyncio.start_server(self.handle, self.host, self.port, backlog=2048)
        async with srv:
            await srv.serve_forever()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, required=True)
    ap.add_argument("--backend-host", default="127.0.0.1")
    ap.add_argument("--backend-port", type=int, default=22)
    a = ap.parse_args()
    asyncio.run(Server(a.host, a.port, (a.backend_host, a.backend_port)).serve())

if __name__ == "__main__":
    main()
PYEOF
  chmod +x "$SERVER_PY"

  PYBIN="$(command -v python3)"
  cat > "$UNIT" <<EOF
[Unit]
Description=BHTTP Server (puerto $PUERTO)
After=network.target

[Service]
Type=simple
ExecStart=$PYBIN $SERVER_PY --host 0.0.0.0 --port $PUERTO --backend-host 127.0.0.1 --backend-port $SSHPORT
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE" >/dev/null 2>&1
  systemctl restart "$SERVICE" >/dev/null 2>&1
  instalar_badvpn
  configurar_atajo_adm

  ok "¡Servidor BHTTP instalado y encendido en el puerto $PUERTO con motor optimizado v8.0!"
  guardar_config
  pausa
}

# ==============================================================================
# GESTIÓN DE USUARIOS
# ==============================================================================
crear_usuario() {
  local u="$1" p="$2" dias="$3"
  if id "$u" >/dev/null 2>&1; then
    sed -i "/^User: $u /d" "$USERS_FILE" 2>/dev/null
  else
    useradd -M -s /bin/bash "$u" || return 1
  fi
  local pass_hash; pass_hash="$(openssl passwd -6 "$p" 2>/dev/null)"
  usermod -p "$pass_hash" "$u"
  if [[ "$dias" =~ ^[0-9]+$ ]] && [ "$dias" -gt 0 ]; then
    chage -E "$(date -d "+${dias} days" +%Y-%m-%d 2>/dev/null || date -v +${dias}d +%Y-%m-%d 2>/dev/null)" "$u" 2>/dev/null
    DIAS_FINAL="${dias} días"
  else
    chage -E -1 "$u" 2>/dev/null; DIAS_FINAL="Ilimitado"
  fi
  echo "User: $u | Pass: $p | Dias: $DIAS_FINAL" >> "$USERS_FILE"
}

ver_usuarios_en_linea() {
  titulo
  seccion "USUARIOS CONECTADOS EN TIEMPO REAL"
  echo -e " ${WHITE}Monitoreando procesos de login activos...${RESET}"
  linea
  local conectados
  conectados=$(ps aux | grep -E 'sshd:|bhttp' | grep -v grep | grep -v root || true)
  if [ -n "$conectados" ]; then
    echo -e "${NEON_GREEN}$conectados${RESET}"
  else
    info "No hay usuarios conectados activamente en este momento."
  fi
  pausa
}

eliminar_usuario_num() {
  titulo
  seccion "ELIMINAR USUARIO POR NUMERACIÓN"
  if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
    local idx=1
    declare -A map_usuarios
    while IFS= read -r linea_usu; do
      u_name=$(echo "$linea_usu" | grep -oP 'User: \K[^|]+' | xargs)
      map_usuarios[$idx]="$u_name"
      echo -e "  ${NEON_ORANGE}[$idx]${RESET} Usuario: ${NEON_GREEN}$u_name${RESET}"
      idx=$((idx+1))
    done < "$USERS_FILE"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el número de usuario a eliminar [1-$((idx-1))]: "
    read -r num_del
    if [ -n "${map_usuarios[$num_del]:-}" ]; then
      local user_del="${map_usuarios[$num_del]}"
      userdel -f "$user_del" 2>/dev/null || true
      sed -i "/^User: $user_del /d" "$USERS_FILE" 2>/dev/null
      ok "Usuario '$user_del' eliminado correctamente."
    else
      fail "Número de opción no válido."
    fi
  else
    info "No hay usuarios registrados."
  fi
  pausa
}

editar_usuario() {
  titulo
  seccion "EDITAR USUARIO EXISTENTE"
  if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el nombre exacto del usuario a editar: "
    read -r u_edit
    if id "$u_edit" >/dev/null 2>&1; then
      echo -ne " ${NEON_ORANGE}◆${RESET} Nueva Contraseña (Enter para mantener actual): "
      read -r n_pass
      echo -ne " ${NEON_ORANGE}◆${RESET} Añadir días adicionales de vigencia (Ej. 30): "
      read -r n_dias
      
      if [ -n "$n_pass" ]; then
        local pass_hash; pass_hash="$(openssl passwd -6 "$n_pass" 2>/dev/null)"
        usermod -p "$pass_hash" "$u_edit"
      fi
      
      if [[ "$n_dias" =~ ^[0-9]+$ ]] && [ "$n_dias" -gt 0 ]; then
        chage -E "$(date -d "+${n_dias} days" +%Y-%m-%d 2>/dev/null || date -v +${n_dias}d +%Y-%m-%d 2>/dev/null)" "$u_edit" 2>/dev/null
      fi
      ok "Usuario '$u_edit' actualizado con éxito."
    else
      fail "El usuario '$u_edit' no existe en el sistema."
    fi
  else
    info "No hay usuarios registrados."
  fi
  pausa
}

menu_usuarios() {
  while true; do
    titulo
    seccion "GESTIÓN DE USUARIOS Y CREDENCIALES"
    echo -e "  ${NEON_GREEN}[1]
