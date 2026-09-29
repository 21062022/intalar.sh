#!/usr/bin/env bash
# ==============================================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER - ULTRA CYBER EDITION
#        BHTTP V.1 & BADVPN PROTOCOL (TIGO Y CLARO NICARAGUA FULL)
#        PREMIUM SERVER EDITION v8.0 (FIX SYNTAX & EOF)
# ==============================================================================

set -o pipefail

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
Description=BadVPN UDP Gateway
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

  ok "¡Servidor BHTTP instalado y encendido en el puerto $PUERTO!"
  guardar_config
  pausa
}

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
            
            local exp_date dias_restantes="N/A"
            exp_date=$(chage -l "$u_name" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
            if [ "$exp_date" != "never" ] && [ -n "$exp_date" ]; then
              local t_exp t_hoy
              t_exp=$(date -d "$exp_date" +%s 2>/dev/null || echo 0)
              t_hoy=$(date +%s)
              if [ "$t_exp" -gt "$t_hoy" ]; then
                dias_restantes=$(( (t_exp - t_hoy) / 86400 ))" días"
              else
                dias_restantes="Expirado"
              fi
            else
            dias_restantes="Ilimitado"
fi
echo -e "  {NEON_ORANGE}[$idx]${RESET} Usuario :{NEON_GREEN}u_name{RESET}"
echo -e "      Contraseña : ${WHITE}u_pass{RESET}"
echo -e "      Vigencia   : ${CYAN}u_dias{RESET}"
echo -e "      Restantes  : {YELLOW}$dias_restantes${RESET}"
echo -e "  ----------------------------------------------------------"
idx=((idx+1))
done < "$USERS_FILE"
else
info "No hay usuarios registrados."
fi
pausa
;;
3) eliminar_usuario_num ;;
4) editar_usuario ;;
5) ver_usuarios_en_linea ;;
0) break ;;
*) fail "Opción inválida."; sleep 1 ;;
esac
done
}
menu_abrir_puertos() {
titulo
seccion "ACTIVAR O ABRIR PUERTO PERSONALIZADO EN FIREWALL"
echo -ne " {NEON_ORANGE}◆{RESET} Ingresa el número de puerto TCP/UDP que deseas abrir (Ej. 8080): "
read -r p_manual
if [[ "p_manual" =~ ^[0-9]+ ]] && [ "$p_manual" -gt 0 ] && [ "$p_manual" -le 65535 ]; then
abrir_puerto_sistema "$p_manual"
else
fail "Número de puerto inválido."
fi
pausa
}
panel_servicios() {
titulo
seccion "PANEL DE CONTROL DE SERVICIOS (BHTTP & BADVPN)"
echo -e "  {NEON_GREEN}[1]{RESET} Reiniciar BHTTP y BadVPN"
echo -e "  {NEON_GREEN}[2]{RESET} Detener Servicios"
echo -e "  {NEON_GREEN}[3]{RESET} Iniciar Servicios"
echo -e "  {RED}[0]{RESET} Regresar"
linea
echo -ne " {NEON_ORANGE}◆{RESET} Opción: "
read -r op_s
case $op_s in
1) systemctl restart bhttp badvpn 2>/dev/null; ok "Servicios reiniciados correctamente." ;;
2) systemctl stop bhttp badvpn 2>/dev/null; ok "Servicios detenidos." ;;
3) systemctl start bhttp badvpn 2>/dev/null; ok "Servicios iniciados." ;;
esac
pausa
}
detalles_vps() {
titulo
seccion "DETALLES DEL SERVIDOR VPS"
echo -e "  {WHITE}IP Pública:{RESET}{NEON_GREEN}(obtener_ip_publica){RESET}"
echo -e "  ${WHITE}Puerto BHTTP:${RESET}{YELLOW}PUERTO{RESET}"
echo -e "  {WHITE}Puerto BadVPN:{RESET}{YELLOW}$BADVPN_PORT${RESET}"
echo -e "  ${WHITE}RAM en Uso:${RESET}{CYAN}(free -h \vert{} awk '/Mem:/ {print $3 "/" $2}')${RESET}"
echo -e "  ${WHITE}Kernel / S.O:${RESET}${MAGENTA}(uname -r)${RESET}"
pausa
}
optimizar_vps() {
titulo
seccion "OPTIMIZACIÓN AUTOMÁTICA DE CPU Y MEMORIA RAM"
sync; echo 3 > /proc/sys/vm/drop_caches
systemctl restart bhttp badvpn 2>/dev/null
ok "Caché de memoria liberada y procesos reiniciados con éxito."
pausa
}
actualizar_script() {
titulo
seccion "ACTUALIZAR SCRIPT DESDE REPOSITORIO"
info "Sincronizando la última versión de la instalación..."
configurar_atajo_adm
ok "Panel y componentes actualizados a la versión v8.0."
pausa
}
destruccion_total() {
titulo
seccion "DESTRUCCIÓN TOTAL / DESINSTALAR SCRIPT COMPLETO"
echo -e "{RED}{BOLD}⚠️ ATENCIÓN: Se eliminará BHTTP, BadVPN, configuraciones y accesos creados.${RESET}"
echo -ne " ¿Estás seguro de desinstalar todo el sistema? (s/n): "
read -r confirm
if [[ "confirm" =~ ^[sS] ]]; then
systemctl stop bhttp badvpn 2>/dev/null || true
systemctl disable bhttp badvpn 2>/dev/null || true
rm -f "$UNIT" "$BADVPN_UNIT" "$ADM_BIN" "$ADMIN_BIN" "$SCRIPT_PATH" 2>/dev/null || true
rm -rf "$DESTDIR" "$CONFIG_DIR" 2>/dev/null || true
systemctl daemon-reload
ok "El script y todos sus componentes han sido eliminados del servidor."
exit 0
else
info "Operación cancelada."
pausa
fi
}
menu_principal() {
check_root
cargar_config
configurar_atajo_adm
while true; do
titulo
seccion "PANEL DE CONTROL PRINCIPAL"
echo -e "  {NEON_GREEN}[1]{RESET}  Instalar / Reinstalar o Cambiar Puerto BHTTP"
echo -e "  {NEON_GREEN}[2]{RESET}  Gestión de Usuarios y Credenciales"
echo -e "  {NEON_GREEN}[3]{RESET}  Activar / Abrir Puerto Personalizado en Firewall"
echo -e "  {NEON_GREEN}[4]{RESET}  Panel de Control de Servicios (Iniciar / Parar / Reiniciar)"
echo -e "  {NEON_GREEN}[5]{RESET}  Detalles de mi servidor VPS"
echo -e "  {NEON_GREEN}[6]{RESET}  Actualizar Script desde GitHub"
echo -e "  {NEON_GREEN}[7]{RESET}  Optimizar Servidor (CPU / Memoria RAM)"
echo -e "  {NEON_GREEN}[8]{RESET}  Configurar BadVPN UDPGW (Puerto:$BADVPN_PORT)"
echo -e "  {NEON_GREEN}[9]{RESET}  Ver Usuarios Conectados en Tiempo Real"
echo -e "  {NEON_GREEN}[10]{RESET} Configurar Atajos Rápidos ('adm' / 'admin')"
echo -e "  {RED}[11] DESTRUCCIÓN TOTAL / DESINSTALAR SCRIPT COMPLETO{RESET}"
echo -e "  {RED}[0]  Salir del Panel{RESET}"
linea
echo -ne " {NEON_ORANGE}◆{RESET} Selecciona una opción [1-11, 0]: "
read -r opcion
case $opcion in
1) instalar_servidor ;;
2) menu_usuarios ;;
3) menu_abrir_puertos ;;
4) panel_servicios ;;
5) detalles_vps ;;
6) actualizar_script ;;
7) optimizar_vps ;;
8) instalar_badvpn; ok "BadVPN reconfigurado."; pausa ;;
9) ver_usuarios_en_linea ;;
10) configurar_atajo_adm; ok "Atajos reconfigurados."; pausa ;;
11) destruccion_total ;;
0) clear_screen; ok "Saliendo del panel..."; exit 0 ;;
*) fail "Opción no válida."; sleep 1 ;;
esac
done
}
menu_principal
