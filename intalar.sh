#!/usr/init/env bash
# ==============================================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER - ULTRA CYBER EDITION
#        BHTTP V.1 & BADVPN PROTOCOL (TIGO Y CLARO NICARAGUA FULL)
#        PREMIUM SERVER EDITION v8.1 (Con HTTP Puro y Indicadores Verdes)
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

# Estados de las Herramientas Super Avanzadas
KEEPALIVE_STATUS="OFF"
PROTECT_BHTTP_STATUS="OFF"
FAST_CONN_STATUS="OFF"

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
        iptables -A INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 7300 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 8880 -j ACCEPT 2>/dev/null || true
        
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
    echo -e "${NEON_PINK}║${RESET} ${NEON_GREEN}${BOLD}  HAZAEL MORENO MULTI SCRIPT${RESET}              ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_BLUE}${BOLD}   BHTTP V.1 & BADVPN PROTOCOL v8.1${RESET}             ${NEON_PINK}║${RESET}"
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
  [ -z "${KEEPALIVE_STATUS:-}" ] && KEEPALIVE_STATUS="OFF"
  [ -z "${PROTECT_BHTTP_STATUS:-}" ] && PROTECT_BHTTP_STATUS="OFF"
  [ -z "${FAST_CONN_STATUS:-}" ] && FAST_CONN_STATUS="OFF"
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
KEEPALIVE_STATUS=${KEEPALIVE_STATUS}
PROTECT_BHTTP_STATUS=${PROTECT_BHTTP_STATUS}
FAST_CONN_STATUS=${FAST_CONN_STATUS}
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
ExecStart=$bin_badvpn --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 500 --max-connections 1000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
}

