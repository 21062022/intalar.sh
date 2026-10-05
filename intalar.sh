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
  # MONITOR DE CONEXIONES SSH/BHTTP EN TIEMPO REAL
  # --------------------------------------------------------------------------
  # IMPORTANTE:
  # - Cada conexión TCP ESTABLISHED cuenta una sola vez.
  # - Se identifica por PID + socket, evitando acumulaciones.
  # - No se usa la tabla completa de procesos como contador, porque un sshd
  #   viejo/huérfano puede seguir visible aunque ya no tenga conexión activa.
  # - La salida es una fotografía nueva en cada actualización.
  # --------------------------------------------------------------------------

  declare -A conteo=()
  declare -A vistos=()
  declare -A proc_args=()
  declare -A proc_user=()

  local ssh_port="${SSHPORT:-22}"
  local proc_snapshot="" sockets="" line pid owner args usuario clave

  # Snapshot de procesos únicamente para saber qué usuario pertenece al PID.
  proc_snapshot="$(ps -eo pid=,user=,args= 2>/dev/null || true)"
  while read -r pid owner args; do
    [ -n "$pid" ] || continue
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    proc_user["$pid"]="$owner"
    proc_args["$pid"]="$args"
  done <<< "$proc_snapshot"

  # ÚNICA FUENTE DEL CONTADOR: sockets TCP actualmente ESTABLISHED.
  # El fallback conserva compatibilidad con versiones distintas de ss,
  # pero nunca vuelve a contar procesos por separado.
  if command -v ss >/dev/null 2>&1; then
    sockets="$(ss -Hntp state established "sport = :$ssh_port" 2>/dev/null || true)"
    if [ -z "$sockets" ]; then
      sockets="$(ss -Hntp state established 2>/dev/null | awk -v p=":$ssh_port" '$4 ~ p {print}' || true)"
    fi
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue

    # Un socket ESTABLISHED debe tener un PID. Si ss no lo entrega, no se
    # inventa una conexión: así evitamos falsos positivos/acumulaciones.
    while read -r pid; do
      [ -n "$pid" ] || continue
      [[ "$pid" =~ ^[0-9]+$ ]] || continue

      # Un PID + socket solo puede sumar una conexión una vez.
      # El remote endpoint también forma parte de la clave para soportar
      # varios dispositivos con las mismas credenciales.
      clave="${pid}|${line%% users:*}"
      [ -n "${vistos[$clave]:-}" ] && continue
      vistos["$clave"]=1

      owner="${proc_user[$pid]:-}"
      args="${proc_args[$pid]:-}"
      usuario=""

      # OpenSSH: sshd: usuario@notty / sshd: usuario@pts/0
      if [[ "$args" =~ sshd:[[:space:]]+([^[:space:]@]+)@ ]]; then
        usuario="${BASH_REMATCH[1]}"
      # Dropbear: intenta extraer usuario@...
      elif [[ "$args" == *dropbear* ]]; then
        if [[ "$args" =~ ([A-Za-z0-9._-]+)@ ]]; then
          usuario="${BASH_REMATCH[1]}"
        elif [ -n "$owner" ] && [ "$owner" != "root" ] && [ "$owner" != "sshd" ]; then
          usuario="$owner"
        fi
      fi

      # Solo cuentas reales y no root.
      if [ -n "$usuario" ] && [ "$usuario" != "root" ] &&
         [[ "$usuario" =~ ^[A-Za-z0-9._-]+$ ]]; then
        conteo["$usuario"]=$(( ${conteo[$usuario]:-0} + 1 ))
      fi
    done < <(printf '%s\n' "$line" | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u)
  done <<< "$sockets"

  for usuario in "${!conteo[@]}"; do
    printf '%s %s\n' "$usuario" "${conteo[$usuario]}"
  done | sort
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
        # MONITOR EN VIVO
        # Actualiza cada 2 segundos. Solo considera usuarios registrados
        # en cuentas.txt y excluye root explícitamente.
        # ------------------------------------------------------------------
        while true; do
          clear_screen
          titulo_rapido
          seccion "ESTADO DE USUARIOS CONECTADOS EN VIVO"

          mapfile -t usuarios_panel < <(obtener_usuarios_panel | sort -u)

          if [ "${#usuarios_panel[@]}" -eq 0 ]; then
            info "No hay usuarios registrados en el panel."
          else
            declare -A conexiones=()
            local total_online=0 total_devices=0

            # Fotografía completamente nueva en cada ciclo.
            # Si una conexión desapareció, desaparece del mapa inmediatamente.
            while read -r usuario cantidad; do
              [ -z "$usuario" ] && continue
              [[ "$cantidad" =~ ^[0-9]+$ ]] || continue
              conexiones["$usuario"]="$cantidad"
              total_online=$((total_online + 1))
              total_devices=$((total_devices + cantidad))
            done < <(obtener_conexiones_ssh)

            echo -e "  ${NEON_BLUE}╭────────────────────────────────────────────────────────────╮${RESET}"
            echo -e "  ${NEON_BLUE}│${RESET} ${WHITE}${BOLD}📡 RESUMEN EN VIVO${RESET}  ${GRAY}Usuarios únicos:${RESET} ${NEON_GREEN}${total_online}${RESET}  ${GRAY}Dispositivos:${RESET} ${NEON_ORANGE}${total_devices}${RESET} ${NEON_BLUE}│${RESET}"
            echo -e "  ${NEON_BLUE}╰────────────────────────────────────────────────────────────╯${RESET}"
            echo

            for u_name in "${usuarios_panel[@]}"; do
              conns="${conexiones[$u_name]:-0}"

              if [ "$conns" -gt 0 ]; then
                if [ "$conns" -eq 1 ]; then
                  txt="1 dispositivo conectado"
                else
                  txt="${conns} dispositivos conectados"
                fi
                echo -e "  ${NEON_GREEN}●${RESET} ${WHITE}${BOLD}${u_name}${RESET}  ${NEON_GREEN}ONLINE${RESET}  ${NEON_ORANGE}${txt}${RESET}"
              else
                echo -e "  ${GRAY}●${RESET} ${GRAY}${u_name}${RESET}  ${RED}OFFLINE${RESET}  ${GRAY}0 dispositivos conectados${RESET}"
              fi
            done
          fi

          echo
          echo -e "  ${GRAY}Actualización automática cada 1 segundo.
  DETECCIÓN: SSH directo + sesiones SSH transportadas por BHTTP.${RESET}"
          echo -e "  ${GRAY}Una desconexión se reflejará normalmente en 1–2 segundos.${RESET}"
          echo -e "  ${GRAY}Presiona Enter para regresar al menú.${RESET}"

          # Espera 1 segundo. Enter sale; si no, vuelve a medir.
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
  while true; do
    titulo; seccion "BHTTP BBR • ACELERACIÓN TCP"
    echo -e "  ${WHITE}Estado:${RESET} ${NEON_ORANGE}$BBR_STATUS${RESET}"; linea
    echo -e "  ${NEON_GREEN}[1]${RESET} BBR + FQ"
    echo -e "  ${NEON_GREEN}[2]${RESET} BBR + FQ_Codel"
    echo -e "  ${NEON_GREEN}[3]${RESET} Apagar BBR"
    echo -e "  ${RED}[0]${RESET} Regresar"; linea
    read -r -p " Opción: " op
    case "$op" in
      1)
        sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 || true
        sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
        sysctl -w net.core.rmem_max=67108864 >/dev/null 2>&1 || true
        sysctl -w net.core.wmem_max=67108864 >/dev/null 2>&1 || true
        grep -q '^net.ipv4.tcp_congestion_control=bbr$' /etc/sysctl.conf 2>/dev/null || echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
        grep -q '^net.core.default_qdisc=fq$' /etc/sysctl.conf 2>/dev/null || echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1 || true; BBR_STATUS="BBR + FQ (ON)"; guardar_config; ok "BBR activado."; pausa ;;
      2)
        sysctl -w net.core.default_qdisc=fq_codel >/dev/null 2>&1 || true
        sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
        grep -q '^net.ipv4.tcp_congestion_control=bbr$' /etc/sysctl.conf 2>/dev/null || echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
        grep -q '^net.core.default_qdisc=fq_codel$' /etc/sysctl.conf 2>/dev/null || echo 'net.core.default_qdisc=fq_codel' >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1 || true; BBR_STATUS="BBR + FQ_Codel (ON)"; guardar_config; ok "BBR activado."; pausa ;;
      3)
        sed -i '/^net.ipv4.tcp_congestion_control=/d;/^net.core.default_qdisc=/d' /etc/sysctl.conf 2>/dev/null || true
        sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1 || true
        sysctl -w net.core.default_qdisc=pfifo_fast >/dev/null 2>&1 || true
        BBR_STATUS="OFF"; guardar_config; ok "BBR apagado."; pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

