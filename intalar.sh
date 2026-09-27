#!/usr/bin/env bash
# =========================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER
#        BHTTP V.1 & BADVPN PROTOCOL (TIGO Y CLARO NICARAGUA FULL)
#        PREMIUM SERVER EDITION v4.0
# =========================================================

set -o pipefail

# =========================================================
# COLORES
# =========================================================
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

PINK="\e[38;5;213m"
PURPLE="\e[38;5;141m"
VIOLET="\e[38;5;177m"
SKY="\e[38;5;117m"
LIME="\e[38;5;154m"
GOLD="\e[38;5;220m"
ORANGE="\e[38;5;214m"
AQUA="\e[38;5;159m"

# =========================================================
# RUTAS Y VARIABLES
# =========================================================
DESTDIR="/usr/local/lib/bhttp"
SERVER_PY="$DESTDIR/bhttp-server.py"
UNIT="/etc/systemd/system/bhttp.service"
BADVPN_UNIT="/etc/systemd/system/badvpn.service"
SERVICE="bhttp"
BADVPN_SERVICE="badvpn"
CONFIG="/etc/bhttp/nullcore.conf"
CANDIDATOS=(8080 80 8443 443 2082 2095 8880 2052 3128)

PUERTO=""
SSHPORT=22
BADVPN_PORT=7300
VERSION="4.0"

# =========================================================
# FUNCIONES VISUALES
# =========================================================
clear_screen() {
    clear 2>/dev/null || true
}

linea() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

linea_color() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

titulo() {
    clear_screen
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${PINK}${BOLD}                 HAZAEL MORENO MULTI SCRIPT${RESET}            ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} ${PURPLE}${BOLD}         BHTTP V.1 & BADVPN PROTOCOL v4.0${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${SKY}        🚀  TIGO Y CLARO NICARAGUA FULL EDITION  🚀${RESET}"
    echo
}

seccion() {
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD} $1${RESET}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

ok() {
    echo -e " ${GREEN}✔${RESET} ${WHITE}$1${RESET}"
}

info() {
    echo -e " ${CYAN}◆${RESET} ${WHITE}$1${RESET}"
}

warn() {
    echo -e " ${YELLOW}⚠${RESET} ${WHITE}$1${RESET}"
}

fail() {
    echo -e " ${RED}✖${RESET} ${WHITE}$1${RESET}"
}

pausa() {
    echo
    read -r -p " Presiona Enter para continuar..."
}

# =========================================================
# VERIFICAR ROOT
# =========================================================
check_root() {
  if [ "$(id -u 2>/dev/null || echo 0)" != 0 ]; then
    fail "Ejecuta como root: sudo bash $0"
    exit 2
  fi
}

# =========================================================
# CARGAR / GUARDAR CONFIGURACIÓN
# =========================================================
cargar_config() {
  mkdir -p /etc/bhttp
  if [ -f "$CONFIG" ]; then
    source "$CONFIG"
  fi
  [ -z "${PUERTO:-}" ] && PUERTO=""
  [ -z "${SSHPORT:-}" ] && SSHPORT=22
  [ -z "${BADVPN_PORT:-}" ] && BADVPN_PORT=7300
}

guardar_config() {
  mkdir -p /etc/bhttp
  cat > "$CONFIG" <<EOF
PUERTO=${PUERTO}
SSHPORT=${SSHPORT}
BADVPN_PORT=${BADVPN_PORT}
EOF
}

# =========================================================
# INSTALAR BADVPN (PORT 7300)
# =========================================================
instalar_badvpn() {
    seccion "INSTALACIÓN DE BADVPN (PORT $BADVPN_PORT)"
    info "Configurando BadVPN Udpgw..."
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y cmake g++ make wget curl badvpn 2>/dev/null || true

    cat > "$BADVPN_UNIT" <<EOF
[Unit]
Description=BadVPN UDP Gateway for Gaming/VOIP
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 500 --max-connections 1000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$BADVPN_SERVICE" >/dev/null 2>&1
    systemctl restart "$BADVPN_SERVICE"
    
    if systemctl is-active --quiet "$BADVPN_SERVICE"; then
        ok "BadVPN Udpgw corriendo correctamente en el puerto 127.0.0.1:$BADVPN_PORT"
    else
        warn "BadVPN configurado (verificar paquete en el sistema)."
    fi
}