# ==============================================================================
# INSTALACIÓN DE BHTTP SERVER CON HTTP PURO (EVITA BLOQUEOS)
# ==============================================================================
instalar_servidor() {
  titulo
  seccion "INSTALACIÓN Y CONFIGURACIÓN DE PUERTO BHTTP (HTTP PURO)"
  
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
LONGPOLL = 2.0

def keystream(sess, mode, seq, d, n):
    base = hashlib.sha256(sess + bytes([mode]) + seq.to_bytes(8, "big") + bytes([d]))
    out = bytearray(); c = 0
    while len(out) < n:
        h = base.copy(); h.update(c.to_bytes(4, "big")); out += h.digest(); c += 1
    return bytes(out[:n])

def mask(data, sess, mode, seq, d):
    return bytes(a ^ b for a, b in zip(data, keystream(sess, mode, seq, d, len(data))))

def probe_reply(mode, size):
    n = size if (mode == 2 and size >= 10) else 10
    out = bytearray(MAGIC + bytes([1, mode]) + size.to_bytes(4, "big"))
    for i in range(10, n): out.append((i * 31) & 255)
    return bytes(out)

class Session:
    def __init__(self, sess, backend):
        self.sess = sess; self.backend = backend
        self.cond = asyncio.Condition(); self.up_next = 0; self.up_pending = {}
        self.down_raw = bytearray(); self.down_chunks = {}; self.down_assign = 0
        self.eof = False; self.closed = False; self.br = None; self.bw = None

    async def connect(self):
        host, port = self.backend
        self.br, self.bw = await asyncio.open_connection(host, port)
        asyncio.create_task(self._reader())

    async def _reader(self):
        try:
            while True:
                data = await self.br.read(65536)
                if not data: break
                async with self.cond: self.down_raw += data; self.cond.notify_all()
        except Exception: pass
        finally:
            async with self.cond: self.eof = True; self.cond.notify_all()

    async def upload(self, seq, data):
        async with self.cond:
            if data: self.up_pending[seq] = data
            while self.up_next in self.up_pending:
                chunk = self.up_pending.pop(self.up_next)
                try: self.bw.write(chunk); await self.bw.drain()
                except Exception: self.closed = True
                self.up_next += 1

    async def download(self, seq, maxlen, deadline):
        if maxlen <= 0: maxlen = 1399
        loop = asyncio.get_running_loop()
        async with self.cond:
            while True:
                if seq < self.down_assign: return self.down_chunks.get(seq, b"")
                if seq == self.down_assign:
                    if self.down_raw:
                        take = bytes(self.down_raw[:maxlen]); del self.down_raw[:maxlen]
                        self.down_chunks[self.down_assign] = take; self.down_assign += 1
                        self.cond.notify_all(); return take
                    if self.eof: self.down_assign += 1; self.cond.notify_all(); return b""
                if not self.eof and loop.time() < deadline:
                    try: await asyncio.wait_for(self.cond.wait(), timeout=max(0.01, deadline - loop.time()))
                    except asyncio.TimeoutError: pass
                    continue
                while self.down_assign <= seq: self.down_assign += 1
                self.cond.notify_all(); return b""

    async def ack(self, seq):
        async with self.cond:
            for k in [k for k in self.down_chunks if k <= seq]: del self.down_chunks[k]

    async def close(self):
        async with self.cond: self.closed = True; self.cond.notify_all()
        try: self.bw.close()
        except Exception: pass

class Server:
    def __init__(self, host, port, backend):
        self.host, self.port, self.backend = host, port, backend
        self.sessions = {}; self.slock = asyncio.Lock()

    async def get_session(self, sess):
        async with self.slock:
            s = self.sessions.get(sess)
            if s is None or s.closed:
                for old_sid, old in list(self.sessions.items()):
                    if old_sid != sess: await old.close(); del self.sessions[old_sid]
                s = Session(sess, self.backend); await s.connect(); self.sessions[sess] = s
            return s

    async def handle(self, reader, writer):
        try:
            # Captura inicial del handshake HTTP / Headers para camuflaje perfecto
            line = await asyncio.wait_for(reader.readline(), timeout=5.0)
            if not line:
                writer.close(); return
            
            # Responder con HTTP/1.1 200 OK genuino si el cliente manda peticiones HTTP estándar
            if line.startswith(b"GET") or line.startswith(b"POST") or line.startswith(b"CONNECT"):
                while True:
                    l = await reader.readline()
                    if not l or l == b"\r\n" or l == b"\n": break
                
                response = (
                    b"HTTP/1.1 200 OK\r\n"
                    b"Server: nginx/1.18.0\r\n"
                    b"Content-Type: application/octet-stream\r\n"
                    b"Connection: keep-alive\r\n"
                    b"Transfer-Encoding: chunked\r\n\r\n"
                )
                writer.write(response)
                await writer.drain()

            while True:
                hdr = await reader.readexactly(29)
                mode = hdr[0]; sess = hdr[1:17]; seq = int.from_bytes(hdr[17:25], "big"); ln = int.from_bytes(hdr[25:29], "big")
                payload = b""
                if ln and mode in (0, 1, 2, 3):
                    raw = await reader.readexactly(ln); payload = mask(raw, sess, mode, seq, 0)
                if payload[:4] == MAGIC:
                    size = int.from_bytes(payload[6:10], "big") if len(payload) >= 10 else 0
                    pmode = payload[5] if len(payload) >= 6 else mode
                    body = mask(probe_reply(pmode, size), sess, mode, seq, 1)
                    writer.write(bytes([0]) + len(body).to_bytes(4, "big") + body); await writer.drain(); continue
                s = await self.get_session(sess)
                if mode == 1:
                    await s.upload(seq, payload); writer.write(bytes([0]) + (0).to_bytes(4, "big")); await writer.drain()
                elif mode == 2:
                    chunk = await s.download(seq, ln if ln > 0 else 1399, asyncio.get_running_loop().time() + LONGPOLL)
                    self._send_data(writer, sess, mode, seq, chunk); await writer.drain()
                elif mode == 3:
                    chunk_size = 1399; count = 1
                    if len(payload) >= 6: chunk_size = int.from_bytes(payload[0:4], "big"); count = payload[5]
                    deadline = asyncio.get_running_loop().time() + LONGPOLL
                    for i in range(count):
                        chunk = await s.download(seq + i, chunk_size, deadline)
                        self._send_data(writer, sess, mode, seq + i, chunk)
                    await writer.drain()
                elif mode == 4:
                    await s.ack(seq); writer.write(bytes([0]) + (0).to_bytes(4, "big")); await writer.drain()
                else: return
        except Exception: pass
        finally:
            try: writer.close()
            except Exception: pass

    def _send_data(self, writer, sess, mode, seq, data):
        real = len(data)
        masked = mask(data, sess, mode, seq, 1) if data else b""
        body = real.to_bytes(4, "big") + masked
        writer.write(bytes([2]) + len(body).to_bytes(4, "big") + body)

    async def serve(self):
        srv = await asyncio.start_server(self.handle, self.host, self.port, backlog=512)
        async with srv: await srv.serve_forever()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, required=True)
    ap.add_argument("--backend-host", default="127.0.0.1")
    ap.add_argument("--backend-port", type=int, default=22)
    a = ap.parse_args()
    asyncio.run(Server(a.host, a.port, (a.backend_host, a.backend_port)).serve())

