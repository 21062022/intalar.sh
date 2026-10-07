#!/bin/bash
# ════════════════════════════════════════════════════════════
# REPARAR-SSH: arregla SSH + proxy WebSocket del HAZEL MORENO MULTI SCRIPT
# Uso:  sudo bash reparar-ssh.sh
# ════════════════════════════════════════════════════════════

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
info() { echo -e "${CYAN}==>${NC} $1"; }

[[ $EUID -ne 0 ]] && { err "Ejecuta como root (sudo bash reparar-ssh.sh)"; exit 1; }

WS_DIR="/usr/local/lib/ws-proxy"
WS_SCRIPT="$WS_DIR/ws-proxy.py"
WS_SERVICE="/etc/systemd/system/ws-proxy.service"
SSHD_CONF="/etc/ssh/sshd_config"

# ─────────────────────────────────────────────
# 1. OpenSSH instalado y corriendo
# ─────────────────────────────────────────────
info "1/6 Verificando OpenSSH..."
if [ ! -x /usr/sbin/sshd ]; then
    warn "openssh-server no estaba instalado, instalando..."
    apt-get update -qq && apt-get install -y -qq openssh-server
fi

if systemctl cat ssh >/dev/null 2>&1; then SSH_SVC="ssh"; else SSH_SVC="sshd"; fi
systemctl enable "$SSH_SVC" >/dev/null 2>&1
systemctl start "$SSH_SVC" 2>/dev/null
systemctl is-active --quiet "$SSH_SVC" && ok "Servicio $SSH_SVC activo" || err "El servicio $SSH_SVC no arranca (journalctl -u $SSH_SVC -n 30)"

# ─────────────────────────────────────────────
# 2. Configuración de sshd (causa más común: PasswordAuthentication no)
# ─────────────────────────────────────────────
info "2/6 Ajustando sshd_config (login por contraseña + túneles)..."
BACKUP="${SSHD_CONF}.bak.$(date +%s)"
cp -a "$SSHD_CONF" "$BACKUP"
mkdir -p /run/sshd

OPTS="PasswordAuthentication yes
AllowTcpForwarding yes
UseDNS no
ClientAliveInterval 30
ClientAliveCountMax 6"

DROPIN=""
if grep -qiE '^\s*Include\s+/etc/ssh/sshd_config\.d/' "$SSHD_CONF"; then
    # sshd usa "el primer valor gana": 00- se lee antes que 50-cloud-init.conf
    mkdir -p /etc/ssh/sshd_config.d
    DROPIN="/etc/ssh/sshd_config.d/00-tunel.conf"
    echo "$OPTS" > "$DROPIN"
else
    # Sistema viejo sin Include: comentar duplicados y poner las opciones al INICIO
    for key in PasswordAuthentication AllowTcpForwarding UseDNS ClientAliveInterval ClientAliveCountMax; do
        sed -i -E "s/^\s*($key\b)/#\1/I" "$SSHD_CONF"
    done
    TMP=$(mktemp)
    { echo "# --- tunel ---"; echo "$OPTS"; echo "# -------------"; cat "$SSHD_CONF"; } > "$TMP"
    cat "$TMP" > "$SSHD_CONF"; rm -f "$TMP"
fi

if /usr/sbin/sshd -t 2>/tmp/sshd_test.err; then
    ok "Configuración de sshd válida"
else
    err "Configuración inválida, restaurando respaldo:"; cat /tmp/sshd_test.err
    cp -a "$BACKUP" "$SSHD_CONF"; [ -n "$DROPIN" ] && rm -f "$DROPIN"
fi

# /bin/false debe figurar en /etc/shells (algunos módulos PAM lo exigen)
grep -qx '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells

systemctl restart "$SSH_SVC" && ok "sshd reiniciado"

echo -e "${CYAN}Valores efectivos de sshd:${NC}"
/usr/sbin/sshd -T 2>/dev/null | grep -Ei '^(port|passwordauthentication|allowtcpforwarding|permitrootlogin|usepam) '

# ─────────────────────────────────────────────
# 3. Reescribir el proxy WebSocket -> SSH (versión corregida)
# ─────────────────────────────────────────────
info "3/6 Reescribiendo el proxy WebSocket..."
mkdir -p "$WS_DIR"
cat > "$WS_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
# Proxy HTTP/"WebSocket" -> SSH para HTTP Custom y similares.
# Tras la respuesta 101/200 el tráfico va SIN frames (túnel crudo), que es
# lo que esperan los clientes tipo HTTP Custom / injectors.
import os, socket, select, threading, logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger("ws-proxy")

LISTEN_PORT = int(os.environ.get('WS_PORT', 80))
SSH_HOST    = os.environ.get('SSH_HOST', '127.0.0.1')
SSH_PORT    = int(os.environ.get('SSH_PORT', 22))
BUFLEN      = 65536

def leer_headers(sock):
    data = b''
    while b'\r\n\r\n' not in data:
        chunk = sock.recv(4096)
        if not chunk or len(data) > 16384:
            return None, b''
        data += chunk
    head, _, rest = data.partition(b'\r\n\r\n')
    return head, rest

def parsear(head):
    lines = head.decode('latin-1').split('\r\n')
    headers = {}
    for l in lines[1:]:
        if ':' in l:
            k, v = l.split(':', 1)
            headers[k.strip().lower()] = v.strip()
    return lines[0], headers

