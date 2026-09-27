#!/usr/bin/env bash
# ==============================================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER - ULTRA CYBER EDITION
#        BHTTP V.1 & BADVPN PROTOCOL (TIGO Y CLARO NICARAGUA FULL)
#        PREMIUM SERVER EDITION v5.0
# ==============================================================================

set -o pipefail

# ==============================================================================
# PALETA DE COLORES VIBRANTES Y NEÓN
# ==============================================================================
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

# Básicos brillantes
RED="\e[1;91m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

# Neones personalizados de alta fidelidad
PINK="\e[38;5;213m"
PURPLE="\e[38;5;141m"
VIOLET="\e[38;5;177m"
SKY="\e[38;5;117m"
LIME="\e[38;5;154m"
GOLD="\e[38;5;220m"
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
CANDIDATOS=(8080 80 8443 443 2082 2095 8880 2052 3128)

PUERTO=""
SSHPORT=22
BADVPN_PORT=7300

# ==============================================================================
# CONFIGURACIÓN DEL COMANDO RÁPIDO "adm" Y AUTO-EJECUTABLE
# ==============================================================================
configurar_atajo_adm() {
  # Copiar script principal a la ruta del sistema
  if [ "$0" != "$SCRIPT_PATH" ]; then
    cp "$0" "$SCRIPT_PATH" 2>/dev/null || true
    chmod +x "$SCRIPT_PATH"
  fi

  # Crear comando directo ejecutable en /usr/local/bin/adm
  cat > "$ADM_BIN" << 'EOF'
#!/usr/bin/env bash
sudo bash /usr/local/bin/intalar.sh
EOF
  chmod +x "$ADM_BIN"

  # Asegurar alias en perfiles de shell comunes
  for rc in /root/.bashrc /home/*/.bashrc /root/.zshrc; do
    if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
      touch "$rc" 2>/dev/null
      sed -i '/alias adm=/d' "$rc" 2>/dev/null
      echo "alias adm='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
    fi
  done
}

# ==============================================================================
# INTERFAZ VISUAL CYBERPUNK
# ==============================================================================
clear_screen() {
    clear 2>/dev/null || true
}

linea() {
    echo -e "${NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

titulo() {
    clear_screen
    echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_GREEN}${BOLD}                   HAZAEL MORENO MULTI SCRIPT${RESET}              ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_BLUE}${BOLD}            BHTTP V.1 & BADVPN PROTOCOL v5.0${RESET}             ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${SKY}     🚀 ${NEON_ORANGE}TIGO Y CLARO NICARAGUA${RESET} ${SKY}• TUNELIZACIÓN MÁXIMA PRO 🚀${RESET}"
    echo
}

seccion() {
    echo
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${PURPLE}│${RESET} ${WHITE}${BOLD} $1${RESET}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────────────┘${RESET}"
    echo
}

ok() { echo -e " ${NEON_GREEN}✔ [ÉXITO]${RESET} ${WHITE}$1${RESET}"; }
info() { echo -e " ${SKY}◆ [INFO]${RESET} ${WHITE}$1${RESET}"; }
fail() { echo -e " ${RED}✖ [ERROR]${RESET} ${WHITE}$1${RESET}"; }

pausa() {
    echo
    echo -e "${GRAY} Presiona ${NEON_GREEN}[Enter]${GRAY} para regresar al panel principal...${RESET}"
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
  [ -z "${PUERTO:-}" ] && PUERTO=""
  [ -z "${SSHPORT:-}" ] && SSHPORT=22
  [ -z "${BADVPN_PORT:-}" ] && BADVPN_PORT=7300
}

guardar_config() {
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG" <<EOF
PUERTO=${PUERTO}
SSHPORT=${SSHPORT}
BADVPN_PORT=${BADVPN_PORT}
EOF
}

# ==============================================================================
# INSTALACIÓN DE BADVPN (PUERTO 7300)
# ==============================================================================
instalar_badvpn() {
    seccion "CONFIGURANDO PROTOCOLO BADVPN (PORT $BADVPN_PORT)"
    info "Instalando dependencias de red..."
    
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
    ok "BadVPN activo y escuchando en 127.0.0.1:$BADVPN_PORT"
}

# ==============================================================================
# CREAR Y REGISTRAR USUARIO
# ==============================================================================
crear_usuario() {
  local u="$1" p="$2" dias="$3"
  
  if [ -z "$u" ] || [ -z "$p" ]; then
    fail "El usuario y la contraseña no pueden estar vacíos."
    return 1
  fi

  if id "$u" >/dev/null 2>&1; then
    info "El usuario '$u' ya existe. Actualizando credenciales..."
    sed -i "/^User: $u /d" "$USERS_FILE" 2>/dev/null
  else
    useradd -M -s /bin/bash "$u" || { fail "No se pudo crear el usuario en el sistema"; return 1; }
  fi

  local pass_hash
  pass_hash="$(openssl passwd -6 "$p" 2>/dev/null)"
  usermod -p "$pass_hash" "$u" || { fail "Error al establecer la contraseña cifrada"; return 1; }
  
  if [[ "$dias" =~ ^[0-9]+$ ]] && [ "$dias" -gt 0 ]; then
    chage -E "$(date -d "+${dias} days" +%Y-%m-%d 2>/dev/null || date -v +${dias}d +%Y-%m-%d 2>/dev/null)" "$u" 2>/dev/null
    DIAS_FINAL="${dias} días"
  else
    chage -E -1 "$u" 2>/dev/null
    DIAS_FINAL="Ilimitado"
  fi

  mkdir -p "$CONFIG_DIR"
  echo "User: $u | Pass: $p | Dias: $DIAS_FINAL" >> "$USERS_FILE"

  USER_FINAL="$u"
  PASS_FINAL="$p"
  return 0
}

ocupados() {
  if command -v ss >/dev/null 2>&1; then
    ss -tln 2>/dev/null | tail -n +2 | awk '{print $4}' | sed 's/.*://'
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln 2>/dev/null | awk '/^tcp/ {print $4}' | sed 's/.*://'
  fi | grep -E '^[0-9]+$' | sort -u
}
libre() { ! ocupados | grep -qx "$1"; }

# ==============================================================================
# INSTALAR SERVIDOR BHTTP
# ==============================================================================
instalar_servidor() {
  titulo
  seccion "INSTALACIÓN DE BHTTP ENGINE"
  
  command -v python3 >/dev/null 2>&1 || { fail "Python3 no está instalado. Ejecuta: apt install -y python3"; pausa; return 1; }
  
  local primer_libre=""
  for p in "${CANDIDATOS[@]}"; do libre "$p" && { primer_libre="$p"; break; }; done
  if [ -z "$PUERTO" ]; then
    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el puerto para BHTTP [${primer_libre:-8080}]: "
    read -r PUERTO
    [ -z "$PUERTO" ] && PUERTO="${primer_libre:-8080}"
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
  configurar_atajo_adm

  if systemctl is-active --quiet "$SERVICE"; then
    ok "¡Servidor BHTTP configurado y operando en el puerto $PUERTO!"
    guardar_config
  else
    fail "El servicio BHTTP no logró inicializarse."
  fi
  pausa
}

# ==============================================================================
# GESTIÓN DE USUARIOS Y CREDENCIALES
# ==============================================================================
menu_usuarios() {
  while true; do
    titulo
    seccion "CENTRO DE GESTIÓN DE USUARIOS Y TÚNELES"
    echo -e "  ${NEON_GREEN}[1]${RESET}  Crear usuario rápido (Manual / 4+ Caracteres)"
    echo -e "  ${NEON_GREEN}[2]${RESET}  Listar usuarios y credenciales activas"
    echo -e "  ${NEON_GREEN}[3]${RESET}  Modificar contraseña de usuario"
    echo -e "  ${NEON_GREEN}[4]${RESET}  Eliminar usuario del sistema"
    echo -e "  ${RED}[0]${RESET}  Regresar al menú principal"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Selecciona una opción: "
    read -r op
    case $op in
      1)
        echo
        echo -ne " ${SKY}◆${RESET} Nombre de usuario: "
        read -r nu
        echo -ne " ${SKY}◆${RESET} Contraseña (mínimo 4 caracteres): "
        read -r np
        echo -ne " ${SKY}◆${RESET} Días de vigencia (ej. 30): "
        read -r nd
        
        if [ ${#np} -lt 4 ]; then
          fail "La contraseña es muy corta. Debe tener mínimo 4 caracteres."
        else
          if crear_usuario "$nu" "$np" "$nd"; then
            local IP_PUB
            IP_PUB="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
            echo
            ok "¡CUENTA CREADA Y CONFIGURADA EXITOSAMENTE!"
            linea
            echo -e "    ${WHITE}Servidor IP  :${RESET} ${NEON_GREEN}${IP_PUB}${RESET}"
            echo -e "    ${WHITE}Puerto BHTTP :${RESET} ${NEON_GREEN}${PUERTO:-8080}${RESET}"
            echo -e "    ${WHITE}Usuario      :${RESET} ${NEON_GREEN}${USER_FINAL}${RESET}"
            echo -e "    ${WHITE}Contraseña   :${RESET} ${NEON_GREEN}${PASS_FINAL}${RESET}"
            echo -e "    ${WHITE}Puerto BadVPN:${RESET} ${NEON_GREEN}${BADVPN_PORT}${RESET}"
            linea
          fi
        fi
        pausa
        ;;
      2)
        echo
        seccion "REGISTRO DE CREDENCIALES ACTIVAS"
        if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
          local IP_PUB
          IP_PUB="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
          echo -e "  ${WHITE}IP Servidor:${RESET} ${NEON_GREEN}${IP_PUB}${RESET} | ${WHITE}Puerto BHTTP:${RESET} ${NEON_GREEN}${PUERTO:-8080}${RESET}"
          linea
          while IFS= read -r linea_usr; do
            echo -e "  🚀 ${CYAN}${linea_usr}${RESET}"
          done < "$USERS_FILE"
        else
          info "Aún no hay cuentas registradas en la base de datos."
        fi
        pausa
        ;;
      3)
        echo
        echo -ne " ${SKY}◆${RESET} Usuario a modificar: "
        read -r nu
        echo -ne " ${SKY}◆${RESET} Nueva contraseña (mínimo 4 caracteres): "
        read -r np
        if [ ${#np} -lt 4 ]; then
          fail "La contraseña debe tener mínimo 4 caracteres."
        elif id "$nu" >/dev/null 2>&1; then
          local pass_hash
          pass_hash="$(openssl passwd -6 "$np" 2>/dev/null)"
          usermod -p "$pass_hash" "$nu"
          sed -i "/^User: $nu /s/| Pass: [^|]* /| Pass: $np /" "$USERS_FILE" 2>/dev/null
          ok "¡Contraseña actualizada con éxito!"
        else
          fail "El usuario ingresado no existe en el sistema."
        fi
        pausa
        ;;
      4)
        echo
        echo -ne " ${RED}◆${RESET} Usuario a eliminar permanentemente: "
        read -r nu
        if id "$nu" >/dev/null 2>&1; then
          userdel -r "$nu" 2>/dev/null
          sed -i "/^User: $nu /d" "$USERS_FILE" 2>/dev/null
          ok "Usuario eliminado por completo."
        else
          fail "El usuario no existe."
        fi
        pausa
        ;;
      0) return ;;
      *) fail "Opción no válida"; pausa ;;
    esac
  done
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
      estado_color="${NEON_GREEN}ACTIVO 🟢${RESET}"
    else
      estado_color="${RED}INACTIVO 🔴${RESET}"
    fi

    echo -e "  ${WHITE}Estado Servidor:${RESET} ${estado_color}  |  ${WHITE}Puerto:${RESET} ${NEON_GREEN}${PUERTO:-No asignado}${RESET}"
    echo -e "  ${WHITE}Comando Rápido :${RESET} ${NEON_PINK}adm${RESET} (Escríbelo en cualquier momento)"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET}  Instalar / Reinstalar BHTTP & BadVPN"
    echo -e "  ${NEON_GREEN}[2]${RESET}  Gestión de Usuarios y Credenciales"
    echo -e "  ${NEON_GREEN}[3]${RESET}  Panel de Control de Servicios (Iniciar / Parar)"
    echo -e "  ${NEON_GREEN}[4]${RESET}  Diagnóstico General del Sistema"
    echo -e "  ${NEON_GREEN}[5]${RESET}  Configurar puerto SSH Backend"
    echo -e "  ${RED}[6]${RESET}  Destrucción Total / Desinstalar Script"
    echo -e "  ${RED}[0]${RESET}  Salir del Panel"
    linea
    echo -ne " ${NEON_ORANGE}◆${RESET} Selecciona una opción [1-6, 0]: "
    read -r opcion
    case $opcion in
      1) instalar_servidor ;;
      2) menu_usuarios ;;
      3) 
        seccion "CONTROL DE SERVICIOS SYSTEMD"
        echo -e "  [1] Iniciar servicios"
        echo -e "  [2] Detener servicios"
        echo -e "  [3] Reiniciar servicios"
        echo -e "  [4] Ver estado en tiempo real"
        echo -ne "  Selecciona: "
        read -r st
        case $st in
          1) systemctl start "$SERVICE" "$BADVPN_SERVICE"; ok "Servicios iniciados"; pausa ;;
          2) systemctl stop "$SERVICE" "$BADVPN_SERVICE"; ok "Servicios detenidos"; pausa ;;
          3) systemctl restart "$SERVICE" "$BADVPN_SERVICE"; ok "Servicios reiniciados"; pausa ;;
          4) systemctl status "$SERVICE" --no-pager; pausa ;;
        esac
        ;;
      4) 
        titulo
        seccion "DIAGNÓSTICO EN VIVO"
        echo -e "  IP Pública   : $(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
        echo -e "  BHTTP Puerto : ${PUERTO:-No configurado}"
        echo -e "  BadVPN Puerto: $BADVPN_PORT"
        echo -e "  SSH Backend  : $SSHPORT"
        echo -e "  Atajo 'adm'  : Activo en /usr/local/bin/adm"
        pausa
        ;;
      5)
        echo -ne " ${SKY}◆${RESET} Ingresa el nuevo puerto SSH backend [${SSHPORT}]: "
        read -r nuevo
        [ -n "$nuevo" ] && SSHPORT="$nuevo" && guardar_config && ok "Puerto SSH actualizado con éxito"
        pausa
        ;;
      6) 
        seccion "DESTRUCCIÓN TOTAL Y LIMPIEZA"
        echo -ne " ${RED}⚠ ¿Estás seguro de eliminar por completo el script, servicios y accesos? (s/n): ${RESET}"
        read -r confirmar
        if [[ "$confirmar" =~ ^[sS]$ ]]; then
          info "Deteniendo servicios..."
          systemctl stop "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null
          systemctl disable "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null
          
          info "Eliminando archivos de programa y directorios..."
          rm -rf "$UNIT" "$BADVPN_UNIT" "$DESTDIR" "$CONFIG_DIR" 2>/dev/null
          rm -f "$SCRIPT_PATH" "$ADM_BIN" 2>/dev/null
          
          info "Limpiando alias y accesos rápidos en terminales..."
          for rc in /root/.bashrc /home/*/.bashrc /root/.zshrc; do
            [ -f "$rc" ] && sed -i '/alias adm=/d' "$rc" 2>/dev/null
          done
          
          systemctl daemon-reload
          systemctl reset-failed
          
          ok "¡DESINSTALACIÓN Y DESTRUCCIÓN TOTAL COMPLETADA CON ÉXITO!"
          echo -e " ${GRAY}El sistema ha quedado limpio. Saliendo...${RESET}"
          exit 0
        else
          info "Operación de desinstalación cancelada."
          pausa
        fi
        ;;
      0) echo -e "\n ${NEON_GREEN}¡Hasta luego, Hazael! Saliendo del panel...${RESET}\n"; exit 0 ;;
      *) fail "Opción inválida. Intenta nuevamente."; pausa ;;
    esac
  done
}

check_root
cargar_config
menu_principal