if __name__ == "__main__": main()
PYEOF
  chmod +x "$SERVER_PY"

  PYBIN="$(command -v python3)"
  cat > "$UNIT" <<EOF
[Unit]
Description=BHTTP Server HTTP Puro (puerto $PUERTO)
After=network.target

[Service]
Type=simple
ExecStart=$PYBIN $SERVER_PY --host 0.0.0.0 --port $PUERTO --backend-host 127.0.0.1 --backend-port $SSHPORT
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE" >/dev/null 2>&1
  systemctl restart "$SERVICE" >/dev/null 2>&1
  instalar_badvpn
  configurar_atajo_adm

  ok "¡Servidor BHTTP con HTTP Puro instalado y encendido en el puerto $PUERTO!"
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

menu_usuarios() {
  while true; do
    titulo
    seccion "GESTIÓN DE USUARIOS Y CREDENCIALES"
    echo -e "  ${NEON_GREEN}[1]${RESET} Crear usuario BHTTP"
    echo -e "  ${NEON_GREEN}[2]${RESET} Detalles de usuario existente (Panel)"
    echo -e "  ${NEON_GREEN}[3]${RESET} Eliminar usuario por numeración"
    echo -e "  ${NEON_GREEN}[4]${RESET} Editar Usuario (Añadir días / Cambiar contraseña)"
    echo -e "  ${NEON_GREEN}[5]${RESET} Ver usuarios en línea"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    read -r op
    case $op in
      1)
        echo -ne " Usuario: "; read -r nu
        echo -ne " Contraseña: "; read -r np
        echo -ne " Días vigencia: "; read -r nd
        if [ ${#np} -lt 4 ]; then fail "Mínimo 4 caracteres"; else
          crear_usuario "$nu" "$np" "$nd" && ok "¡Usuario creado!"
        fi
        pausa
        ;;
      2)
        titulo
        seccion "PANEL DE DETALLES DE USUARIOS EXISTENTES"
        if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
          local idx=1
          while IFS= read -r linea_usu; do
            local u_name u_pass u_dias
            u_name=$(echo "$linea_usu" | grep -oP 'User: \K[^|]+' | xargs)
            u_pass=$(echo "$linea_usu" | grep -oP 'Pass: \K[^|]+' | xargs)
            u_dias=$(echo "$linea_usu" | grep -oP 'Dias: \K.*' | xargs)
            echo -e "  ${NEON_ORANGE}[$idx]${RESET} Usuario : ${NEON_GREEN}$u_name${RESET} | Pass : ${WHITE}$u_pass${RESET} | Vigencia : ${CYAN}$u_dias${RESET}"
            idx=$((idx+1))
          done < "$USERS_FILE"
        else
          info "No hay usuarios registrados."
        fi
        pausa
        ;;
      3)
        titulo
        seccion "ELIMINAR USUARIO POR NUMERACIÓN"
        if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
          local idx=1
          declare -a arr_users
          while IFS= read -r linea_usu; do
            local u_name
            u_name=$(echo "$linea_usu" | grep -oP 'User: \K[^|]+' | xargs)
            arr_users[$idx]="$u_name"
            echo -e "  ${NEON_ORANGE}[$idx]${RESET} $u_name"
            idx=$((idx+1))
          done < "$USERS_FILE"
          echo
          echo -ne " ${NEON_ORANGE}◆${RESET} Número de usuario a eliminar (0 para cancelar): "
          read -r num_del
          if [[ "$num_del" =~ ^[0-9]+$ ]] && [ "$num_del" -gt 0 ] && [ -n "${arr_users[$num_del]:-}" ]; then
            local target_user="${arr_users[$num_del]}"
            userdel -r "$target_user" 2>/dev/null
            sed -i "/^User: $target_user /d" "$USERS_FILE" 2>/dev/null
            ok "¡Usuario $target_user eliminado con éxito!"
          else
            info "Operación cancelada."
          fi
        else
          info "No hay usuarios."
        fi
        pausa
        ;;
      4)
        titulo
        seccion "EDITAR USUARIO"
        if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
          local idx=1
          declare -a arr_users
          while IFS= read -r linea_usu; do
            local u_name
            u_name=$(echo "$linea_usu" | grep -oP 'User: \K[^|]+' | xargs)
            arr_users[$idx]="$u_name"
            echo -e "  ${NEON_ORANGE}[$idx]${RESET} $u_name"
            idx=$((idx+1))
          done < "$USERS_FILE"
          echo
          echo -ne " ${NEON_ORANGE}◆${RESET} Número de usuario a editar: "
          read -r num_edit
          if [[ "$num_edit" =~ ^[0-9]+$ ]] && [ "$num_edit" -gt 0 ] && [ -n "${arr_users[$num_edit]:-}" ]; then
            local target_user="${arr_users[$num_edit]}"
            echo -ne " Nueva contraseña (deja en blanco para mantener): "
            read -r n_pass
            local p_actual
            p_actual=$(grep "^User: $target_user " "$USERS_FILE" | grep -oP 'Pass: \K[^|]+' | xargs)
            [ -z "$n_pass" ] && n_pass="$p_actual"
            local pass_hash; pass_hash="$(openssl passwd -6 "$n_pass" 2>/dev/null)"
            usermod -p "$pass_hash" "$target_user" 2>/dev/null
            sed -i "/^User: $target_user /d" "$USERS_FILE" 2>/dev/null
            echo "User: $target_user | Pass: $n_pass | Dias: Actualizado" >> "$USERS_FILE"
            ok "¡Usuario actualizado!"
          else
            fail "Número inválido."
          fi
        else
          info "No hay usuarios."
        fi
        pausa
        ;;
      5)
        titulo
        seccion "USUARIOS CONECTADOS EN VIVO"
        if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
          while IFS= read -r linea_usu; do
            local u_name
            u_name=$(echo "$linea_usu" | grep -oP 'User: \K[^|]+' | xargs)
            if [ -n "$u_name" ]; then
              local conns=$(ps -u "$u_name" -o comm= 2>/dev/null | grep -E 'sshd|bash|sh' | wc -l)
              if [ "$conns" -gt 0 ]; then
                echo -e "  👤 Usuario: ${NEON_GREEN}$u_name${RESET} / ${NEON_ORANGE}$conns conexión(es) activa(s)${RESET}"
              else
                echo -e "  👤 Usuario: ${GRAY}$u_name${RESET} / ${RED}0 en línea${RESET}"
              fi
            fi
          done < "$USERS_FILE"
        else
          info "No hay usuarios."
        fi
        pausa
        ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# APERTURA DE PUERTOS
