#!/usr/bin/env bash
# ==============================================================================
# HAZAEL MORENO MULTI SCRIPT - BHTTP & BADVPN
# Versión PRO • MONITOR EN LÍNEA 2s • ROOT EXCLUIDO • SSH/BHTTP
# ==============================================================================

set -o pipefail

RESET="\e[0m"; BOLD="\e[1m"; DIM="\e[2m"
RED="\e[1;91m"; GREEN="\e[1;92m"; YELLOW="\e[1;93m"
BLUE="\e[1;94m"; MAGENTA="\e[1;95m"; CYAN="\e[1;96m"
WHITE="\e[1;97m"; GRAY="\e[1;90m"
SKY="\e[38;5;117m"; NEON_BLUE="\e[38;5;39m"; NEON_GREEN="\e[38;5;46m"
NEON_PINK="\e[38;5;198m"; NEON_ORANGE="\e[38;5;208m"

DESTDIR="/usr/local/lib/bhttp"
SERVER_PY="$DESTDIR/bhttp-server.py"
UNIT="/etc/systemd/system/bhttp.service"
BADVPN_UNIT="/etc/systemd/system/badvpn.service"
SERVICE="bhttp"; BADVPN_SERVICE="badvpn"
CONFIG_DIR="/etc/bhttp"
CONFIG="$CONFIG_DIR/nullcore.conf"
USERS_FILE="$CONFIG_DIR/cuentas.txt"
IP_CACHE_FILE="$CONFIG_DIR/public_ip.cache"
SCRIPT_PATH="/usr/local/bin/intalar.sh"
ADM_BIN="/usr/local/bin/adm"
ADMIN_BIN="/usr/local/bin/admin"
PUERTO="443"; SSHPORT=22; BADVPN_PORT=7300
BADVPN_STATE="OFF"; AUTOSTART_STATUS="OFF"; CRON_STATUS="OFF"; BBR_STATUS="OFF"

GITHUB_URL="https://raw.githubusercontent.com/21062022/intalar.sh/main/intalar.sh"

