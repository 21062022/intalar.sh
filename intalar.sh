#!/usr/bin/env bash
==============================================================================
INSTALADOR DE SCRIPTS MÚLTIPLES DE HAZAEL MORENO - EDICIÓN ULTRA CIBERNÉTICA
PROTOCOLO BHTTP V.1 & BADVPN (TIGO Y CLARO NICARAGUA COMPLETO)
EDICIÓN DE SERVIDOR PREMIUM v7.0
==============================================================================
set -o pipefail
==============================================================================
PALETA DE COLORES VIBRANTES Y NEÓN
==============================================================================
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
ROJO="\e[1;91m"
VERDE="\e[1;92m"
AMARILLO="\e[1;93m"
AZUL="\e[1;94m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
BLANCO="\e[1;97m"
GRIS="\e[1;90m"
CIELO="\e[38;5;117m"
NEON_BLUE="\e[38;5;39m"
NEON_GREEN="\e[38;5;46m"
NEON_PINK="\e[38;5;198m"
NEON_ORANGE="\e[38;5;208m"
NEON_PURPLE="\e[38;5;141m"
NEON_YELLOW="\e[38;5;226m"
==============================================================================
RUTAS Y DIRECTORIOS DEL SISTEMA
==============================================================================
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
PUERTO=""
SSHPORT=22
BADVPN_PORT=7300
==============================================================================
CONFIGURACIÓN DE COMANDOS RÁPIDOS ("adm" / "admin")
==============================================================================
configurar_atajo_adm() {
if [ "$0" != "$SCRIPT_PATH" ] && [ -f "$0" ]; then
cp "$0" "$SCRIPT_PATH" 2>/dev/null || true
fi
chmod +x "$SCRIPT_PATH" 2>/dev/null || true
cat > "ADM_BIN" << 'EOF'
#!/usr/bin/env bash
exec sudo bash /usr/local/bin/intalar.sh "@"
EOF
chmod +x "$ADM_BIN"
cat > "ADMIN_BIN" << 'EOF'
#!/usr/bin/env bash
exec sudo bash /usr/local/bin/intalar.sh "@"
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
==============================================================================
GESTIÓN GLOBAL DE FIREWALL
==============================================================================
abrir_puerto_sistema() {
local p_custom="$1"
info "Aplicando reglas de red y firewall para el puerto $p_custom..."
if command -v ufw >/dev/null 2>&1; then
ufw allow "$p_custom"/tcp >/dev/null 2>&1
ufw allow "$BADVPN_PORT"/tcp >/dev/null 2>&1
ufw allow 22/tcp >/dev/null 2>&1
ufw reload >/dev/null 2>&1 || true
fi
if command -v iptables >/dev/null 2>&1; then
iptables -A INPUT -p tcp --dport "$p_custom" -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport "$BADVPN_PORT" -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
iptables -A INPUT -p tcp --dport 8880 -j ACCEPT 2>/dev/null || true
if command -v netfilter-persistent >/dev/null 2>&1; then
netfilter-persistent save >/dev/null 2>&1 || true
elif [ -d /etc/iptables ]; then
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
fi
fi
ok "Puerto $p_custom y servicios activados correctamente."
}
==============================================================================
INTERFAZ VISUAL
==============================================================================
clear_screen() { clear 2>/dev/null || true; }
linea() { echo -e "{NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}"; }
titulo() {
clear_screen
cargar_config
echo -e "{NEON_PINK}╔══════════════════════════════════════════════════════════════╗{RESET}"
echo -e "{NEON_PINK}║{RESET} {NEON_GREEN}{BOLD}         HAZAEL MORENO MULTI SCRIPT                   {RESET}{NEON_PINK}║{RESET}"
echo -e "{NEON_PINK}║{RESET} ${NEON_BLUE}${BOLD}       BHTTP V.1 & BADVPN PROTOCOL v7.0                ${RESET}${NEON_PINK}║{RESET}"
echo -e "{NEON_PINK}╚══════════════════════════════════════════════════════════════╝{RESET}"
echo -e "      {NEON_ORANGE}🚀 TIGO Y CLARO NICARAGUA • TUNELIZACIÓN MÁXIMA PRO 🚀{RESET}"
echo
if systemctl is-active --quiet "SERVICE" 2>/dev/null; then
STATUS_STR="{NEON_GREEN}{BOLD}ACTIVO 🟢{RESET}"
else
STATUS_STR="{ROJO}{BOLD}INACTIVO 🔴${RESET}"
fi
PUERTO_SHOW="{PUERTO:-8080}"
echo -e " ${BLANCO}${BOLD}Estado Servidor:{RESET} STATUS_STR ${BLANCO}│ Puerto BHTTP:${RESET} ${NEON_YELLOW}${BOLD}$PUERTO_SHOW${RESET}"
echo -e " ${BLANCO}${BOLD}Comandos Rápidos:{RESET} {NEON_PINK}{BOLD}adm${RESET} {BLANCO}o{RESET} {NEON_PINK}{BOLD}admin${RESET}"
linea
}
seccion() {
echo
echo -e "{MAGENTA}╭──────────────────────────────────────────────────────────────╮{RESET}"
echo -e "{MAGENTA}│{RESET} {BLANCO}{BOLD} 1{RESET}"
echo -e "{MAGENTA}╰──────────────────────────────────────────────────────────────╯{RESET}"
echo
}
ok() { echo -e " {NEON_GREEN}✔ [ÉXITO]{RESET} ${BLANCO}1{RESET}"; }
info() { echo -e " {CIELO}◆ [INFO]{RESET} ${BLANCO}1{RESET}"; }
fail() { echo -e " {ROJO}✖ [ERROR]{RESET} ${BLANCO}1{RESET}"; }
pausa() {
echo
echo -e "{GRIS} Presiona ${NEON_GREEN}[Enter]${GRIS} para regresar...{RESET}"
read -r
}
check_root() {
if [ "$(id -u 2>/dev/null || echo 0)" != 0 ]; then
fail "Este script debe ejecutarse como root: sudo bash $0"
exit 2
fi
}
cargar_config() {
mkdir -p "CONFIG_DIR"
[ -f "$CONFIG" ] && source "$CONFIG"
[ -z "${PUERTO:-}" ] && PUERTO="8080"
[ -z "${SSHPORT:-}" ] && SSHPORT=22
[ -z "{BADVPN_PORT:-}" ] && BADVPN_PORT=7300
}
guardar_config() {
mkdir -p "CONFIG_DIR"
cat > "$CONFIG" <<EOF
PUERTO=${PUERTO}
SSHPORT={SSHPORT}
BADVPN_PORT=${BADVPN_PORT}
EOF
}
==============================================================================
INSTALACIÓN DE BADVPN Y BHTTP
==============================================================================
instalar_badvpn() {
apt-get update -y >/dev/null 2>&1
apt-get install -y cmake g++ make wget curl badvpn iptables-persistent cron 2>/dev/null || true
cat > "$BADVPN_UNIT" <<EOF
[Unit]
Description=BadVPN UDP Gateway
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
}
instalar_servidor() {
titulo
seccion "INSTALACIÓN Y CONFIGURACIÓN DE PUERTO BHTTP"
command -v python3 >/dev/null 2>&1 || { fail "Python3 no está instalado."; pausa; return 1; }
local sugerido="${PUERTO:-8080}"
echo -e " {BLANCO}Puerto BHTTP actual/sugerido:{RESET} ${NEON_GREEN}sugerido{RESET}"
echo -ne " {NEON_ORANGE}◆{RESET} Ingresa el nuevo puerto BHTTP (Presiona Enter para mantener $sugerido): "
read -r nuevo_puerto
if [ -n "$nuevo_puerto" ]; then
if [[ "nuevo_puerto" =~ ^[0-9]+ ]] && [ "$nuevo_puerto" -gt 0 ] && [ "$nuevo_puerto" -le 65535 ]; then
PUERTO="$nuevo_puerto"
else
fail "Puerto inválido. Se mantendrá el puerto anterior: $sugerido"
fi
fi
abrir_puerto_sistema "$PUERTO"
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
def init(self, sess, backend):
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
def init(self, host, port, backend):
self.host = host; self.port = port; self.backend = backend
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
if name == "main": main()
PYEOF
chmod +x "$SERVER_PY"
PYBIN="$(command -v python3)"
cat > "$UNIT" <<EOF
[Unit]
Description=Servidor BHTTP (puerto $PUERTO)
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
==============================================================================
GESTIÓN DE USUARIOS
==============================================================================
crear_usuario() {
local u="$1" p="$2" dias="$3"
if id "$u" >/dev/null 2>&1; then
sed -i "/Usuario: $u /d" "$USERS_FILE" 2>/dev/null
else
useradd -M -s /bin/bash "u" || return 1
fi
local pass_hash; pass_hash="(openssl passwd -6 "$p" 2>/dev/null)"
usermod -p "pass_hash" "$u"
if [[ "$dias" =~ ^[0-9]+$ ]] && [ "$dias" -gt 0 ]; then
chage -E "$(date -d "+${dias} days" +%Y-%m-%d 2>/dev/null || date -v +{dias}d +%Y-%m-%d 2>/dev/null)" "u" 2>/dev/null
DIAS_FINAL="{dias} días"
else
chage -E -1 "$u" 2>/dev/null; DIAS_FINAL="Ilimitado"
fi
echo "Usuario: $u \vert{} Contraseña: $p | Dias: $DIAS_FINAL" >> "$USERS_FILE"
}
contar_conexiones_usuario() {
local usr="1"
local online_count
online_count=(ps -u "$usr" 2>/dev/null | grep -E -c 'sshd|bash|sh')
echo "$online_count"
}
monitor_usuarios_tiempo_real() {
clear_screen
if [ ! -f "$USERS_FILE" ] \vert{}\vert{} [ ! -s "$USERS_FILE" ]; then
titulo
seccion "MONITOR EN TIEMPO REAL"
info "No hay usuarios registrados en el sistema."
pausa
return
fi
while true; do
echo -e "\033[H\033[J"
echo -e "{NEON_PINK}╭──────────────────────────────────────────────────────────────╮{RESET}"
echo -e "{NEON_PINK}│{RESET}  {NEON_GREEN}{BOLD}📡 MONITOR DE CONEXIONES EN TIEMPO REAL (AUTO-REFRESH){RESET}  ${NEON_PINK}│${RESET}"
echo -e "{NEON_PINK}╰──────────────────────────────────────────────────────────────╯{RESET}"
echo -e " ${CIELO}Estado Actual de Cuentas y Dispositivos Conectados:${RESET}"
echo -e "{NEON_BLUE}──────────────────────────────────────────────────────────────${RESET}"
printf " %-12s %-16s %-20s %-15s\n" "ESTADO" "USUARIO" "CONEXIONES" "VIGENCIA"
echo -e "{NEON_BLUE}──────────────────────────────────────────────────────────────{RESET}"
total_online=0
while IFS= read -r line || [ -n "line" ]; do
usr=(echo "$line" | awk '{print $2}')
[ -z "$usr" ] && continue
dias=$(echo "$line" | awk -F'|' '{print 3}' | sed 's/.*: //')
con_count=(contar_conexiones_usuario "$usr")
if [ "con_count" -gt 0 ]; then
status="{NEON_GREEN}🟢 ONLINE {RESET}"
usr_color="{NEON_GREEN}{BOLD}"
con_str="{VERDE}{con_count} en línea{RESET}"
total_online=((total_online + con_count))
else
status="{ROJO}🔴 OFFLINE${RESET}"
usr_color="{BLANCO}"
con_str="{GRIS}0 en línea${RESET}"
fi
printf " %-12s {usr_color}\%-16s{RESET} %-20s %-15s\n" "$status" "$usr" "$con_str" "$dias"
done < "$USERS_FILE"
echo -e "{NEON_BLUE}──────────────────────────────────────────────────────────────{RESET}"
echo -e " {NEON_ORANGE}🔥 Total de dispositivos activos globalmente:{RESET} {NEON_GREEN}{BOLD}total_online{RESET}"
echo -e "{NEON_BLUE}──────────────────────────────────────────────────────────────{RESET}"
echo -e " {GRIS}Escribe ${AMARILLO}q${GRIS} + Enter para salir (Refresco automático cada 2s)...{RESET}"
read -t 2 -r input
if [[ "$input" == "q" \vert{}\vert{} "$input" == "Q" ]]; then
break
fi
done
}
detalles_usuarios_existentes() {
titulo
seccion "DETALLES DE USUARIOS EXISTENTES CREADOS"
if [ ! -f "$USERS_FILE" ] \vert{}\vert{} [ ! -s "$USERS_FILE" ]; then
info "No hay usuarios registrados en la base de datos."
pausa
return
fi
printf " {NEON_BLUE}\%-4s \%-18s \%-18s \%-15s{RESET}\n" "N°" "USUARIO" "CONTRASEÑA 🔑" "DÍAS / EXPIRA"
echo -e "{NEON_BLUE}──────────────────────────────────────────────────────────────{RESET}"
local i=1
while IFS= read -r line || [ -n "line" ]; do
usr=(echo "$line" | awk '{print 2}')
pass=(echo "$line" | awk -F'|' '{print 2}' | sed 's/.*: //')
dias=(echo "$line" | awk -F'|' '{print $3}' | sed 's/.*: //')
[ -z "$usr" ] && continue
printf " {NEON_GREEN}\%-4s{RESET} {BLANCO}\%-18s{RESET} {NEON_YELLOW}\%-18s{RESET} {CIELO}\%-15s{RESET}\n" "[$i]" "$usr" "pass" "$dias"
i=$((i + 1))
done < "$USERS_FILE"
echo -e "${NEON_BLUE}──────────────────────────────────────────────────────────────{RESET}"
pausa
}
editar_usuario_lista() {
titulo
seccion "EDITAR USUARIOS CREADOS"
if [ ! -f "$USERS_FILE" ] \vert{}\vert{} [ ! -s "$USERS_FILE" ]; then
info "No hay usuarios disponibles para editar."
pausa
return
fi
echo -e " {BLANCO}Selecciona el número del usuario que deseas editar:{RESET}"
echo
local i=1
declare -A map_usr
while IFS= read -r line || [ -n "line" ]; do
usr=(echo "$line" | awk '{print $2}')
[ -z "$usr" ] && continue
map_usr[$i]="usr"
echo -e " ${NEON_GREEN}[$i]${RESET} Usuario:${BLANCO}$usr${RESET}"
i=((i + 1))
done < "$USERS_FILE"
echo
echo -ne " {NEON_ORANGE}◆{RESET} Ingresa el número [1-$((i-1))]: "
read -r sel
if [ -n "${map_usr[sel]}" ]; then
local target_user="{map_usr[$sel]}"
echo -e "\n {CIELO}Editando usuario:{RESET} {NEON_GREEN}{BOLD}target_user{RESET}"
echo -ne " Nueva contraseña 🔑 (Presiona Enter para mantener): "
read -r new_pass
echo -ne " Nuevos Días de Vigencia (Presiona Enter para mantener): "
read -r new_days
if [ -n "new_pass" ]; then
local pass_hash; pass_hash="(openssl passwd -6 "$new_pass" 2>/dev/null)"
usermod -p "$pass_hash" "target_user"
else
new_pass=(grep "Usuario: $target_user " "$USERS_FILE" | awk -F'|' '{print $2}' | sed 's/.*: //')
fi
if [ -n "new_days" ] && [[ "$new_days" =~ ^[0-9]+$ ]]; then
chage -E "(date -d "+{new_days} days" +%Y-%m-%d 2>/dev/null || date -v +{new_days}d +%Y-%m-%d 2>/dev/null)" "target_user" 2>/dev/null
dias_final="{new_days} días"
else
dias_final=$(grep "Usuario: $target_user " "$USERS_FILE" | awk -F'|' '{print $3}' | sed 's/.*: //')
fi
sed -i "/Usuario: $target_user /d" "$USERS_FILE" 2>/dev/null
echo "Usuario: $target_user \vert{} Contraseña: $new_pass | Dias: $dias_final" >> "$USERS_FILE"
ok "¡Usuario $target_user actualizado correctamente!"
else
fail "Selección inválida."
fi
pausa
}
eliminar_usuario_lista() {
titulo
seccion "ELIMINAR USUARIO DE LA LISTA"
if [ ! -f "$USERS_FILE" ] \vert{}\vert{} [ ! -s "$USERS_FILE" ]; then
info "No hay usuarios para eliminar."
pausa
return
fi
local i=1
declare -A map_usr
while IFS= read -r line || [ -n "line" ]; do
usr=(echo "$line" | awk '{print $2}')
[ -z "$usr" ] && continue
map_usr[$i]="usr"
echo -e " ${NEON_GREEN}[$i]${RESET} Usuario:${BLANCO}$usr${RESET}"
i=((i +
i + 1))
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

# ==============================================================================
# BORRAR TODOS LOS USUARIOS CREADOS
# ==============================================================================
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

# ==============================================================================
# MENÚ GESTIÓN DE USUARIOS
# ==============================================================================
menu_usuarios() {
  while true; do
    titulo
    seccion "GESTIÓN DE USUARIOS Y CREDENCIALES"
    echo -e " ${NEON_GREEN}[1]${RESET} Crear usuario rápido"
    echo -e " ${NEON_GREEN}[2]${RESET} Monitor de usuarios en tiempo real (En línea / Desconectado)"
    echo -e " ${NEON_GREEN}[3]${RESET} Ver detalles de usuarios creados (Nombre, Contraseña 🔑 y Días)"
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
    
    # Crear script de mantenimiento ligero
    cat << 'EOF' > /usr/local/bin/optimizar_vps.sh
#!/bin/bash
sync; echo 3 > /proc/sys/vm/drop_caches
systemctl restart bhttp badvpn 2>/dev/null
EOF
    chmod +x /usr/local/bin/optimizar_vps.sh

    # Agregar a cronjob cada 6 horas si no existe
    (crontab -l 2>/dev/null | grep -v "optimizar_vps.sh" ; echo "0 */6 * * * /usr/local/bin/optimizar_vps.sh >/dev/null 2>&1") | crontab -
    
    # Ejecutar optimización una vez de inmediato
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