# ==============================================================================
menu_activar_puertos() {
  while true; do
    titulo
    seccion "APERTURA MANUAL DE PUERTOS"
    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el puerto a abrir (Ej. 443, 8080): "
    read -r p_ingresado
    if [[ "$p_ingresado" =~ ^[0-9]+$ ]] && [ "$p_ingresado5" -le 65535 2>/dev/null || [ "$p_ingresado" -le 65535 ] ]; then
      abrir_puerto_sistema "$p_ingresado"
      ok "¡Puerto $p_ingresado abierto!"
    else
      fail "Puerto inválido."
    fi
    echo -ne " ¿Abrir otro? (s/n): "
    read -r otro
    [[ "$otro" =~ ^[sS]$ ]] || break
  done
}

# ==============================================================================
# BADVPN GATEWAY
# ==============================================================================
menu_optimizar_vps() {
  while true; do
    titulo
    local bv_txt
    [ "$BADVPN_STATE" = "ON" ] && bv_txt="${NEON_GREEN}ACTIVO (ON)${RESET}" || bv_txt="${RED}INACTIVO (OFF)${RESET}"
    seccion "CONFIGURACIÓN BADVPN GATEWAY"
    echo -e "  Estado: [ $bv_txt ]"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar BadVPN Puerto 7300"
    echo -e "  ${NEON_GREEN}[2]${RESET} Activar BadVPN Puerto 7200"
    echo -e "  ${NEON_GREEN}[3]${RESET} Apagar BadVPN"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " Opción: "
    read -r opt_opt
    case $opt_opt in
      1) BADVPN_PORT=7300; instalar_badvpn; systemctl enable "$BADVPN_SERVICE"; systemctl restart "$BADVPN_SERVICE"; abrir_puerto_sistema "$BADVPN_PORT"; BADVPN_STATE="ON"; guardar_config; ok "¡BadVPN 7300 ON!"; pausa ;;
      2) BADVPN_PORT=7200; instalar_badvpn; systemctl enable "$BADVPN_SERVICE"; systemctl restart "$BADVPN_SERVICE"; abrir_puerto_sistema "$BADVPN_PORT"; BADVPN_STATE="ON"; guardar_config; ok "¡BadVPN 7200 ON!"; pausa ;;
      3) systemctl stop "$BADVPN_SERVICE"; BADVPN_STATE="OFF"; guardar_config; ok "¡BadVPN OFF!"; pausa ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# BHTTP BBR