clear_screen(){ clear 2>/dev/null || true; }
linea(){ echo -e "${NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
ok(){ echo -e " ${NEON_GREEN}✔ [ÉXITO]${RESET} ${WHITE}$1${RESET}"; }
info(){ echo -e " ${SKY}◆ [INFO]${RESET} ${WHITE}$1${RESET}"; }
fail(){ echo -e " ${RED}✖ [ERROR]${RESET} ${WHITE}$1${RESET}"; }
pausa(){ echo; read -r -p "$(echo -e "${GRAY}Presiona ${NEON_GREEN}[Enter]${GRAY} para regresar...${RESET}")"; }

check_root(){
  if [ "$(id -u 2>/dev/null || echo 0)" -ne 0 ]; then
    fail "Este script debe ejecutarse como root: sudo bash $0"
    exit 2
  fi
}

obtener_ip_publica(){
  local ip_pub=""

  # Usar caché si existe y es reciente para no bloquear el panel.
  if [ -s "$IP_CACHE_FILE" ]; then
    local ahora mtime
    ahora="$(date +%s 2>/dev/null || echo 0)"
    mtime="$(stat -c %Y "$IP_CACHE_FILE" 2>/dev/null || echo 0)"
    if [ "$mtime" -gt 0 ] && [ $((ahora-mtime)) -lt 3600 ]; then
      cat "$IP_CACHE_FILE"
      return 0
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    ip_pub="$(curl -4fsS --max-time 1 https://api.ipify.org 2>/dev/null || true)"
  fi

  [ -z "$ip_pub" ] && ip_pub="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -z "$ip_pub" ] && ip_pub="127.0.0.1"

  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  printf '%s\n' "$ip_pub" > "$IP_CACHE_FILE" 2>/dev/null || true
  echo "$ip_pub"
}

titulo(){
  clear_screen
  local ip_maquina
  ip_maquina="$(obtener_ip_publica)"
  echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${NEON_PINK}║${RESET} ${NEON_GREEN}${BOLD}                   HAZAEL MORENO MULTI SCRIPT${RESET}              ${NEON_PINK}║${RESET}"
  echo -e "${NEON_PINK}║${RESET} ${NEON_BLUE}${BOLD}              BHTTP V.1 & BADVPN PROTOCOL v8.0${RESET}             ${NEON_PINK}║${RESET}"
  echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${SKY}     🚀 ${NEON_ORANGE}TIGO Y CLARO NICARAGUA${RESET} ${SKY}• IP: ${YELLOW}${BOLD}$ip_maquina${RESET} 🚀${RESET}"
  echo
}
titulo_rapido(){
  clear_screen
  local ip_maquina=""

  if [ -s "$IP_CACHE_FILE" ]; then
    ip_maquina="$(head -n1 "$IP_CACHE_FILE" 2>/dev/null)"
  fi

  [ -z "$ip_maquina" ] && ip_maquina="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -z "$ip_maquina" ] && ip_maquina="127.0.0.1"

  echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${NEON_PINK}║${RESET} ${NEON_GREEN}${BOLD}                   HAZAEL MORENO MULTI SCRIPT${RESET}              ${NEON_PINK}║${RESET}"
  echo -e "${NEON_PINK}║${RESET} ${NEON_BLUE}${BOLD}              BHTTP V.1 & BADVPN PROTOCOL v8.0${RESET}             ${NEON_PINK}║${RESET}"
  echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${SKY}     🚀 ${NEON_ORANGE}TIGO Y CLARO NICARAGUA${RESET} ${SKY}• IP: ${YELLOW}${BOLD}$ip_maquina${RESET} 🚀${RESET}"
  echo
}

seccion(){
  echo
  echo -e "${MAGENTA}┌──────────────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${MAGENTA}│${RESET} ${WHITE}${BOLD} $1${RESET}"
  echo -e "${MAGENTA}└──────────────────────────────────────────────────────────────────┘${RESET}"
  echo
}

configurar_atajo_adm(){
  if [ "$0" != "$SCRIPT_PATH" ] && [ -f "$0" ]; then
    cp "$0" "$SCRIPT_PATH" 2>/dev/null || true
  fi
  chmod +x "$SCRIPT_PATH" 2>/dev/null || true
  cat > "$ADM_BIN" <<'EOF'
#!/usr/bin/env bash
exec sudo bash /usr/local/bin/intalar.sh "$@"
EOF
  cat > "$ADMIN_BIN" <<'EOF'
#!/usr/bin/env bash
exec sudo bash /usr/local/bin/intalar.sh "$@"
EOF
  chmod +x "$ADM_BIN" "$ADMIN_BIN"
  for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
    if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
      touch "$rc" 2>/dev/null || true
      sed -i '/alias adm=/d;/alias admin=/d' "$rc" 2>/dev/null || true
      echo "alias adm='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
      echo "alias admin='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
    fi
  done
}

cargar_config(){
  mkdir -p "$CONFIG_DIR"
  [ -f "$CONFIG" ] && source "$CONFIG"
  : "${PUERTO:=443}"; : "${SSHPORT:=22}"; : "${BADVPN_PORT:=7300}"
  : "${BADVPN_STATE:=OFF}"; : "${AUTOSTART_STATUS:=OFF}"
  : "${CRON_STATUS:=OFF}"; : "${BBR_STATUS:=OFF}"
}
guardar_config(){
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG" <<EOF
PUERTO=$PUERTO
SSHPORT=$SSHPORT
BADVPN_PORT=$BADVPN_PORT
BADVPN_STATE=$BADVPN_STATE
AUTOSTART_STATUS=$AUTOSTART_STATUS
CRON_STATUS=$CRON_STATUS
BBR_STATUS=$BBR_STATUS
EOF
}

abrir_puerto_sistema(){
  local p="$1"
  info "Aplicando reglas de firewall para el puerto $p..."
  if command -v ufw >/dev/null 2>&1; then
    ufw allow "$p"/tcp >/dev/null 2>&1 || true
    ufw allow "$p"/udp >/dev/null 2>&1 || true
    ufw allow "$BADVPN_PORT"/tcp >/dev/null 2>&1 || true
    ufw allow "$BADVPN_PORT"/udp >/dev/null 2>&1 || true
    ufw allow 22/tcp >/dev/null 2>&1 || true
    ufw reload >/dev/null 2>&1 || true
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -C INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null || true
    iptables -C INPUT -p udp --dport "$p" -j ACCEPT 2>/dev/null || iptables -A INPUT -p udp --dport "$p" -j ACCEPT 2>/dev/null || true
    iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
    iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
    if command -v netfilter-persistent >/dev/null 2>&1; then
      netfilter-persistent save >/dev/null 2>&1 || true
    elif [ -d /etc/iptables ]; then
      iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi
  fi
  ok "Puertos y firewall actualizados correctamente."
}

instalar_badvpn(){
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y badvpn iptables-persistent >/dev/null 2>&1 || true
  local bin=""
  for x in /usr/bin/badvpn-udpgw /usr/local/bin/badvpn-udpgw; do
    [ -x "$x" ] && { bin="$x"; break; }
  done
  [ -z "$bin" ] && bin="$(command -v badvpn-udpgw 2>/dev/null || true)"
  if [ -z "$bin" ]; then
    fail "No se encontró badvpn-udpgw en el sistema."
    return 1
  fi
  cat > "$BADVPN_UNIT" <<EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=$bin --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 500 --max-connections 1000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

instalar_servidor(){
  titulo
  seccion "INSTALACIÓN Y CONFIGURACIÓN DE PUERTO BHTTP"
  command -v python3 >/dev/null 2>&1 || { fail "Python3 no está instalado."; pausa; return 1; }
  local sugerido="${PUERTO:-443}" nuevo_puerto
  echo -e "  ${WHITE}Puerto BHTTP actual/sugerido:${RESET} ${NEON_GREEN}$sugerido${RESET}"
  read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Ingresa el nuevo puerto BHTTP (Enter mantiene $sugerido): ")" nuevo_puerto
  if [ -n "$nuevo_puerto" ]; then
    if [[ "$nuevo_puerto" =~ ^[0-9]+$ ]] && [ "$nuevo_puerto" -gt 0 ] && [ "$nuevo_puerto" -le 65535 ]; then
      PUERTO="$nuevo_puerto"
    else
      fail "Puerto inválido. Se mantendrá $sugerido."
      PUERTO="$sugerido"
    fi
  else
    PUERTO="$sugerido"
  fi

  abrir_puerto_sistema "$PUERTO"
  mkdir -p "$DESTDIR"

  cat > "$SERVER_PY" <<'PYEOF'
#!/usr/bin/env python3
import argparse, asyncio, hashlib, time

MAGIC=b"BHP1"
READ_TIMEOUT=20.0
BACKEND_CONNECT_TIMEOUT=10.0
SESSION_IDLE_TIMEOUT=90.0
SESSION_MAX_AGE=21600.0
CLEANUP_INTERVAL=15.0
LONGPOLL=2.0
FRONTEND_GRACE=1.0
MAX_DOWN_BUFFER=8*1024*1024
MAX_DOWN_CHUNKS=2048
MAX_PAYLOAD=1024*1024
HEADER_SIZE=29
MAX_MULTI_COUNT=64

def keystream(sess, mode, seq, d, n):
    base=hashlib.sha256(sess+bytes([mode])+seq.to_bytes(8,"big")+bytes([d]))
    out=bytearray(); c=0
    while len(out)<n:
        h=base.copy(); h.update(c.to_bytes(4,"big")); out+=h.digest(); c+=1
    return bytes(out[:n])

def mask(data,sess,mode,seq,d):
    return bytes(a^b for a,b in zip(data,keystream(sess,mode,seq,d,len(data))))

def probe_reply(mode,size):
    n=size if mode==2 and size>=10 else 10
    out=bytearray(MAGIC+bytes([1,mode])+size.to_bytes(4,"big"))
    for i in range(10,n): out.append((i*31)&255)
    return bytes(out)

class Session:
    def __init__(self,sess,backend):
        self.sess=sess; self.backend=backend; self.cond=asyncio.Condition()
        self.up_next=0; self.up_pending={}
        self.down_raw=bytearray(); self.down_chunks={}; self.down_assign=0
        self.eof=False; self.closed=False
        self.br=None; self.bw=None; self.reader_task=None
        now=time.monotonic(); self.created_at=now; self.last_activity=now
        self.write_lock=asyncio.Lock()
        # Conexiones BHTTP (frontend) actualmente asociadas a esta sesión.
        # Cuando llega a cero, cerramos el backend SSH tras una pequeña
        # ventana de gracia para detectar la desconexión rápidamente sin
        # romper una reconexión inmediata con el mismo ID de sesión.
        self.frontend_count=0
        self.frontend_lock=asyncio.Lock()
        self.frontend_close_task=None
    def touch(self): self.last_activity=time.monotonic()
    def idle_for(self): return time.monotonic()-self.last_activity
    def age(self): return time.monotonic()-self.created_at
    async def connect(self):
        try:
            self.br,self.bw=await asyncio.wait_for(
                asyncio.open_connection(self.backend[0],self.backend[1],limit=65536),
                timeout=BACKEND_CONNECT_TIMEOUT)
            self.touch(); self.reader_task=asyncio.create_task(self._reader()); return True
        except Exception:
            self.closed=True; await self._close_backend(); return False
    async def _reader(self):
        try:
            while not self.closed:
                data=await self.br.read(65536)
                if not data: break
                self.touch()
                async with self.cond:
                    if self.closed: break
                    if len(self.down_raw)+len(data)>MAX_DOWN_BUFFER:
                        self.closed=True; self.eof=True; self.cond.notify_all(); break
                    self.down_raw.extend(data); self.cond.notify_all()
        except asyncio.CancelledError: raise
        except Exception: pass
        finally:
            async with self.cond:
                self.eof=True; self.cond.notify_all()
    async def upload(self,seq,data):
        if self.closed: return False
        self.touch()
        async with self.cond:
            if data:
                if len(self.up_pending)>=MAX_DOWN_CHUNKS:
                    self.closed=True; self.cond.notify_all(); return False
                self.up_pending[seq]=data
        async with self.write_lock:
            while True:
                async with self.cond:
                    if self.closed: return False
                    chunk=self.up_pending.pop(self.up_next,None)
                    if chunk is None: break
                try:
                    self.bw.write(chunk); await asyncio.wait_for(self.bw.drain(),timeout=READ_TIMEOUT); self.touch()
                except asyncio.CancelledError: raise
                except Exception:
                    self.closed=True
                    async with self.cond: self.cond.notify_all()
                    return False
                self.up_next+=1
        return True
    async def download(self,seq,maxlen,deadline):
        if self.closed: return b""
        maxlen=min(max(maxlen,1),MAX_PAYLOAD)
        loop=asyncio.get_running_loop()
        async with self.cond:
            while True:
                if self.closed: return b""
                if seq<self.down_assign: return self.down_chunks.get(seq,b"")
                if seq==self.down_assign:
                    if self.down_raw:
                        take=bytes(self.down_raw[:maxlen]); del self.down_raw[:maxlen]
                        self.down_chunks[self.down_assign]=take; self.down_assign+=1
                        self.touch(); self.cond.notify_all(); return take
                    if self.eof:
                        self.down_assign+=1; self.cond.notify_all(); return b""
                remaining=deadline-loop.time()
                if not self.eof and not self.closed and remaining>0:
                    try: await asyncio.wait_for(self.cond.wait(),timeout=remaining)
                    except asyncio.TimeoutError: pass
                    continue
                while self.down_assign<=seq: self.down_assign+=1
                self.cond.notify_all(); return b""
    async def ack(self,seq):
        if self.closed: return
        self.touch()
        async with self.cond:
            for k in [k for k in self.down_chunks if k<=seq]: del self.down_chunks[k]
    async def attach_frontend(self):
        async with self.frontend_lock:
            if self.frontend_close_task is not None:
                task=self.frontend_close_task
                self.frontend_close_task=None
                if not task.done():
                    task.cancel()
                try:
                    await task
                except asyncio.CancelledError:
                    pass
                except Exception:
                    pass
            self.frontend_count += 1

    async def detach_frontend(self):
        async with self.frontend_lock:
            if self.frontend_count > 0:
                self.frontend_count -= 1

            if self.frontend_count == 0 and not self.closed:
                # Cierre rápido del backend tras la desconexión del cliente.
                # La gracia de 1 segundo permite una reconexión inmediata.
                if self.frontend_close_task is None or self.frontend_close_task.done():
                    self.frontend_close_task=asyncio.create_task(
                        self._close_if_no_frontend(),
                        name="bhttp-frontend-grace-close"
                    )

    async def _close_if_no_frontend(self):
        try:
            await asyncio.sleep(FRONTEND_GRACE)
            async with self.frontend_lock:
                if self.frontend_count != 0 or self.closed:
                    return
            await self.close()
        except asyncio.CancelledError:
            pass
        except Exception:
            pass

    async def _close_backend(self):
        writer=self.bw; self.bw=None; self.br=None
        if writer:
            try: writer.close(); await asyncio.wait_for(writer.wait_closed(),timeout=3)
            except Exception: pass
    async def close(self):
        self.closed=True

        close_task=self.frontend_close_task
        self.frontend_close_task=None
        if close_task is not None and close_task is not asyncio.current_task() and not close_task.done():
            close_task.cancel()
            try:
                await close_task
            except asyncio.CancelledError:
                pass
            except Exception:
                pass
        async with self.cond:
            self.eof=True; self.down_raw.clear(); self.down_chunks.clear(); self.up_pending.clear(); self.cond.notify_all()
        task=self.reader_task
        if task and task is not asyncio.current_task() and not task.done():
            task.cancel()
            try: await asyncio.wait_for(task,timeout=2)
            except Exception: pass
        await self._close_backend(); self.reader_task=None

class Server:
    def __init__(self,host,port,backend):
        self.host=host; self.port=port; self.backend=backend
        self.sessions={}; self.slock=asyncio.Lock(); self.cleanup_task=None; self.stopping=False
    async def get_session(self,sess):
        async with self.slock:
            s=self.sessions.get(sess)
            if s and not s.closed and s.idle_for()<=SESSION_IDLE_TIMEOUT and s.age()<=SESSION_MAX_AGE:
                s.touch(); return s
            if s:
                self.sessions.pop(sess,None); await s.close()
            s=Session(sess,self.backend)
            if not await s.connect(): await s.close(); return None
            self.sessions[sess]=s; return s
    async def cleanup_sessions(self):
        while not self.stopping:
            try:
                await asyncio.sleep(CLEANUP_INTERVAL); now=time.monotonic(); dead=[]
                async with self.slock:
                    for sid,s in list(self.sessions.items()):
                        if now-s.last_activity>SESSION_IDLE_TIMEOUT or now-s.created_at>SESSION_MAX_AGE or s.closed:
                            dead.append(s); self.sessions.pop(sid,None)
                for s in dead:
                    try: await s.close()
                    except Exception: pass
            except asyncio.CancelledError: break
            except Exception: continue
    async def _read_exactly(self,reader,size): return await asyncio.wait_for(reader.readexactly(size),timeout=READ_TIMEOUT)
    async def _safe_drain(self,writer): await asyncio.wait_for(writer.drain(),timeout=READ_TIMEOUT)
    def _send_data(self,writer,sess,mode,seq,data):
        masked=mask(data,sess,mode,seq,1) if data else b""
        body=len(data).to_bytes(4,"big")+masked
        writer.write(bytes([2])+len(body).to_bytes(4,"big")+body)
    async def handle(self,reader,writer):
        s=None
        attached_session=None
        try:
            while not self.stopping:
                try: hdr=await self._read_exactly(reader,HEADER_SIZE)
                except (asyncio.IncompleteReadError,asyncio.TimeoutError): break
                if len(hdr)!=HEADER_SIZE: break
                mode=hdr[0]; sess=hdr[1:17]; seq=int.from_bytes(hdr[17:25],"big"); ln=int.from_bytes(hdr[25:29],"big")
                if mode not in (0,1,2,3,4) or ln>MAX_PAYLOAD: break
                payload=b""
                if ln and mode in (0,1,2,3):
                    try: raw=await self._read_exactly(reader,ln)
                    except (asyncio.IncompleteReadError,asyncio.TimeoutError): break
                    payload=mask(raw,sess,mode,seq,0)
                if payload[:4]==MAGIC:
                    size=int.from_bytes(payload[6:10],"big") if len(payload)>=10 else 0
                    pmode=payload[5] if len(payload)>=6 else mode
                    size=min(max(size,0),MAX_PAYLOAD)
                    body=mask(probe_reply(pmode,size),sess,mode,seq,1)
                    writer.write(bytes([0])+len(body).to_bytes(4,"big")+body); await self._safe_drain(writer); continue
                s=await self.get_session(sess)
                if not s: break
                if attached_session is not s:
                    if attached_session is not None:
                        try:
                            await attached_session.detach_frontend()
                        except Exception:
                            pass
                    await s.attach_frontend()
                    attached_session=s
                s.touch()
                if mode==1:
                    if not await s.upload(seq,payload): break
                    writer.write(bytes([0])+(0).to_bytes(4,"big")); await self._safe_drain(writer)
                elif mode==2:
                    chunk=await s.download(seq,ln if ln else 1399,asyncio.get_running_loop().time()+LONGPOLL)
                    self._send_data(writer,sess,mode,seq,chunk); await self._safe_drain(writer)
                elif mode==3:
                    chunk_size=1399; count=1
                    if len(payload)>=6:
                        chunk_size=int.from_bytes(payload[:4],"big"); count=payload[5]
                    chunk_size=min(max(chunk_size,1),MAX_PAYLOAD); count=min(max(count,1),MAX_MULTI_COUNT)
                    deadline=asyncio.get_running_loop().time()+LONGPOLL
                    for i in range(count):
                        if s.closed: break
                        chunk=await s.download(seq+i,chunk_size,deadline); self._send_data(writer,sess,mode,seq+i,chunk)
                    await self._safe_drain(writer)
                elif mode==4:
                    await s.ack(seq); writer.write(bytes([0])+(0).to_bytes(4,"big")); await self._safe_drain(writer)
                else: break
        except asyncio.CancelledError: raise
        except Exception: pass
        finally:
            # Desasocia la conexión BHTTP actual. Si ya no quedan
            # conexiones frontend, la sesión SSH backend se cierra
            # rápidamente; esto hace que el monitor vea la desconexión.
            try:
                if attached_session is not None:
                    await attached_session.detach_frontend()
            except Exception:
                pass
            try:
                writer.close()
                try: await asyncio.wait_for(writer.wait_closed(),timeout=3)
                except Exception: pass
            except Exception: pass
    async def close_all_sessions(self):
        async with self.slock:
            sessions=list(self.sessions.values()); self.sessions.clear()
        for s in sessions:
            try: await s.close()
            except Exception: pass
    async def serve(self):
        srv=await asyncio.start_server(self.handle,self.host,self.port,backlog=512,limit=65536)
        self.cleanup_task=asyncio.create_task(self.cleanup_sessions())
        try:
            async with srv: await srv.serve_forever()
        finally:
            self.stopping=True
            if self.cleanup_task:
                self.cleanup_task.cancel()
                try: await self.cleanup_task
                except BaseException: pass
            await self.close_all_sessions()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--host",default="0.0.0.0"); ap.add_argument("--port",type=int,required=True)
    ap.add_argument("--backend-host",default="127.0.0.1"); ap.add_argument("--backend-port",type=int,default=22)
    a=ap.parse_args()
    try: asyncio.run(Server(a.host,a.port,(a.backend_host,a.backend_port)).serve())
    except KeyboardInterrupt: pass

if __name__=="__main__": main()
PYEOF

  chmod +x "$SERVER_PY"
  local pybin; pybin="$(command -v python3)"
  cat > "$UNIT" <<EOF
[Unit]
Description=BHTTP Server (puerto $PUERTO)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$pybin $SERVER_PY --host 0.0.0.0 --port $PUERTO --backend-host 127.0.0.1 --backend-port $SSHPORT
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable "$SERVICE" >/dev/null 2>&1 || true
  systemctl restart "$SERVICE" >/dev/null 2>&1 || true
  instalar_badvpn || true
  configurar_atajo_adm
  guardar_config
  ok "Servidor BHTTP instalado/reinstalado correctamente."
  pausa
}

crear_usuario(){
  local u="$1" p="$2" dias="$3"
  if ! [[ "$u" =~ ^[a-zA-Z0-9._-]+$ ]]; then fail "Nombre de usuario inválido."; return 1; fi
  if id "$u" >/dev/null 2>&1; then
    sed -i "/^User: $u |/d" "$USERS_FILE" 2>/dev/null || true
  else
    useradd -M -s /bin/bash "$u" || return 1
  fi
  local pass_hash; pass_hash="$(openssl passwd -6 "$p" 2>/dev/null)" || return 1
  usermod -p "$pass_hash" "$u" || return 1
  local DIAS_FINAL
  if [[ "$dias" =~ ^[0-9]+$ ]] && [ "$dias" -gt 0 ]; then
    local exp; exp="$(date -d "+${dias} days" +%Y-%m-%d 2>/dev/null || true)"
    [ -n "$exp" ] && chage -E "$exp" "$u" 2>/dev/null || true
    DIAS_FINAL="${dias} días"
  else
    chage -E -1 "$u" 2>/dev/null || true
    DIAS_FINAL="Ilimitado"
  fi
  echo "User: $u | Pass: $p | Dias: $DIAS_FINAL" >> "$USERS_FILE"
}

extraer_usuario(){
  echo "$1" | grep -oP 'User: \K[^|]+' | xargs
}

# ------------------------------------------------------------------------------
# USUARIOS DEL PANEL
# Solo muestra las cuentas creadas/registradas desde este panel.
# No incluye root, usuarios del sistema ni sesiones ajenas al panel.
# ------------------------------------------------------------------------------
obtener_usuarios_panel(){
  local linea_usu u

  [ -s "$USERS_FILE" ] || return 0

  while IFS= read -r linea_usu; do
    u="$(extraer_usuario "$linea_usu")"

    [ -z "$u" ] && continue
    [ "$u" = "root" ] && continue

    echo "$u"
  done < "$USERS_FILE"
}

# ------------------------------------------------------------------------------
# FOTOGRAFÍA RÁPIDA DE SESIONES SSH
# Una sola lectura de procesos por actualización.
# Así evitamos hacer comandos por separado para cada usuario y la pantalla
# responde rápidamente incluso con bastantes cuentas.
# ------------------------------------------------------------------------------
obtener_conexiones_ssh(){
  # --------------------------------------------------------------------------
  # CONTEO REAL DE DISPOSITIVOS CONECTADOS (v2)
  #
  # Cambios respecto a la versión anterior:
  #   - Se cuenta POR CONEXIÓN TCP ESTABLECIDA (IP:puerto del cliente), no por
  #     proceso. Antes un mismo dispositivo sumaba varias veces (proceso
  #     privilegiado + proceso de sesión + sesiones extra del mismo cliente).
  #   - Las conexiones se deduplican: una conexión = 1 dispositivo.
  #   - Si el socket ya no está ESTABLISHED, deja de contarse al instante.
  #   - Fallback por tabla de procesos solo si "ss" no existe.
  #   - Nunca cuenta root ni nombres raros.
  # --------------------------------------------------------------------------

  declare -A conteo=()
  declare -A proc_user=()
  declare -A proc_args=()
  declare -A conn_vista=()

  local line pid owner args usuario peer found p
  local ssh_port="${SSHPORT:-22}"
  local proc_snapshot=""
  local sockets=""

  proc_snapshot="$(ps -eo pid=,user=,args= 2>/dev/null || true)"

  while read -r pid owner args; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    proc_user["$pid"]="$owner"
    proc_args["$pid"]="$args"
  done <<< "$proc_snapshot"

  if command -v ss >/dev/null 2>&1; then
    # Solo conexiones ESTABLISHED cuyo puerto local es el de SSH.
    sockets="$(ss -Hntp state established "( sport = :$ssh_port )" 2>/dev/null || true)"

    while IFS= read -r line; do
      [ -n "$line" ] || continue

      # Dirección del cliente (penúltima columna antes de users:).
      peer="$(awk '{print $(NF-1)}' <<< "$line")"
      [ -n "$peer" ] || continue
      [ -n "${conn_vista[$peer]:-}" ] && continue

      usuario=""
      while read -r p; do
        [[ "$p" =~ ^[0-9]+$ ]] || continue
        owner="${proc_user[$p]:-}"
        args="${proc_args[$p]:-}"

        # OpenSSH: "sshd: usuario@pts/0", "sshd: usuario@notty" o "sshd: usuario [priv]"
        if [[ "$args" =~ sshd:[[:space:]]+([^[:space:]@\[]+)([@[:space:]]|$) ]]; then
          usuario="${BASH_REMATCH[1]}"
        # Dropbear: el proceso hijo pertenece al usuario autenticado.
        elif [[ "$args" == *dropbear* ]] && [ -n "$owner" ] &&
             [ "$owner" != "root" ] && [ "$owner" != "sshd" ]; then
          usuario="$owner"
        fi

        # Preferimos un usuario válido; si aún no hay, seguimos buscando.
        if [ -n "$usuario" ] && [ "$usuario" != "root" ] &&
           [ "$usuario" != "unknown" ] && [[ "$usuario" =~ ^[A-Za-z0-9._-]+$ ]]; then
          break
        fi
        usuario=""
      done < <(grep -oE 'pid=[0-9]+' <<< "$line" | cut -d= -f2 | sort -un)

      # Conexión sin usuario autenticado (handshake) o root: no se cuenta.
      [ -n "$usuario" ] || continue

      conn_vista["$peer"]=1
      conteo["$usuario"]=$(( ${conteo[$usuario]:-0} + 1 ))
    done <<< "$sockets"

  else
    # FALLBACK sin "ss": una sesión sshd de usuario (sin [priv]) = 1 conexión.
    while read -r pid owner args; do
      [[ "$pid" =~ ^[0-9]+$ ]] || continue
      usuario=""
      if [[ "$args" =~ sshd:[[:space:]]+([^[:space:]@]+)@ ]]; then
        usuario="${BASH_REMATCH[1]}"
      elif [[ "$args" == *dropbear* ]] && [ -n "$owner" ] &&
           [ "$owner" != "root" ] && [ "$owner" != "sshd" ]; then
        usuario="$owner"
      fi
      if [ -n "$usuario" ] && [ "$usuario" != "root" ] &&
         [[ "$usuario" =~ ^[A-Za-z0-9._-]+$ ]]; then
        conteo["$usuario"]=$(( ${conteo[$usuario]:-0} + 1 ))
      fi
    done <<< "$proc_snapshot"
  fi

  for usuario in "${!conteo[@]}"; do
    printf '%s %s\n' "$usuario" "${conteo[$usuario]}"
  done | sort
}

# ------------------------------------------------------------------------------
# KEEPALIVE DE SSH
# Cuando un celular pierde señal o cambia de red, la conexión TCP puede quedar
# "fantasma" por horas y el panel seguía contándola. Con estos valores, SSH
# cierra esas conexiones muertas en ~30 segundos. Es un archivo aparte
# (drop-in), no modifica sshd_config, y usa reload (no corta sesiones activas).
# ------------------------------------------------------------------------------
aplicar_keepalive_ssh(){
  local dropin_dir="/etc/ssh/sshd_config.d"
  local dropin="$dropin_dir/99-bhttp-keepalive.conf"

  [ -d "$dropin_dir" ] || return 0
  [ -f "$dropin" ] && return 0
  grep -qiE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/' /etc/ssh/sshd_config 2>/dev/null || return 0

  cat > "$dropin" <<'KEOF'
# Detecta clientes caídos y libera su sesión (usado por el panel de usuarios en línea)
ClientAliveInterval 10
ClientAliveCountMax 3
TCPKeepAlive yes
KEOF

  if sshd -t 2>/dev/null; then
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
  else
    rm -f "$dropin"
  fi
}
menu_usuarios(){
  while true; do
    titulo; seccion "GESTIÓN DE USUARIOS Y CREDENCIALES"
    echo -e "  ${NEON_GREEN}[1]${RESET} Crear usuario BHTTP"
    echo -e "  ${NEON_GREEN}[2]${RESET} Detalles de usuario existente"
    echo -e "  ${NEON_GREEN}[3]${RESET} Eliminar usuario por numeración"
    echo -e "  ${NEON_GREEN}[4]${RESET} Editar usuario"
    echo -e "  ${NEON_GREEN}[5]${RESET} Ver usuarios en línea"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p "$(echo -e " ${NEON_ORANGE}◆${RESET} Opción: ")" op
    case "$op" in
      1)
        read -r -p " Usuario: " nu
        read -r -s -p " Contraseña: " np; echo
        read -r -p " Días vigencia (0 = ilimitado): " nd
        if [ "${#np}" -lt 4 ]; then fail "Mínimo 4 caracteres"; else mkdir -p "$CONFIG_DIR"; crear_usuario "$nu" "$np" "$nd" && ok "¡Usuario creado!"; fi
        pausa ;;
      2)
        titulo; seccion "PANEL DE DETALLES DE USUARIOS EXISTENTES"
        if [ -s "$USERS_FILE" ]; then
          local idx=1 linea_usu u_name u_pass u_dias exp_date dias_restantes
          while IFS= read -r linea_usu; do
            u_name="$(extraer_usuario "$linea_usu")"; u_pass="$(echo "$linea_usu"|grep -oP 'Pass: \K[^|]+'|xargs)"; u_dias="$(echo "$linea_usu"|grep -oP 'Dias: \K.*'|xargs)"
            exp_date="$(chage -l "$u_name" 2>/dev/null|grep 'Account expires'|cut -d: -f2|xargs)"
            if [ -n "$exp_date" ] && [ "$exp_date" != "never" ]; then
              local t_exp t_hoy; t_exp="$(date -d "$exp_date" +%s 2>/dev/null || echo 0)"; t_hoy="$(date +%s)"
              if [ "$t_exp" -gt "$t_hoy" ]; then dias_restantes="$(( (t_exp-t_hoy)/86400 )) días"; else dias_restantes="Expirado"; fi
            else dias_restantes="Ilimitado"; fi
            echo -e "  ${NEON_ORANGE}[$idx]${RESET} Usuario: ${NEON_GREEN}$u_name${RESET}"
            echo -e "      Contraseña: ${WHITE}$u_pass${RESET}"
            echo -e "      Vigencia: ${CYAN}$u_dias${RESET}"
            echo -e "      Restantes: ${YELLOW}$dias_restantes${RESET}"
            echo "  ----------------------------------------------------------"
            idx=$((idx+1))
          done < "$USERS_FILE"
        else info "No hay usuarios registrados."; fi
        pausa ;;
      3)
        titulo; seccion "ELIMINAR USUARIO POR NUMERACIÓN"
        if [ -s "$USERS_FILE" ]; then
          local idx=1 linea_usu u_name num_del target_user
          declare -a arr_users=()
          while IFS= read -r linea_usu; do
            u_name="$(extraer_usuario "$linea_usu")"; arr_users[$idx]="$u_name"
            echo -e "  ${NEON_ORANGE}[$idx]${RESET} $u_name"; idx=$((idx+1))
          done < "$USERS_FILE"
          read -r -p " Número a eliminar (0 cancela): " num_del
          if [[ "$num_del" =~ ^[0-9]+$ ]] && [ "$num_del" -gt 0 ] && [ -n "${arr_users[$num_del]:-}" ]; then
            target_user="${arr_users[$num_del]}"; userdel -r "$target_user" 2>/dev/null || true
            sed -i "/^User: $target_user |/d" "$USERS_FILE"; ok "¡Usuario $target_user eliminado!"
          else info "Operación cancelada o número inválido."; fi
        else info "No hay usuarios."; fi
        pausa ;;
      4)
        titulo; seccion "EDITAR USUARIO"
        if [ -s "$USERS_FILE" ]; then
          local idx=1 linea_usu u_name num_edit target_user n_pass n_dias p_actual DIAS_FINAL
          declare -a arr_users=()
          while IFS= read -r linea_usu; do
            u_name="$(extraer_usuario "$linea_usu")"; arr_users[$idx]="$u_name"
            echo -e "  ${NEON_ORANGE}[$idx]${RESET} $u_name"; idx=$((idx+1))
          done < "$USERS_FILE"
          read -r -p " Número a editar: " num_edit
          if [[ "$num_edit" =~ ^[0-9]+$ ]] && [ "$num_edit" -gt 0 ] && [ -n "${arr_users[$num_edit]:-}" ]; then
            target_user="${arr_users[$num_edit]}"
            read -r -s -p " Nueva contraseña (Enter = no cambiar): " n_pass; echo
            read -r -p " Añadir días (Enter = no cambiar): " n_dias
            p_actual="$(grep "^User: $target_user |" "$USERS_FILE"|grep -oP 'Pass: \K[^|]+'|xargs)"
            [ -z "$n_pass" ] && n_pass="$p_actual"
            usermod -p "$(openssl passwd -6 "$n_pass")" "$target_user" 2>/dev/null || true
            if [[ "$n_dias" =~ ^[0-9]+$ ]] && [ "$n_dias" -gt 0 ]; then
              local exp; exp="$(date -d "+${n_dias} days" +%Y-%m-%d 2>/dev/null || true)"
              [ -n "$exp" ] && chage -E "$exp" "$target_user" 2>/dev/null || true
              DIAS_FINAL="${n_dias} días"
            else DIAS_FINAL="Actualizado"; fi
            sed -i "/^User: $target_user |/d" "$USERS_FILE"
            echo "User: $target_user | Pass: $n_pass | Dias: $DIAS_FINAL" >> "$USERS_FILE"
            ok "¡Usuario actualizado!"
          else fail "Número inválido."; fi
        else info "No hay usuarios."; fi
        pausa ;;
      5)
        # ------------------------------------------------------------------
        # MONITOR EN VIVO (panel v2)
        # Foto nueva cada segundo. Solo usuarios registrados en cuentas.txt.
        # ------------------------------------------------------------------
        aplicar_keepalive_ssh >/dev/null 2>&1 || true

        while true; do
          local frame="" total_u=0 online_u=0 total_c=0 i bar fila
          local -a lista_on=() lista_off=()
          local -A conexiones=()

          mapfile -t usuarios_panel < <(obtener_usuarios_panel | sort -u)

          while read -r usuario cantidad; do
            [ -z "$usuario" ] && continue
            [[ "$cantidad" =~ ^[0-9]+$ ]] || continue
            conexiones["$usuario"]="$cantidad"
          done < <(obtener_conexiones_ssh)

          for u_name in "${usuarios_panel[@]}"; do
            [ -z "$u_name" ] && continue
            total_u=$((total_u + 1))
            conns="${conexiones[$u_name]:-0}"
            if [ "$conns" -gt 0 ]; then
              online_u=$((online_u + 1)); total_c=$((total_c + conns))
              bar=""; for ((i=0; i<conns && i<10; i++)); do bar+="▰"; done
              printf -v fila "  ${NEON_GREEN}●${RESET} ${WHITE}%-18.18s${RESET} ${NEON_GREEN}%-10s${RESET} ${NEON_ORANGE}%2d${RESET} ${GRAY}dispositivo(s)${RESET} ${NEON_BLUE}%s${RESET}\n" "$u_name" "EN LÍNEA" "$conns" "$bar"
              lista_on+=("$fila")
            else
              printf -v fila "  ${RED}○${RESET} ${GRAY}%-18.18s %-10s  0 dispositivo(s)${RESET}\n" "$u_name" "OFFLINE"
              lista_off+=("$fila")
            fi
          done

          frame+="$(titulo_rapido)"$'\n'
          frame+="$(seccion "USUARIOS EN LÍNEA • MONITOR EN VIVO")"$'\n'

          if [ "$total_u" -eq 0 ]; then
            frame+="  ${GRAY}No hay usuarios registrados en el panel.${RESET}"$'\n'
          else
            frame+="  ${SKY}👥 Registrados:${RESET} ${WHITE}${BOLD}${total_u}${RESET}   ${NEON_GREEN}🟢 En línea:${RESET} ${WHITE}${BOLD}${online_u}${RESET}   ${RED}🔴 Offline:${RESET} ${WHITE}${BOLD}$((total_u - online_u))${RESET}   ${NEON_ORANGE}📱 Dispositivos:${RESET} ${WHITE}${BOLD}${total_c}${RESET}"$'\n'
            frame+="$(linea)"$'\n'
            frame+="  ${GRAY}USUARIO            ESTADO      CONEXIONES${RESET}"$'\n'
            frame+="$(linea)"$'\n'
            for fila in "${lista_on[@]}" "${lista_off[@]}"; do
              frame+="$fila"
            done
            frame+="$(linea)"$'\n'
          fi

          frame+="  ${GRAY}🔄 Se actualiza cada segundo • $(date '+%H:%M:%S')${RESET}"$'\n'
          frame+="  ${GRAY}Cada dispositivo = 1 conexión. Al desconectarse baja solo.${RESET}"$'\n'
          frame+="  ${GRAY}Presiona Enter para regresar al menú.${RESET}"$'\n'

          clear_screen
          printf '%b' "$frame"

          if IFS= read -r -t 1; then
            break
          fi
        done
        ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