menu_autostart(){
  while true; do
    titulo; seccion "AUTO INICIAR SCRIPT AL ABRIR TERMINAL"
    echo -e "  ${WHITE}Estado:${RESET} ${NEON_ORANGE}$AUTOSTART_STATUS${RESET}"; linea
    echo -e "  [1] Encender"; echo -e "  [2] Apagar"; echo -e "  [0] Regresar"; linea
    read -r -p " Opción: " op
    case "$op" in
      1)
        AUTOSTART_STATUS="ON"; guardar_config
        for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
          if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
            touch "$rc" 2>/dev/null || true
            sed -i '/# HAZAEL_AUTOSTART/d' "$rc" 2>/dev/null || true
            echo "[[ \$- == *i* ]] && [ -z \"\$TMUX\" ] && sudo bash $SCRIPT_PATH # HAZAEL_AUTOSTART" >> "$rc"
          fi
        done
        ok "Auto inicio activado."; pausa ;;
      2)
        AUTOSTART_STATUS="OFF"; guardar_config
        for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do sed -i '/# HAZAEL_AUTOSTART/d' "$rc" 2>/dev/null || true; done
        ok "Auto inicio desactivado."; pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

ejecutar_optimizacion_manual(){
  sync
  echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
  swapoff -a 2>/dev/null || true
  swapon -a 2>/dev/null || true
}