# =========================================================
# CREAR USUARIO (CONTRASEÑA MANUAL 4+ CARACTERES SIN ERRORES)
# =========================================================
crear_usuario() {
  local u="$1" p="$2" dias="$3"
  
  if [ -z "$u" ] || [ -z "$p" ]; then
    fail "El usuario y la contraseña no pueden estar vacíos."
    return 1
  fi

  if id "$u" >/dev/null 2>&1; then
    info "El usuario '$u' ya existe. Actualizando credenciales..."
  else
    useradd -M -s /bin/bash "$u" || { fail "No se pudo crear el usuario '$u'"; return 1; }
  fi

  local pass_hash
  pass_hash="$(openssl passwd -6 "$p" 2>/dev/null)"
  usermod -p "$pass_hash" "$u" || { fail "Error al establecer la contraseña"; return 1; }
  
  if [[ "$dias" =~ ^[0-9]+$ ]] && [ "$dias" -gt 0 ]; then
    chage -E "$(date -d "+${dias} days" +%Y-%m-%d 2>/dev/null || date -v +${dias}d +%Y-%m-%d 2>/dev/null)" "$u" 2>/dev/null
  else
    chage -E -1 "$u" 2>/dev/null
  fi

  USER_FINAL="$u"
  PASS_FINAL="$p"
  DIAS_FINAL="${dias:-Ilimitado}"
  return 0
}

# =========================================================
# PUERTOS LIBRES
# =========================================================
ocupados() {
  if command -v ss >/dev/null 2>&1; then
    ss -tln 2>/dev/null | tail -n +2 | awk '{print $4}' | sed 's/.*://'
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln 2>/dev/null | awk '/^tcp/ {print $4}' | sed 's/.*://'
  fi | grep -E '^[0-9]+$' | sort -u
}
libre() { ! ocupados | grep -qx "$1"; }

# =========================================================
# INSTALAR SERVIDOR BHTTP
# =========================================================
instalar_servidor() {
  titulo
  seccion "INSTALACIÓN DE PROTOCOLO BHTTP"
  
  command -v python3 >/dev/null 2>&1 || { fail "Falta python3. Instálalo: apt install -y python3"; pausa; return 1; }
  
  local primer_libre=""
  for p in "${CANDIDATOS[@]}"; do libre "$p" && { primer_libre="$p"; break; }; done
  if [ -z "$PUERTO" ]; then
    echo -ne " ${CYAN}◆${RESET} Puerto BHTTP [${primer_libre:-8080}]: "
    read -r PUERTO
    [ -z "$PUERTO" ] && PUERTO="${primer_libre:-8080}"
  fi

  if ! [[ "$PUERTO" =~ ^[0-9]+$ ]] || [ "$PUERTO" -lt 1 ] || [ "$PUERTO" -gt 65535 ]; then
    fail "Puerto inválido: $PUERTO"; pausa; return 1
  fi
  if ! libre "$PUERTO"; then
    fail "El puerto $PUERTO ya se encuentra ocupado."; pausa; return 1
  fi

  mkdir -p "$DESTDIR"
  cat > "$SERVER_PY" << 'PYEOF'
#!/usr/bin/env python3
import argparse, asyncio, hashlib, struct, sys
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
    for i in range(10, n):
        out.append((i * 31) & 255)
    return bytes(out)
class Session:
    def __init__(self, sess, backend):
        self.sess = sess
        self.backend = backend
        self.cond = asyncio.Condition()
        self.up_next = 0
        self.up_pending = {}
        self.down_raw = bytearray()
        self.down_chunks = {}
        self.down_assign = 0
        self.eof = False
        self.closed = False
        self.br = None
        self.bw = None
    async def connect(self):
        host, port = self.backend
        self.br, self.bw = await asyncio.open_connection(host, port)
        asyncio.create_task(self._reader())
    async def _reader(self):
        try:
            while True:
                data = await self.br.read(65536)
                if not data: break
                async with self.cond:
                    self.down_raw += data
                    self.cond.notify_all()
        except Exception:
            pass
        finally:
            async with self.cond:
                self.eof = True
                self.cond.notify_all()
    async def upload(self, seq, data):
        async with self.cond:
            if data:
                self.up_pending[seq] = data
            while self.up_next in self.up_pending:
                chunk = self.up_pending.pop(self.up_next)
                try:
                    self.bw.write(chunk)
                    await self.bw.drain()
                except Exception:
                    self.closed = True
                self.up_next += 1
    async def download(self, seq, maxlen, deadline):
        if maxlen <= 0: maxlen = 1399
        loop = asyncio.get_running_loop()
        async with self.cond:
            while True:
                if seq < self.down_assign:
                    return self.down_chunks.get(seq, b"")
                if seq == self.down_assign:
                    if self.down_raw:
                        take = bytes(self.down_raw[:maxlen]); del self.down_raw[:maxlen]
                        self.down_chunks[self.down_assign] = take
                        self.down_assign += 1
                        self.cond.notify_all()
                        return take
                    if self.eof:
                        self.down_assign += 1
                        self.cond.notify_all()
                        return b""
                if not self.eof and loop.time() < deadline:
                    try:
                        await asyncio.wait_for(self.cond.wait(), timeout=max(0.01, deadline - loop.time()))
                    except asyncio.TimeoutError:
                        pass
                    continue
                while self.down_assign <= seq:
                    self.down_assign += 1
                self.cond.notify_all()
                return b""
    async def ack(self, seq):
        async with self.cond:
            for k in [k for k in self.down_chunks if k <= seq]:
                del self.down_chunks[k]
    async def close(self):
        async with self.cond:
            self.closed = True
            self.cond.notify_all()
        try: self.bw.close()
        except Exception: pass
class Server:
    def __init__(self, host, port, backend):
        self.host, self.port, self.backend = host, port, backend
        self.sessions = {}
        self.slock = asyncio.Lock()
    async def get_session(self, sess):
        async with self.slock:
            s = self.sessions.get(sess)
            if s is None or s.closed:
                for old_sid, old in list(self.sessions.items()):
                    if old_sid != sess:
                        await old.close()
                        del self.sessions[old_sid]
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
                    await s.upload(seq, payload)
                    writer.write(bytes([0]) + (0).to_bytes(4, "big"))
                    await writer.drain()
                elif mode == 2:
                    chunk = await s.download(seq, ln if ln > 0 else 1399, asyncio.get_running_loop().time() + LONGPOLL)
                    self._send_data(writer, sess, mode, seq, chunk)
                    await writer.drain()
                elif mode == 3:
                    chunk_size = 1399; count = 1
                    if len(payload) >= 6:
                        chunk_size = int.from_bytes(payload[0:4], "big")
                        count = payload[5]
                    deadline = asyncio.get_running_loop().time() + LONGPOLL
                    for i in range(count):
                        chunk = await s.download(seq + i, chunk_size, deadline)
                        self._send_data(writer, sess, mode, seq + i, chunk)
                    await writer.drain()
                elif mode == 4:
                    await s.ack(seq)
                    writer.write(bytes([0]) + (0).to_bytes(4, "big"))
                    await writer.drain()
                else:
                    return
        except Exception:
            pass
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

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE" >/dev/null 2>&1
  systemctl restart "$SERVICE"
  
  instalar_badvpn

  if systemctl is-active --quiet "$SERVICE"; then
    ok "Servicio BHTTP activo en el puerto $PUERTO"
    guardar_config
  else
    fail "El servicio BHTTP no arrancó correctamente."
  fi
  pausa
}