menu_activar_puertos(){
  while true; do
    titulo; seccion "ACTIVADOR Y APERTURA MANUAL DE PUERTOS (FIREWALL)"
    echo -e "  ${WHITE}Abre cualquier puerto TCP/UDP adicional.${RESET}"; linea
    read -r -p " Puerto (0 para regresar): " p
    [ "$p" = "0" ] && return
    if [[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -gt 0 ] && [ "$p" -le 65535 ]; then
      abrir_puerto_sistema "$p"
    else fail "Puerto inválido."; fi
    pausa
  done
}

menu_optimizar_vps(){
  while true; do
    titulo; seccion "CONFIGURACIÓN DE BADVPN GATEWAY (UDP)"
    local bv_txt
    if [ "$BADVPN_STATE" = "ON" ]; then bv_txt="${NEON_GREEN}ACTIVO (ON) - Puerto $BADVPN_PORT${RESET}"; else bv_txt="${RED}INACTIVO (OFF)${RESET}"; fi
    echo -e "  ${WHITE}Estado:${RESET} [ $bv_txt ]"; linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Activar BadVPN en 7300"
    echo -e "  ${NEON_GREEN}[2]${RESET} Activar BadVPN en 7200"
    echo -e "  ${NEON_GREEN}[3]${RESET} Apagar BadVPN"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p " Opción: " opt
    case "$opt" in
      1|2)
        [ "$opt" = "1" ] && BADVPN_PORT=7300 || BADVPN_PORT=7200
        instalar_badvpn
        systemctl enable "$BADVPN_SERVICE" >/dev/null 2>&1 || true
        systemctl restart "$BADVPN_SERVICE" >/dev/null 2>&1 || true
        abrir_puerto_sistema "$BADVPN_PORT"; BADVPN_STATE="ON"; guardar_config
        ok "BadVPN activado en $BADVPN_PORT."; pausa ;;
      3)
        systemctl stop "$BADVPN_SERVICE" 2>/dev/null || true
        systemctl disable "$BADVPN_SERVICE" 2>/dev/null || true
        BADVPN_STATE="OFF"; guardar_config; ok "BadVPN apagado."; pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