menu_optimizacion_automatica(){
  while true; do
    titulo; seccion "OPTIMIZACIÓN AUTOMÁTICA CADA 6 HORAS"
    echo -e "  ${WHITE}Estado:${RESET} ${NEON_ORANGE}$CRON_STATUS${RESET}"; linea
    echo -e "  [1] Activar"; echo -e "  [2] Desactivar"; echo -e "  [3] Ejecutar ahora"; echo -e "  [0] Regresar"; linea
    read -r -p " Opción: " op
    case "$op" in
      1)
        CRON_STATUS="ON"; guardar_config
        (crontab -l 2>/dev/null | grep -v 'HAZAEL_DROP_CACHES'; echo '0 */6 * * * sync && echo 3 > /proc/sys/vm/drop_caches # HAZAEL_DROP_CACHES') | crontab -
        ok "Optimización automática activada."; pausa ;;
      2)
        CRON_STATUS="OFF"; guardar_config
        (crontab -l 2>/dev/null | grep -v 'HAZAEL_DROP_CACHES') | crontab -
        ok "Optimización automática desactivada."; pausa ;;
      3) ejecutar_optimizacion_manual; ok "Sistema optimizado."; pausa ;;
      0) return ;;
      *) fail "Opción inválida."; pausa ;;
    esac
  done
}

actualizar_script(){
  titulo; seccion "ACTUALIZADOR AUTOMÁTICO DEL SCRIPT"
  info "Descargando y verificando la nueva versión..."
  command -v curl >/dev/null 2>&1 || { fail "curl no está instalado."; pausa; return 1; }
  local tmp="/tmp/intalar_update.sh"
  if ! curl -fsSL --max-time 30 "$GITHUB_URL" -o "$tmp"; then
    fail "No se pudo descargar el archivo desde GitHub."; pausa; return 1
  fi
  if ! head -n 1 "$tmp" | grep -qE '^#!/.*(bash|sh)'; then
    fail "El archivo descargado no parece ser un script válido."; rm -f "$tmp"; pausa; return 1
  fi
  if ! bash -n "$tmp"; then
    fail "La versión descargada tiene errores de sintaxis. NO se reemplazó el script."
    rm -f "$tmp"; pausa; return 1
  fi
  cp -a "$SCRIPT_PATH" "${SCRIPT_PATH}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
  install -m 0755 "$tmp" "$SCRIPT_PATH"
  rm -f "$tmp"
  ok "Script actualizado y verificado correctamente."
  info "Reiniciando el panel..."
  sleep 1
  exec bash "$SCRIPT_PATH"
}