# =========================================================
# GESTIÓN DE USUARIOS
# =========================================================
menu_usuarios() {
  while true; do
    titulo
    seccion "GESTIÓN DE USUARIOS"
    echo -e "  ${GREEN}[1]${RESET}  Crear usuario para túnel (Manual / 4+ Caracteres)"
    echo -e "  ${GREEN}[2]${RESET}  Listar usuarios del sistema"
    echo -e "  ${GREEN}[3]${RESET}  Cambiar contraseña de usuario"
    echo -e "  ${GREEN}[4]${RESET}  Eliminar usuario"
    echo -e "  ${RED}[0]${RESET}  Volver al menú principal"
    linea
    echo -ne " ${CYAN}◆${RESET} Selecciona una opción: "
    read -r op
    case $op in
      1)
        echo
        echo -ne " ${CYAN}◆${RESET} Nombre de usuario: "
        read -r nu
        echo -ne " ${CYAN}◆${RESET} Contraseña (mínimo 4 caracteres): "
        read -r np
        echo -ne " ${CYAN}◆${RESET} Días de duración activa (ej. 30): "
        read -r nd
        
        if [ ${#np} -lt 4 ]; then
          fail "Error: La contraseña debe tener al menos 4 caracteres."
        else
          if crear_usuario "$nu" "$np" "$nd"; then
            echo
            ok "USUARIO CREADO OK"
            echo -e "    Usuario  : ${WHITE}${USER_FINAL}${RESET}"
            echo -e "    Clave    : ${WHITE}${PASS_FINAL}${RESET}"
            echo -e "    Vigencia : ${WHITE}${DIAS_FINAL}${RESET}"
            echo -e "    BadVPN   : ${WHITE}Port $BADVPN_PORT${RESET}"
          fi
        fi
        pausa
        ;;
      2)
        echo
        echo -e "${WHITE}  Usuarios del sistema (UID >= 1000):${RESET}"
        linea
        awk -F: '$3 >= 1000 && $1 != "nobody" {print "  → " $1}' /etc/passwd
        pausa
        ;;
      3)
        echo
        echo -ne " ${CYAN}◆${RESET} Usuario: "
        read -r nu
        echo -ne " ${CYAN}◆${RESET} Nueva contraseña (mínimo 4 caracteres): "
        read -r np
        if [ ${#np} -lt 4 ]; then
          fail "Error: La contraseña debe tener al menos 4 caracteres."
        elif id "$nu" >/dev/null 2>&1; then
          local pass_hash
          pass_hash="$(openssl passwd -6 "$np" 2>/dev/null)"
          usermod -p "$pass_hash" "$nu" && ok "Contraseña actualizada correctamente." || fail "Error al actualizar."
        else
          fail "El usuario no existe."
        fi
        pausa
        ;;
      4)
        echo
        echo -ne " ${CYAN}◆${RESET} Usuario a eliminar: "
        read -r nu
        if id "$nu" >/dev/null 2>&1; then
          userdel -r "$nu" 2>/dev/null && ok "Usuario eliminado correctamente." || fail "Error al eliminar."
        else
          fail "El usuario no existe."
        fi
        pausa
        ;;
      0) return ;;
      *) fail "Opción inválida"; pausa ;;
    esac
  done
}