menu_bhttp_bbr(){
  local backup="$CONFIG_DIR/bhttp-performance.backup"
  local state_file="$CONFIG_DIR/bhttp-performance.state"

  _perf_get(){ sysctl -n "$1" 2>/dev/null || true; }
  _perf_set(){ sysctl -w "$1=$2" >/dev/null 2>&1; }
  _perf_has(){ sysctl -n "$1" >/dev/null 2>&1; }

  _perf_save(){
    mkdir -p "$CONFIG_DIR"
    cat > "$backup" <<EOF
net.ipv4.tcp_congestion_control=$(_perf_get net.ipv4.tcp_congestion_control)
net.core.default_qdisc=$(_perf_get net.core.default_qdisc)
net.core.rmem_max=$(_perf_get net.core.rmem_max)
net.core.wmem_max=$(_perf_get net.core.wmem_max)
net.ipv4.tcp_rmem=$(_perf_get net.ipv4.tcp_rmem)
net.ipv4.tcp_wmem=$(_perf_get net.ipv4.tcp_wmem)
net.ipv4.tcp_fastopen=$(_perf_get net.ipv4.tcp_fastopen)
net.ipv4.tcp_slow_start_after_idle=$(_perf_get net.ipv4.tcp_slow_start_after_idle)
net.core.somaxconn=$(_perf_get net.core.somaxconn)
net.ipv4.tcp_max_syn_backlog=$(_perf_get net.ipv4.tcp_max_syn_backlog)
EOF
  }

  _perf_apply_sysctl(){
    local profile="$1" cc qdisc
    if [ "$profile" = "speed" ]; then
      cc="bbr"; qdisc="fq"
    else
      cc="cubic"; qdisc="fq_codel"
    fi

    if ! grep -qw "$cc" /proc/sys/net/ipv4/tcp_allowed_congestion_control 2>/dev/null &&
       ! grep -qw "$cc" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
      if [ "$cc" = "bbr" ] && modprobe tcp_bbr 2>/dev/null; then :; fi
    fi

    if [ "$profile" = "speed" ] && ! grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
      return 2
    fi

    _perf_set net.core.default_qdisc "$qdisc" || true
    _perf_set net.ipv4.tcp_congestion_control "$cc" || true
    _perf_set net.core.rmem_max 67108864 || true
    _perf_set net.core.wmem_max 67108864 || true
    _perf_set net.ipv4.tcp_rmem "4096 131072 67108864" || true
    _perf_set net.ipv4.tcp_wmem "4096 131072 67108864" || true
    _perf_set net.core.somaxconn 8192 || true
    _perf_set net.ipv4.tcp_max_syn_backlog 8192 || true
    _perf_set net.ipv4.tcp_fastopen 3 || true
    _perf_set net.ipv4.tcp_slow_start_after_idle 0 || true

    # No tocar valores obsoletos o peligrosos; solo persistimos parámetros
    # que el kernel actual acepte.
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/99-bhttp-performance.conf" <<EOF
# BHTTP Performance Engine - generado por intalar.sh
net.core.default_qdisc=$qdisc
net.ipv4.tcp_congestion_control=$cc
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 131072 67108864
net.ipv4.tcp_wmem=4096 131072 67108864
net.core.somaxconn=8192
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
EOF
    mkdir -p /etc/sysctl.d
    cp "$CONFIG_DIR/99-bhttp-performance.conf" /etc/sysctl.d/99-bhttp-performance.conf 2>/dev/null || true
    sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-bhttp-performance.conf >/dev/null 2>&1 || true
    _perf_set net.ipv4.tcp_congestion_control "$cc" || true
    _perf_set net.core.default_qdisc "$qdisc" || true
  }

  _perf_restore(){
    if [ -s "$backup" ]; then
      while IFS='=' read -r key value; do
        [ -n "$key" ] || continue
        _perf_set "$key" "$value" || true
      done < "$backup"
    fi
    rm -f /etc/sysctl.d/99-bhttp-performance.conf "$CONFIG_DIR/99-bhttp-performance.conf" "$state_file"
    sysctl --system >/dev/null 2>&1 || true
    BBR_STATUS="OFF"
    guardar_config
  }

  _perf_state(){
    case "$(cat "$state_file" 2>/dev/null)" in
      speed) echo "${NEON_GREEN}VELOCIDAD PURA 🟢${RESET}" ;;
      stable) echo "${NEON_GREEN}ESTABILIDAD 🟢${RESET}" ;;
      *) echo "${RED}APAGADO 🔴${RESET}" ;;
    esac
  }

  while true; do
    titulo; seccion "BHTTP PERFORMANCE ENGINE"
    echo -e "  ${WHITE}Estado:${RESET} $(_perf_state)"; linea
    echo -e "  ${NEON_GREEN}[1]${RESET} ESTABILIDAD"
    echo -e "      ${GRAY}CUBIC + FQ_Codel + buffers equilibrados${RESET}"
    echo -e "  ${NEON_GREEN}[2]${RESET} VELOCIDAD PURA"
    echo -e "      ${GRAY}BBR + FQ + TCP Fast Open + tuning de colas${RESET}"
    echo -e "  ${RED}[3]${RESET} APAGAR OPTIMIZACIÓN"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p " Opción: " op
    case "$op" in
      1|2)
        if [ ! -s "$backup" ]; then _perf_save; fi
        if [ "$op" = "2" ]; then
          if _perf_apply_sysctl speed; then
            printf '%s\n' speed > "$state_file"
            BBR_STATUS="VELOCIDAD PURA (ON)"
            guardar_config
            systemctl restart "$SERVICE" >/dev/null 2>&1 || true
            ok "VELOCIDAD PURA activada: BBR + FQ y tuning TCP aplicado."
          else
            fail "Este kernel no tiene BBR disponible; no se aplicó el perfil de velocidad."
          fi
        else
          _perf_apply_sysctl stable
          printf '%s\n' stable > "$state_file"
          BBR_STATUS="ESTABILIDAD (ON)"
          guardar_config
          systemctl restart "$SERVICE" >/dev/null 2>&1 || true
          ok "ESTABILIDAD activada: CUBIC + FQ_Codel y tuning equilibrado."
        fi
        pausa ;;
      3)
        _perf_restore
        systemctl restart "$SERVICE" >/dev/null 2>&1 || true
        ok "Optimización apagada y valores anteriores restaurados."
        pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

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
  if ! systemctl is-active --quiet cron 2>/dev/null && ! systemctl is-active --quiet crond 2>/dev/null && ! pgrep -x cron >/dev/null 2>&1 && ! pgrep -x crond >/dev/null 2>&1; then
    info "Instalando/iniciando el servicio cron..."
    apt-get install -y cron >/dev/null 2>&1 || true
    systemctl enable cron >/dev/null 2>&1 || systemctl enable crond >/dev/null 2>&1 || true
    systemctl start cron >/dev/null 2>&1 || systemctl start crond >/dev/null 2>&1 || true
  fi
  systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null || pgrep -x cron >/dev/null 2>&1 || pgrep -x crond >/dev/null 2>&1
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
  # Protección: debe ser el script COMPLETO (no un parche ni otro archivo).
  if grep -q 'BLOQUE_NUEVO''_EOF' "$tmp" || \
     ! grep -q 'HAZAEL MORENO MULTI SCRIPT' "$tmp" || \
     ! grep -q 'PYEOF' "$tmp" || \
     ! grep -qE '^instalar_servidor\(\)' "$tmp" || \
     ! grep -qE '^check_root$' "$tmp"; then
    fail "El archivo de GitHub NO es el script completo (parece un parche u otro archivo)."
    info "Tu panel actual no fue modificado."
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