# ==============================================================================
menu_bhttp_bbr() {
  while true; do
    titulo
    seccion "BHTTP BBR ACELERACIÓN"
    echo -e "  Estado BBR: [ ${NEON_ORANGE}${BBR_STATUS}${RESET} ]"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Fuerza Bruta BBR (Máximo)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Estabilidad + Velocidad"
    echo -e "  ${NEON_GREEN}[3]${RESET} Apagar BBR"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " Opción: "
    read -r bbr_op
    case $bbr_op in
      1)
        sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
        sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
        BBR_STATUS="FUERZA BRUTA (ON)"
        guardar_config; ok "¡BBR Fuerza Bruta Activado!"; pausa ;;
      2)
        sysctl -w net.core.default_qdisc=fq_codel >/dev/null 2>&1
        sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
        BBR_STATUS="ESTABILIDAD (ON)"
        guardar_config; ok "¡BBR Estabilidad Activado!"; pausa ;;
      3)
        sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
        BBR_STATUS="OFF"
        guardar_config; ok "¡BBR Apagado!"; pausa ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# AUTOSTART
# ==============================================================================
menu_autostart() {
  while true; do
    titulo
    seccion "AUTO INICIAR SCRIPT"
    echo -e "  Estado: [ ${NEON_ORANGE}$AUTOSTART_STATUS${RESET} ]"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Encender (ON)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Apagar (OFF)"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " Opción: "
    read -r as_op
    case $as_op in
      1) AUTOSTART_STATUS="ON"; guardar_config; ok "¡AutoStart ON!"; pausa ;;
      2) AUTOSTART_STATUS="OFF"; guardar_config; ok "¡AutoStart OFF!"; pausa ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# OPTIMIZACIÓN AUTOMÁTICA
# ==============================================================================
ejecutar_optimizacion_manual() {
  sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
}