# =========================================================
# MENÚ PRINCIPAL
# =========================================================
menu_principal() {
  while true; do
    titulo
    local estado
    estado=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "no instalado")
    echo -e "  ${WHITE}Estado BHTTP:${RESET} ${GREEN}${estado}${RESET} | ${WHITE}Puerto:${RESET} ${GREEN}${PUERTO:-—}${RESET} | ${WHITE}BadVPN:${RESET} ${GREEN}${BADVPN_PORT}${RESET}"
    linea
    echo -e "  ${GREEN}[1]${RESET}  Instalar / Reinstalar BHTTP & BadVPN"
    echo -e "  ${GREEN}[2]${RESET}  Gestión de Usuarios"
    echo -e "  ${GREEN}[3]${RESET}  Control del Servicio"
    echo -e "  ${GREEN}[4]${RESET}  Información del Sistema"
    echo -e "  ${GREEN}[5]${RESET}  Cambiar puerto SSH backend"
    echo -e "  ${RED}[6]${RESET}  Desinstalar"
    echo -e "  ${RED}[0]${RESET}  Salir"
    linea
    echo -ne " ${CYAN}◆${RESET} Selecciona una opción: "
    read -r opcion
    case $opcion in
      1) instalar_servidor ;;
      2) menu_usuarios ;;
      3) 
        seccion "CONTROL DEL SERVICIO"
        echo -e "  [1] Iniciar  |  [2] Detener  |  [3] Reiniciar  |  [4] Estado"
        read -r st
        case $st in
          1) systemctl start "$SERVICE" "$BADVPN_SERVICE"; ok "Iniciados"; pausa ;;
          2) systemctl stop "$SERVICE" "$BADVPN_SERVICE"; ok "Detenidos"; pausa ;;
          3) systemctl restart "$SERVICE" "$BADVPN_SERVICE"; ok "Reiniciados"; pausa ;;
          4) systemctl status "$SERVICE" --no-pager; pausa ;;
        esac
        ;;
      4) 
        titulo
        seccion "DIAGNÓSTICO"
        echo -e "  IP Pública   : $(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
        echo -e "  BHTTP Puerto : ${PUERTO:-No instalado}"
        echo -e "  BadVPN Puerto: $BADVPN_PORT"
        pausa
        ;;
      5)
        echo -ne " ${CYAN}◆${RESET} Nuevo puerto SSH backend [${SSHPORT}]: "
        read -r nuevo
        [ -n "$nuevo" ] && SSHPORT="$nuevo" && guardar_config && ok "Actualizado"
        pausa
        ;;
      6) 
        systemctl stop "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null
        rm -f "$UNIT" "$BADVPN_UNIT" "$SERVER_PY"
        systemctl daemon-reload
        ok "Desinstalado"
        pausa
        ;;
      0) echo -e "\n  Saliendo...\n"; exit 0 ;;
      *) fail "Opción no válida"; pausa ;;
    esac
  done
}

check_root
cargar_config
menu_principal