fila_menu(){
  # $1 num izq, $2 texto izq, $3 num der, $4 texto der, $5 color (opcional)
  local c="${5:-$NEON_GREEN}" t="$2" pad
  pad=$((32-${#t})); [ "$pad" -lt 1 ] && pad=1
  printf "  ${c}[%2s]${RESET} %s%*s ${c}[%2s]${RESET} %s\n" "$1" "$t" "$pad" "" "$3" "$4"
}

# ------------------------------------------------------------------------------
# MENÚ PRINCIPAL PROFESIONAL
# ------------------------------------------------------------------------------
menu_principal(){
  configurar_atajo_adm
  # Alinea bien las columnas con letras acentuadas (ó, á).
  if locale -a 2>/dev/null | grep -qiE '^c\.utf-?8$'; then export LC_ALL=C.UTF-8; fi
  while true; do
    refrescar_estados
    titulo
    panel_estado
    local estado_bhttp
    estado_bhttp="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"

    echo -e "  ${MAGENTA}${BOLD}MENÚ PRINCIPAL${RESET}  ${GRAY}• comandos: ${NEON_PINK}adm${GRAY} / ${NEON_PINK}admin${RESET}"
    linea
    fila_menu 1 "Instalar / Reinstalar BHTTP" 2 "Gestionar usuarios"
    fila_menu 3 "Encender / Apagar BHTTP" 4 "Abrir puertos manuales"
    fila_menu 5 "BadVPN Gateway" 6 "Actualizar desde GitHub"
    fila_menu 7 "Liberar memoria RAM" 8 "Auto iniciar script"
    fila_menu 9 "Optimización automática" 10 "BHTTP BBR (red)"
    fila_menu 11 "Destrucción total" 0 "Salir" "$RED"
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

check_root
cargar_config
menu_principal