menu_optimizacion_automatica() {
  while true; do
    titulo
    seccion "OPTIMIZACIÓN AUTOMÁTICA"
    echo -e "  Estado: [ ${NEON_ORANGE}$CRON_STATUS${RESET} ]"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar cada 6 horas (ON)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Desactivar (OFF)"
    echo -e "  ${NEON_GREEN}[3]${RESET} Optimizar RAM Ahora"
    echo -e "  ${RED}[0]${RESET} Regresar"
    linea
    echo -ne " Opción: "
    read -r cron_op
    case $cron_op in
      1) CRON_STATUS="ON"; guardar_config; ok "¡Optimización 6h ON!"; pausa ;;
      2) CRON_STATUS="OFF"; guardar_config; ok "¡Optimización OFF!"; pausa ;;
      3) ejecutar_optimizacion_manual; ok "¡RAM Liberada!"; pausa ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# HERRAMIENTAS SUPER AVANZADAS - OPCIÓN [12] (CON BOLITA VERDE 🟢)
# ==============================================================================
menu_herramientas_avanzadas() {
  while true; do
    titulo
    seccion "HERRAMIENTAS SUPER AVANZADAS"
    
    # Validadores de estado para las bolitas verdes
    local s1="${RED}🔴 (OFF)${RESET}"; [ "$KEEPALIVE_STATUS" = "ON" ] && s1="${NEON_GREEN}🟢 (ON)${RESET}"
    local s2="${RED}🔴 (OFF)${RESET}"; [ "$PROTECT_BHTTP_STATUS" = "ON" ] && s2="${NEON_GREEN}🟢 (ON)${RESET}"
    local s3="${RED}🔴 (OFF)${RESET}"; [ "$FAST_CONN_STATUS" = "ON" ] && s3="${NEON_GREEN}🟢 (ON)${RESET}"
    local s4="${GRAY}⚪ (ESPERA)${RESET}"

    echo -e "  ${NEON_GREEN}[1]${RESET} Activar Keep Alive        : $s1"
    echo -e "  ${NEON_GREEN}[2]${RESET} Proteger BHTTP (HTTP Puro): $s2"
    echo -e "  ${NEON_GREEN}[3]${RESET} Conexión Rápida BHTTP     : $s3"
    echo -e "  ${NEON_GREEN}[4]${RESET} Herramientas en espera    : $s4"
    echo -e "  ${RED}[0]${RESET} Regresar al Menú Principal"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Selecciona una opción para encender/apagar: "
    read -r adv_op
    case $adv_op in
      1)
        if [ "$KEEPALIVE_STATUS" = "ON" ]; then
          KEEPALIVE_STATUS="OFF"
          info "Keep Alive desactivado."
        else
          sysctl -w net.ipv4.tcp_keepalive_time=30 >/dev/null 2>&1
          sysctl -w net.ipv4.tcp_keepalive_intvl=10 >/dev/null 2>&1
          sysctl -w net.ipv4.tcp_keepalive_probes=3 >/dev/null 2>&1
          KEEPALIVE_STATUS="ON"
          ok "¡Keep Alive activado! Bolita verde encendida."
        fi
        guardar_config
        pausa
        ;;
      2)
        if [ "$PROTECT_BHTTP_STATUS" = "ON" ]; then
          PROTECT_BHTTP_STATUS="OFF"
          info "Protección BHTTP (HTTP Puro) desactivada."
        else
          # Reforzando reglas de sockets y enmascaramiento HTTP Puro
          sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
          sysctl -w net.ipv4.tcp_window_scaling=1 >/dev/null 2>&1
          PROTECT_BHTTP_STATUS="ON"
          ok "¡Protección BHTTP (HTTP Puro) activada! Tráfico camuflado e indetectable. Bolita verde encendida."
        fi
        guardar_config
        pausa
        ;;
      3)
        if [ "$FAST_CONN_STATUS" = "ON" ]; then
          FAST_CONN_STATUS="OFF"
          info "Conexión Rápida desactivada."
        else
          if [ -f /etc/ssh/sshd_config ]; then
            sed -i 's/^#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config 2>/dev/null
            sed -i 's/^UseDNS yes/UseDNS no/' /etc/ssh/sshd_config 2>/dev/null
            systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
          fi
          sysctl -w net.ipv4.tcp_fin_timeout=10 >/dev/null 2>&1
          sysctl -w net.ipv4.tcp_tw_reuse=1 >/dev/null 2>&1
          FAST_CONN_STATUS="ON"
          ok "¡Conexión Rápida aplicada y puerto SSH/22 acelerado! Bolita verde encendida."
        fi
        guardar_config
        pausa
        ;;
      4)
        titulo
        seccion "HERRAMIENTAS EN ESPERA"
        info "Módulo reservado y vacío."
        pausa
        ;;
      0) return ;;
    esac
  done
}