def tunel(a, b):
    socks = [a, b]
    try:
        while True:
            r, _, _ = select.select(socks, [], [], 3600)
            if not r:
                continue
            for s in r:
                data = s.recv(BUFLEN)
                if not data:
                    return
                (b if s is a else a).sendall(data)   # sendall: no pierde bytes
    except OSError:
        pass

def manejar(client, addr):
    ssh = None
    try:
        client.settimeout(30)
        head, rest = leer_headers(client)
        if head is None:
            return
        linea, headers = parsear(head)
        log.info("%s -> %s", addr[0], linea[:80])

        try:
            ssh = socket.create_connection((SSH_HOST, SSH_PORT), timeout=10)
        except OSError as e:
            log.error("No conecta a SSH %s:%s (%s)", SSH_HOST, SSH_PORT, e)
            client.sendall(b"HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\n\r\n")
            return

        if 'websocket' in headers.get('upgrade', '').lower():
            resp = (b"HTTP/1.1 101 Switching Protocols\r\n"
                    b"Upgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        else:
            # IMPORTANTE: sin cuerpo ni Content-Length, o se mezcla con el banner de SSH
            resp = b"HTTP/1.1 200 Connection established\r\n\r\n"
        client.sendall(resp)

        ssh.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client.settimeout(None)
        ssh.settimeout(None)
        if rest:
            ssh.sendall(rest)
        tunel(client, ssh)
    except Exception as e:
        log.error("Error con %s: %s", addr, e)
    finally:
        for s in (client, ssh):
            try:
                if s: s.close()
            except OSError:
                pass

def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(('0.0.0.0', LISTEN_PORT))
    srv.listen(200)
    log.info("Escuchando en %s -> SSH %s:%s", LISTEN_PORT, SSH_HOST, SSH_PORT)
    while True:
        c, a = srv.accept()
        threading.Thread(target=manejar, args=(c, a), daemon=True).start()

if __name__ == "__main__":
    main()
PYTHON_EOF
chmod +x "$WS_SCRIPT"
python3 -m py_compile "$WS_SCRIPT" && ok "Proxy escrito y sin errores de sintaxis" || err "Error de sintaxis en el proxy"

if [ ! -f "$WS_SERVICE" ]; then
    cat > "$WS_SERVICE" << EOF
[Unit]
Description=WebSocket to SSH Proxy
After=network.target

[Service]
Type=simple
Environment=WS_PORT=80
Environment=SSH_HOST=127.0.0.1
Environment=SSH_PORT=22
ExecStart=/usr/bin/python3 $WS_SCRIPT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    ok "Servicio ws-proxy creado (puerto 80 -> SSH 22)"
fi
systemctl daemon-reload
systemctl enable ws-proxy >/dev/null 2>&1
systemctl restart ws-proxy
sleep 2
systemctl is-active --quiet ws-proxy && ok "ws-proxy activo" || { err "ws-proxy no arrancó:"; journalctl -u ws-proxy -n 15 --no-pager; }

# ─────────────────────────────────────────────
# 4. Firewall local
# ─────────────────────────────────────────────
info "4/6 Revisando firewall local..."
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    for p in 22 80 8080; do ufw allow "$p"/tcp >/dev/null; done
    ok "ufw: puertos 22, 80 y 8080 permitidos"
else
    ok "ufw no está activo"
fi
warn "Si tu VPS es Oracle/AWS/Google/Azure, abre 22, 80 y 8080 TCP también en el panel del proveedor (Security Group / VCN)."

# ─────────────────────────────────────────────
# 5. Estado de los usuarios
# ─────────────────────────────────────────────
info "5/6 Usuarios SSH (UID >= 1000):"
awk -F: '$3>=1000 && $3<65534 {print $1" "$7}' /etc/passwd | while read -r u sh; do
    est=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
    exp=$(chage -l "$u" 2>/dev/null | awk -F': ' '/Account expires/{print $2}')
    pwexp=$(chage -l "$u" 2>/dev/null | awk -F': ' '/Password expires/{print $2}')
    echo "  $u  shell=$sh  pass=$est (P=ok, L=bloqueado)  cuenta expira=$exp  clave expira=$pwexp"
done

# ─────────────────────────────────────────────
# 6. Pruebas locales
# ─────────────────────────────────────────────
info "6/6 Puertos escuchando:"
ss -tlnp 2>/dev/null | awk 'NR==1 || /:(22|80|8080|7300) /'

probar() {   # $1=puerto $2=payload
    exec 3<>/dev/tcp/127.0.0.1/"$1" 2>/dev/null || { echo "  no conecta"; return; }
    printf "$2" >&3
    timeout 3 head -c 300 <&3 | tr -d '\r' | head -5 | sed 's/^/  /'
    exec 3<&- 3>&-
}
echo -e "\n${CYAN}Banner SSH directo (debe verse SSH-2.0-OpenSSH...):${NC}"
probar 22 ""
echo -e "\n${CYAN}Proxy WS puerto 80 (debe verse '101 Switching Protocols' y luego SSH-2.0...):${NC}"
probar 80 'GET / HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n'

echo -e "\n${GREEN}Listo.${NC} Respaldo de sshd_config: $BACKUP"
echo "Si algo sigue fallando, pásame la salida de:"
echo "  journalctl -u $SSH_SVC -n 30 --no-pager"
echo "  journalctl -u ws-proxy -n 30 --no-pager"