destruir_script_total(){
  titulo
  echo -e "${RED}${BOLD}ADVERTENCIA: DESTRUCCIÓN TOTAL${RESET}"
  echo "Esto detendrá servicios y eliminará archivos del script."
  read -r -p "¿Continuar? (s/n): " c
  [[ "$c" =~ ^[sS]$ ]] || { info "Cancelado."; pausa; return; }
  systemctl stop "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null || true
  systemctl disable "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null || true
  rm -f "$UNIT" "$BADVPN_UNIT" "$ADM_BIN" "$ADMIN_BIN" "$SCRIPT_PATH"
  rm -rf "$DESTDIR" "$CONFIG_DIR"
  systemctl daemon-reload
  for rc in /root/.bashrc /root/.zshrc /etc/bash.bashrc; do
    sed -i '/# HAZAEL_AUTOSTART/d;/alias adm=/d;/alias admin=/d' "$rc" 2>/dev/null || true
  done
  ok "Desinstalación completada."; exit 0
}

menu_principal(){
  configurar_atajo_adm
  while true; do
    titulo
    local estado
    estado="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
    [ "$estado" = "active" ] && estado_color="${NEON_GREEN}ACTIVO 🟢${RESET}" || estado_color="${RED}INACTIVO 🔴${RESET}"
    echo -e "  ${WHITE}BHTTP Servidor:${RESET} $estado_color | Puerto: ${NEON_GREEN}${PUERTO}${RESET}"
    echo -e "  ${WHITE}BadVPN Gateway:${RESET} ${BADVPN_STATE} | Puerto: ${BADVPN_PORT}"
    echo -e "  ${WHITE}Comandos:${RESET} ${NEON_PINK}adm${RESET} / ${NEON_PINK}admin${RESET}"
    linea
    echo -e "  ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar BHTTP"
    echo -e "  ${NEON_GREEN}[2]${RESET} Gestionar Usuarios"
    echo -e "  ${NEON_GREEN}[3]${RESET} Encender / Apagar BHTTP"
    echo -e "  ${NEON_GREEN}[4]${RESET} Abrir Puertos Manuales"
    echo -e "  ${NEON_GREEN}[5]${RESET} BadVPN Gateway"
    echo -e "  ${NEON_GREEN}[6]${RESET} Actualizar Script desde GitHub"
    echo -e "  ${NEON_GREEN}[7]${RESET} Liberar Memoria RAM"
    echo -e "  ${NEON_GREEN}[8]${RESET} Auto Iniciar Script"
    echo -e "  ${NEON_GREEN}[9]${RESET} Optimización Automática"
    echo -e "  ${NEON_GREEN}[10]${RESET} BHTTP BBR"
    echo -e "  ${RED}[11]${RESET} Destrucción Total"
    echo -e "  ${RED}[0]${RESET} Salir"; linea
    read -r -p " Opción: " opc
    case "$opc" in
      1) instalar_servidor ;;
      2) menu_usuarios ;;
      3)
        titulo; seccion "CONTROL DE ESTADO BHTTP"
        if [ "$estado" = "active" ]; then
          systemctl stop "$SERVICE" 2>/dev/null || true; systemctl disable "$SERVICE" 2>/dev/null || true; ok "BHTTP detenido."
        else
          systemctl enable "$SERVICE" 2>/dev/null || true; systemctl start "$SERVICE" 2>/dev/null || true; ok "BHTTP iniciado."
        fi
        pausa ;;
      4) menu_activar_puertos ;;
      5) menu_optimizar_vps ;;
      6) actualizar_script ;;
      7) ejecutar_optimizacion_manual; ok "Memoria optimizada."; pausa ;;
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