# ==============================================================================
# ACTUALIZADOR
# ==============================================================================
actualizar_script() {
    titulo
    seccion "ACTUALIZAR SCRIPT"
    local URL_GITHUB="https://raw.githubusercontent.com/21062022/intalar.sh/main/intalar.sh"
    local TEMP_SCRIPT="/tmp/intalar_update.sh"
    if curl -fsSL "$URL_GITHUB" -o "$TEMP_SCRIPT"; then
        cp "$TEMP_SCRIPT" "$SCRIPT_PATH" 2>/dev/null
        chmod +x "$SCRIPT_PATH"
        ok "¡Actualizado con éxito!"
        exec sudo bash "$SCRIPT_PATH"
    else
        fail "Error al conectar con GitHub."
    fi
    pausa
}

# ==============================================================================
# DESTRUCCIÓN TOTAL
# ==============================================================================
destruir_script_total() {
    titulo
    echo -ne " ¿Deseas desinstalar todo por completo? (s/n): "
    read -r confirmacion
    if [[ "$confirmacion" =~ ^[sS]$ ]]; then
        systemctl stop "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null || true
        rm -f "$UNIT" "$BADVPN_UNIT" 2>/dev/null
        rm -rf "$DESTDIR" "$CONFIG_DIR" "$ADM_BIN" "$ADMIN_BIN" "$SCRIPT_PATH" 2>/dev/null
        ok "¡Desinstalación completa!"
        exit 0
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
    echo -e "  ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar puerto BHTTP (HTTP Puro)"
    echo -e "  ${NEON_GREEN}[2]${RESET} Gestionar Usuarios (Crear, Editar, En línea)"
    echo -e "  ${NEON_GREEN}[3]${RESET} Encender / Apagar BHTTP Server"
    echo -e "  ${NEON_GREEN}[4]${RESET} Abrir Puertos Manuales (Firewall)"
    echo -e "  ${NEON_GREEN}[5]${RESET} BadVPN Gateway (Puertos 7200 o 7300 / UDP Juegos)"
    echo -e "  ${NEON_GREEN}[6]${RESET} Actualizar Script desde GitHub"
    echo -e "  ${NEON_GREEN}[7]${RESET} (Extra) Liberar Memoria RAM Manual"
    echo -e "  ${NEON_GREEN}[8]${RESET} Auto Iniciar Script al Abrir Terminal"
    echo -e "  ${NEON_GREEN}[9]${RESET} Optimización Automática Cada 6 Horas (RAM y CPU)"
    echo -e "  ${NEON_GREEN}[10]${RESET} BHTTP BBR (Aceleración de Velocidad TCP Extrema)"
    echo -e "  ${NEON_GREEN}[12]${RESET} Herramientas Super Avanzadas"
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
          ok "¡Servidor BHTTP detenido (OFF)!"
        else
          systemctl enable "$SERVICE" 2>/dev/null
          systemctl start "$SERVICE" 2>/dev/null
          ok "¡Servidor BHTTP encendido (ON)!"
        fi
        pausa
        ;;
      4) menu_activar_puertos ;;
      5) menu_optimizar_vps ;;
      6) actualizar_script ;;
      7) ejecutar_optimizacion_manual; ok "¡RAM liberada!"; pausa ;;
      8) menu_autostart ;;
      9) menu_optimizacion_automatica ;;
      10) menu_bhttp_bbr ;;
      12) menu_herramientas_avanzadas ;;
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
