#!/usr/bin/env bash
# ==============================================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER - ULTRA CYBER EDITION
#        BHTTP V.1 & BADVPN PROTOCOL (TIGO Y CLARO NICARAGUA FULL)
#        PREMIUM SERVER EDITION v8.0
#        BHTTP CON LIMPIEZA AUTOMÁTICA DE SESIONES Y PROTECCIÓN ANTI-COLGADO
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
# GESTIÓN GLOBAL DE FIREWALL
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
clear_screen() {
    clear 2>/dev/null || true
}

linea() {
    echo -e "${NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

obtener_ip_publica() {
    local ip_pub

    ip_pub=$(
        curl -fsS --max-time 2 https://api.ipify.org 2>/dev/null ||
        hostname -I | awk '{print $1}'
    )

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

ok() {
    echo -e " ${NEON_GREEN}✔ [ÉXITO]${RESET} ${WHITE}$1${RESET}"
}

info() {
    echo -e " ${SKY}◆ [INFO]${RESET} ${WHITE}$1${RESET}"
}

fail() {
    echo -e " ${RED}✖ [ERROR]${RESET} ${WHITE}$1${RESET}"
}

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

# ==============================================================================
# CONFIGURACIÓN
# ==============================================================================
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

    apt-get install -y \
        cmake \
        g++ \
        make \
        wget \
        curl \
        badvpn \
        iptables-persistent \
        2>/dev/null || true

    local bin_badvpn=""

    if [ -f /usr/bin/badvpn-udpgw ]; then
        bin_badvpn="/usr/bin/badvpn-udpgw"
    elif [ -f /usr/local/bin/badvpn-udpgw ]; then
        bin_badvpn="/usr/local/bin/badvpn-udpgw"
    else
        bin_badvpn="$(
            which badvpn-udpgw 2>/dev/null ||
            echo "/usr/bin/badvpn-udpgw"
        )"
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
# INSTALACIÓN Y CONFIGURACIÓN DE BHTTP
# ==============================================================================
instalar_servidor() {
    titulo

    seccion "INSTALACIÓN Y CONFIGURACIÓN DE PUERTO BHTTP"

    command -v python3 >/dev/null 2>&1 || {
        fail "Python3 no está instalado."
        pausa
        return 1
    }

    local sugerido="${PUERTO:-443}"

    echo -e "  ${WHITE}Puerto BHTTP actual/sugerido:${RESET} ${NEON_GREEN}$sugerido${RESET}"

    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el nuevo puerto BHTTP (Presiona Enter para mantener $sugerido): "
    read -r nuevo_puerto

    if [ -n "$nuevo_puerto" ]; then

        if [[ "$nuevo_puerto" =~ ^[0-9]+$ ]] &&
           [ "$nuevo_puerto" -gt 0 ] &&
           [ "$nuevo_puerto" -le 65535 ]; then

            PUERTO="$nuevo_puerto"

        else

            fail "Puerto inválido. Se mantendrá el puerto anterior: $sugerido"

        fi

    else

        PUERTO="$sugerido"

    fi

    abrir_puerto_sistema "$PUERTO"

    mkdir -p "$DESTDIR"

    # ==========================================================================
    # SERVIDOR PYTHON BHTTP REFORZADO
    # ==========================================================================
    cat > "$SERVER_PY" << 'PYEOF'
#!/usr/bin/env python3

import argparse
import asyncio
import hashlib
import time

MAGIC = b"BHP1"

# ============================================================================
# PROTECCIÓN CONTRA LATENCIA, CONEXIONES COLGADAS Y ACUMULACIÓN DE MEMORIA
# ============================================================================

# Tiempo máximo para recibir cabecera/payload.
READ_TIMEOUT = 20.0

# Tiempo máximo para conectar contra el backend SSH.
BACKEND_CONNECT_TIMEOUT = 10.0

# Tiempo sin actividad antes de considerar una sesión muerta.
SESSION_IDLE_TIMEOUT = 90.0

# Vida máxima absoluta de una sesión.
SESSION_MAX_AGE = 21600.0

# Cada cuánto se ejecuta el limpiador.
CLEANUP_INTERVAL = 15.0

# Long-poll original.
LONGPOLL = 2.0

# Máximo de datos esperando dentro de una sesión.
MAX_DOWN_BUFFER = 8 * 1024 * 1024

# Máximo de bloques pendientes.
MAX_DOWN_CHUNKS = 2048

# Máximo payload permitido.
MAX_PAYLOAD = 1024 * 1024

# Cabecera BHTTP fija.
HEADER_SIZE = 29

# Máximo de bloques de una solicitud múltiple.
MAX_MULTI_COUNT = 64


# ============================================================================
# MÁSCARA / PROTOCOLO
# ============================================================================

def keystream(sess, mode, seq, d, n):

    base = hashlib.sha256(
        sess +
        bytes([mode]) +
        seq.to_bytes(8, "big") +
        bytes([d])
    )

    out = bytearray()
    c = 0

    while len(out) < n:

        h = base.copy()
        h.update(c.to_bytes(4, "big"))

        out += h.digest()
        c += 1

    return bytes(out[:n])


def mask(data, sess, mode, seq, d):

    return bytes(
        a ^ b
        for a, b in zip(
            data,
            keystream(
                sess,
                mode,
                seq,
                d,
                len(data)
            )
        )
    )


def probe_reply(mode, size):

    n = size if (
        mode == 2 and
        size >= 10
    ) else 10

    out = bytearray(
        MAGIC +
        bytes([1, mode]) +
        size.to_bytes(4, "big")
    )

    for i in range(10, n):
        out.append((i * 31) & 255)

    return bytes(out)


# ============================================================================
# SESIÓN BACKEND
# ============================================================================

class Session:

    def __init__(self, sess, backend):

        self.sess = sess
        self.backend = backend

        self.cond = asyncio.Condition()

        # --------------------------------------------------------------
        # UPLOAD
        # --------------------------------------------------------------

        self.up_next = 0
        self.up_pending = {}

        # --------------------------------------------------------------
        # DOWNLOAD
        # --------------------------------------------------------------

        self.down_raw = bytearray()
        self.down_chunks = {}
        self.down_assign = 0

        # --------------------------------------------------------------
        # ESTADO
        # --------------------------------------------------------------

        self.eof = False
        self.closed = False

        # --------------------------------------------------------------
        # BACKEND
        # --------------------------------------------------------------

        self.br = None
        self.bw = None

        self.reader_task = None

        # --------------------------------------------------------------
        # CONTROL DE VIDA
        # --------------------------------------------------------------

        now = time.monotonic()

        self.created_at = now
        self.last_activity = now

        # Evita escrituras concurrentes sobre el backend.
        self.write_lock = asyncio.Lock()

    # ------------------------------------------------------------------
    # ACTIVIDAD
    # ------------------------------------------------------------------

    def touch(self):
        self.last_activity = time.monotonic()

    def idle_for(self):
        return time.monotonic() - self.last_activity

    def age(self):
        return time.monotonic() - self.created_at

    # ------------------------------------------------------------------
    # CONECTAR BACKEND
    # ------------------------------------------------------------------

    async def connect(self):

        host, port = self.backend

        try:

            self.br, self.bw = await asyncio.wait_for(
                asyncio.open_connection(
                    host,
                    port,
                    limit=65536
                ),
                timeout=BACKEND_CONNECT_TIMEOUT
            )

            self.touch()

            self.reader_task = asyncio.create_task(
                self._reader(),
                name="bhttp-backend-reader"
            )

            return True

        except Exception:

            self.closed = True

            await self._close_backend()

            return False

    # ------------------------------------------------------------------
    # LECTOR BACKEND
    # ------------------------------------------------------------------

    async def _reader(self):

        try:

            while not self.closed:

                data = await self.br.read(65536)

                if not data:
                    break

                self.touch()

                async with self.cond:

                    if self.closed:
                        break

                    # --------------------------------------------------
                    # PROTECCIÓN DE MEMORIA
                    # --------------------------------------------------

                    if (
                        len(self.down_raw) +
                        len(data)
                        > MAX_DOWN_BUFFER
                    ):

                        self.closed = True
                        self.eof = True

                        self.cond.notify_all()

                        break

                    self.down_raw.extend(data)

                    self.cond.notify_all()

        except asyncio.CancelledError:

            raise

        except Exception:

            pass

        finally:

            async with self.cond:

                self.eof = True

                self.cond.notify_all()

    # ------------------------------------------------------------------
    # UPLOAD
    # ------------------------------------------------------------------

    async def upload(self, seq, data):

        if self.closed:
            return False

        self.touch()

        async with self.cond:

            if data:

                # Evitar acumulación infinita.
                if len(self.up_pending) >= MAX_DOWN_CHUNKS:

                    self.closed = True

                    self.cond.notify_all()

                    return False

                self.up_pending[seq] = data

        # Solo una escritura al backend a la vez.
        async with self.write_lock:

            while True:

                async with self.cond:

                    if self.closed:
                        return False

                    chunk = self.up_pending.pop(
                        self.up_next,
                        None
                    )

                    if chunk is None:
                        break

                try:

                    self.bw.write(chunk)

                    await asyncio.wait_for(
                        self.bw.drain(),
                        timeout=READ_TIMEOUT
                    )

                    self.touch()

                except asyncio.CancelledError:

                    raise

                except Exception:

                    self.closed = True

                    async with self.cond:
                        self.cond.notify_all()

                    return False

                self.up_next += 1

        return True

    # ------------------------------------------------------------------
    # DOWNLOAD
    # ------------------------------------------------------------------

    async def download(
        self,
        seq,
        maxlen,
        deadline
    ):

        if self.closed:
            return b""

        if maxlen <= 0:
            maxlen = 1399

        maxlen = min(
            maxlen,
            MAX_PAYLOAD
        )

        loop = asyncio.get_running_loop()

        async with self.cond:

            while True:

                if self.closed:
                    return b""

                # Ya asignado anteriormente.
                if seq < self.down_assign:

                    return self.down_chunks.get(
                        seq,
                        b""
                    )

                # Siguiente bloque.
                if seq == self.down_assign:

                    if self.down_raw:

                        take = bytes(
                            self.down_raw[:maxlen]
                        )

                        del self.down_raw[:maxlen]

                        self.down_chunks[
                            self.down_assign
                        ] = take

                        # Protección de memoria.
                        if (
                            len(self.down_chunks)
                            > MAX_DOWN_CHUNKS
                        ):

                            self.closed = True

                            self.cond.notify_all()

                            return b""

                        self.down_assign += 1

                        self.touch()

                        self.cond.notify_all()

                        return take

                    if self.eof:

                        self.down_assign += 1

                        self.cond.notify_all()

                        return b""

                # ------------------------------------------------------
                # ESPERA CONTROLADA
                # ------------------------------------------------------

                remaining = (
                    deadline -
                    loop.time()
                )

                if (
                    not self.eof
                    and not self.closed
                    and remaining > 0
                ):

                    try:

                        await asyncio.wait_for(
                            self.cond.wait(),
                            timeout=remaining
                        )

                    except asyncio.TimeoutError:

                        pass

                    continue

                # Long-poll agotado.
                while self.down_assign <= seq:
                    self.down_assign += 1

                self.cond.notify_all()

                return b""

    # ------------------------------------------------------------------
    # ACK
    # ------------------------------------------------------------------

    async def ack(self, seq):

        if self.closed:
            return

        self.touch()

        async with self.cond:

            old = [
                k
                for k in self.down_chunks
                if k <= seq
            ]

            for k in old:
                del self.down_chunks[k]

    # ------------------------------------------------------------------
    # CERRAR BACKEND
    # ------------------------------------------------------------------

    async def _close_backend(self):

        writer = self.bw

        self.bw = None
        self.br = None

        if writer is not None:

            try:

                writer.close()

                await asyncio.wait_for(
                    writer.wait_closed(),
                    timeout=3.0
                )

            except Exception:

                pass

    # ------------------------------------------------------------------
    # CIERRE COMPLETO
    # ------------------------------------------------------------------

    async def close(self):

        self.closed = True

        async with self.cond:

            self.eof = True

            # Liberar buffers inmediatamente.
            self.down_raw.clear()
            self.down_chunks.clear()
            self.up_pending.clear()

            self.cond.notify_all()

        # --------------------------------------------------------------
        # CANCELAR LECTOR
        # --------------------------------------------------------------

        task = self.reader_task

        if task is not None:

            current = asyncio.current_task()

            if (
                task is not current
                and not task.done()
            ):

                task.cancel()

                try:

                    await asyncio.wait_for(
                        task,
                        timeout=2.0
                    )

                except (
                    asyncio.CancelledError,
                    asyncio.TimeoutError
                ):

                    pass

                except Exception:

                    pass

        # --------------------------------------------------------------
        # CERRAR BACKEND
        # --------------------------------------------------------------

        await self._close_backend()

        # --------------------------------------------------------------
        # ROMPER REFERENCIAS
        # --------------------------------------------------------------

        self.reader_task = None


# ============================================================================
# SERVIDOR
# ============================================================================

class Server:

    def __init__(
        self,
        host,
        port,
        backend
    ):

        self.host = host
        self.port = port
        self.backend = backend

        # Todas las sesiones BHTTP.
        self.sessions = {}

        # Lock para el diccionario.
        self.slock = asyncio.Lock()

        # Tarea del limpiador.
        self.cleanup_task = None

        self.stopping = False

    # ------------------------------------------------------------------
    # OBTENER / CREAR SESIÓN
    # ------------------------------------------------------------------

    async def get_session(self, sess):

        async with self.slock:

            s = self.sessions.get(sess)

            # ----------------------------------------------------------
            # REUTILIZAR SESIÓN VIVA
            # ----------------------------------------------------------

            if (
                s is not None
                and not s.closed
            ):

                if (
                    s.idle_for()
                    <= SESSION_IDLE_TIMEOUT
                    and
                    s.age()
                    <= SESSION_MAX_AGE
                ):

                    s.touch()

                    return s

            # ----------------------------------------------------------
            # SESIÓN MUERTA / EXPIRADA
            # ----------------------------------------------------------

            if s is not None:

                self.sessions.pop(
                    sess,
                    None
                )

                await s.close()

            # ----------------------------------------------------------
            # CREAR SESIÓN NUEVA
            # ----------------------------------------------------------

            s = Session(
                sess,
                self.backend
            )

            connected = await s.connect()

            if not connected:

                await s.close()

                return None

            self.sessions[sess] = s

            return s

    # ------------------------------------------------------------------
    # LIMPIADOR AUTOMÁTICO
    # ------------------------------------------------------------------

    async def cleanup_sessions(self):

        while not self.stopping:

            try:

                await asyncio.sleep(
                    CLEANUP_INTERVAL
                )

                now = time.monotonic()

                dead = []

                # ------------------------------------------------------
                # IDENTIFICAR SESIONES MUERTAS
                # ------------------------------------------------------

                async with self.slock:

                    for sid, session in list(
                        self.sessions.items()
                    ):

                        expired_idle = (
                            now -
                            session.last_activity
                            >
                            SESSION_IDLE_TIMEOUT
                        )

                        expired_age = (
                            now -
                            session.created_at
                            >
                            SESSION_MAX_AGE
                        )

                        backend_dead = (
                            session.closed
                        )

                        if (
                            expired_idle
                            or expired_age
                            or backend_dead
                        ):

                            dead.append(
                                (
                                    sid,
                                    session
                                )
                            )

                            self.sessions.pop(
                                sid,
                                None
                            )

                # ------------------------------------------------------
                # CERRAR FUERA DEL LOCK
                # ------------------------------------------------------

                for sid, session in dead:

                    try:

                        await session.close()

                    except Exception:

                        pass

            except asyncio.CancelledError:

                break

            except Exception:

                # El limpiador nunca debe tumbar el servidor.
                continue

    # ------------------------------------------------------------------
    # LECTURA EXACTA CON TIMEOUT
    # ------------------------------------------------------------------

    async def _read_exactly(
        self,
        reader,
        size,
        timeout=READ_TIMEOUT
    ):

        return await asyncio.wait_for(
            reader.readexactly(size),
            timeout=timeout
        )

    # ------------------------------------------------------------------
    # DRAIN PROTEGIDO
    # ------------------------------------------------------------------

    async def _safe_drain(
        self,
        writer
    ):

        await asyncio.wait_for(
            writer.drain(),
            timeout=READ_TIMEOUT
        )

    # ------------------------------------------------------------------
    # HANDLER BHTTP
    # ------------------------------------------------------------------

    async def handle(
        self,
        reader,
        writer
    ):

        try:

            while not self.stopping:

                # ======================================================
                # CABECERA
                # ======================================================

                try:

                    hdr = await self._read_exactly(
                        reader,
                        HEADER_SIZE
                    )

                except asyncio.IncompleteReadError:

                    break

                except asyncio.TimeoutError:

                    # Cliente dejó de enviar datos.
                    break

                # ======================================================
                # VALIDAR CABECERA
                # ======================================================

                if len(hdr) != HEADER_SIZE:
                    break

                mode = hdr[0]

                sess = hdr[1:17]

                seq = int.from_bytes(
                    hdr[17:25],
                    "big"
                )

                ln = int.from_bytes(
                    hdr[25:29],
                    "big"
                )

                # ======================================================
                # VALIDAR MODE
                # ======================================================

                if mode not in (
                    0,
                    1,
                    2,
                    3,
                    4
                ):

                    break

                # ======================================================
                # PROTECCIÓN PAYLOAD
                # ======================================================

                if ln > MAX_PAYLOAD:

                    break

                payload = b""

                # ======================================================
                # LEER PAYLOAD
                # ======================================================

                if (
                    ln
                    and
                    mode in (
                        0,
                        1,
                        2,
                        3
                    )
                ):

                    try:

                        raw = await self._read_exactly(
                            reader,
                            ln
                        )

                    except (
                        asyncio.IncompleteReadError,
                        asyncio.TimeoutError
                    ):

                        break

                    payload = mask(
                        raw,
                        sess,
                        mode,
                        seq,
                        0
                    )

                # ======================================================
                # PROBE
                # ======================================================

                if payload[:4] == MAGIC:

                    size = (
                        int.from_bytes(
                            payload[6:10],
                            "big"
                        )
                        if len(payload) >= 10
                        else 0
                    )

                    pmode = (
                        payload[5]
                        if len(payload) >= 6
                        else mode
                    )

                    size = min(
                        max(size, 0),
                        MAX_PAYLOAD
                    )

                    body = mask(
                        probe_reply(
                            pmode,
                            size
                        ),
                        sess,
                        mode,
                        seq,
                        1
                    )

                    writer.write(
                        bytes([0]) +
                        len(body).to_bytes(
                            4,
                            "big"
                        ) +
                        body
                    )

                    await self._safe_drain(
                        writer
                    )

                    continue

                # ======================================================
                # SESIÓN
                # ======================================================

                s = await self.get_session(
                    sess
                )

                if s is None:

                    break

                s.touch()

                # ======================================================
                # MODE 1 - UPLOAD
                # ======================================================

                if mode == 1:

                    success = await s.upload(
                        seq,
                        payload
                    )

                    if not success:
                        break

                    writer.write(
                        bytes([0]) +
                        (0).to_bytes(
                            4,
                            "big"
                        )
                    )

                    await self._safe_drain(
                        writer
                    )

                # ======================================================
                # MODE 2 - DOWNLOAD
                # ======================================================

                elif mode == 2:

                    chunk = await s.download(
                        seq,
                        ln if ln > 0 else 1399,
                        asyncio.get_running_loop().time()
                        + LONGPOLL
                    )

                    self._send_data(
                        writer,
                        sess,
                        mode,
                        seq,
                        chunk
                    )

                    await self._safe_drain(
                        writer
                    )

                # ======================================================
                # MODE 3 - DOWNLOAD MÚLTIPLE
                # ======================================================

                elif mode == 3:

                    chunk_size = 1399
                    count = 1

                    if len(payload) >= 6:

                        chunk_size = int.from_bytes(
                            payload[0:4],
                            "big"
                        )

                        count = payload[5]

                    chunk_size = min(
                        max(chunk_size, 1),
                        MAX_PAYLOAD
                    )

                    count = min(
                        max(count, 1),
                        MAX_MULTI_COUNT
                    )

                    deadline = (
                        asyncio.get_running_loop().time()
                        + LONGPOLL
                    )

                    for i in range(count):

                        if s.closed:
                            break

                        chunk = await s.download(
                            seq + i,
                            chunk_size,
                            deadline
                        )

                        self._send_data(
                            writer,
                            sess,
                            mode,
                            seq + i,
                            chunk
                        )

                    await self._safe_drain(
                        writer
                    )

                # ======================================================
                # MODE 4 - ACK
                # ======================================================

                elif mode == 4:

                    await s.ack(
                        seq
                    )

                    writer.write(
                        bytes([0]) +
                        (0).to_bytes(
                            4,
                            "big"
                        )
                    )

                    await self._safe_drain(
                        writer
                    )

                else:

                    break

        except asyncio.CancelledError:

            raise

        except (
            asyncio.TimeoutError,
            asyncio.IncompleteReadError,
            ConnectionResetError,
            BrokenPipeError,
            ConnectionAbortedError
        ):

            pass

        except Exception:

            # Un cliente defectuoso no debe tumbar el proceso.
            pass

        finally:

            # ----------------------------------------------------------
            # IMPORTANTE
            #
            # Cerramos solamente la conexión BHTTP actual.
            # La sesión backend se mantiene para reutilización.
            # ----------------------------------------------------------

            try:

                writer.close()

                try:

                    await asyncio.wait_for(
                        writer.wait_closed(),
                        timeout=3.0
                    )

                except Exception:

                    pass

            except Exception:

                pass

    # ------------------------------------------------------------------
    # ENVIAR DATA
    # ------------------------------------------------------------------

    def _send_data(
        self,
        writer,
        sess,
        mode,
        seq,
        data
    ):

        real = len(data)

        masked = (
            mask(
                data,
                sess,
                mode,
                seq,
                1
            )
            if data
            else b""
        )

        body = (
            real.to_bytes(
                4,
                "big"
            ) +
            masked
        )

        writer.write(
            bytes([2]) +
            len(body).to_bytes(
                4,
                "big"
            ) +
            body
        )

    # ------------------------------------------------------------------
    # CERRAR TODAS LAS SESIONES
    # ------------------------------------------------------------------

    async def close_all_sessions(self):

        async with self.slock:

            sessions = list(
                self.sessions.values()
            )

            self.sessions.clear()

        for session in sessions:

            try:

                await session.close()

            except Exception:

                pass

    # ------------------------------------------------------------------
    # SERVE
    # ------------------------------------------------------------------

    async def serve(self):

        srv = await asyncio.start_server(
            self.handle,
            self.host,
            self.port,
            backlog=512,
            limit=65536
        )

        self.cleanup_task = asyncio.create_task(
            self.cleanup_sessions(),
            name="bhttp-session-cleaner"
        )

        try:

            async with srv:

                await srv.serve_forever()

        except asyncio.CancelledError:

            raise

        finally:

            self.stopping = True

            # ----------------------------------------------------------
            # DETENER LIMPIADOR
            # ----------------------------------------------------------

            if self.cleanup_task is not None:

                self.cleanup_task.cancel()

                try:

                    await self.cleanup_task

                except asyncio.CancelledError:

                    pass

                except Exception:

                    pass

                self.cleanup_task = None

            # ----------------------------------------------------------
            # CERRAR SESIONES
            # ----------------------------------------------------------

            await self.close_all_sessions()


# ============================================================================
# MAIN
# ============================================================================

def main():

    ap = argparse.ArgumentParser()

    ap.add_argument(
        "--host",
        default="0.0.0.0"
    )

    ap.add_argument(
        "--port",
        type=int,
        required=True
    )

    ap.add_argument(
        "--backend-host",
        default="127.0.0.1"
    )

    ap.add_argument(
        "--backend-port",
        type=int,
        default=22
    )

    a = ap.parse_args()

    server = Server(
        a.host,
        a.port,
        (
            a.backend_host,
            a.backend_port
        )
    )

    try:

        asyncio.run(
            server.serve()
        )

    except KeyboardInterrupt:

        pass


if __name__ == "__main__":

    main()
PYEOF

    chmod +x "$SERVER_PY"

    # ==========================================================================
    # SYSTEMD BHTTP
    # ==========================================================================

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

# Límites razonables para evitar que una fuga o saturación
# afecte indefinidamente al VPS.
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload

    systemctl enable "$SERVICE" >/dev/null 2>&1

    systemctl restart "$SERVICE" >/dev/null 2>&1

    instalar_badvpn

    configurar_atajo_adm

    ok "¡Servidor BHTTP instalado y protegido contra sesiones colgadas!"
    info "Limpieza automática de sesiones: cada 15 segundos."
    info "Timeout de lectura: 20 segundos."
    info "Timeout de backend SSH: 10 segundos."
    info "Inactividad máxima de sesión: 90 segundos."
    info "Buffer máximo por sesión: 8 MB."

    guardar_config

    pausa
}

# ==============================================================================
# GESTIÓN DE USUARIOS
# ==============================================================================
crear_usuario() {
    local u="$1"
    local p="$2"
    local dias="$3"

    if id "$u" >/dev/null 2>&1; then

        sed -i "/^User: $u /d" \
            "$USERS_FILE" 2>/dev/null

    else

        useradd -M -s /bin/bash "$u" || return 1

    fi

    local pass_hash

    pass_hash="$(
        openssl passwd -6 "$p" 2>/dev/null
    )"

    usermod -p "$pass_hash" "$u"

    if [[ "$dias" =~ ^[0-9]+$ ]] &&
       [ "$dias" -gt 0 ]; then

        chage -E "$(
            date -d "+${dias} days" +%Y-%m-%d 2>/dev/null ||
            date -v +${dias}d +%Y-%m-%d 2>/dev/null
        )" "$u" 2>/dev/null

        DIAS_FINAL="${dias} días"

    else

        chage -E -1 "$u" 2>/dev/null
        DIAS_FINAL="Ilimitado"

    fi

    echo "User: $u | Pass: $p | Dias: $DIAS_FINAL" \
        >> "$USERS_FILE"
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

                echo -ne " Usuario: "
                read -r nu

                echo -ne " Contraseña: "
                read -r np

                echo -ne " Días vigencia: "
                read -r nd

                if [ ${#np} -lt 4 ]; then

                    fail "Mínimo 4 caracteres"

                else

                    crear_usuario \
                        "$nu" \
                        "$np" \
                        "$nd" &&
                        ok "¡Usuario creado!"

                fi

                pausa
                ;;

            2)

                titulo

                seccion "PANEL DE DETALLES DE USUARIOS EXISTENTES"

                if [ -f "$USERS_FILE" ] &&
                   [ -s "$USERS_FILE" ]; then

                    local idx=1

                    while IFS= read -r linea_usu; do

                        local u_name
                        local u_pass
                        local u_dias

                        u_name=$(
                            echo "$linea_usu" |
                            grep -oP 'User: \K[^|]+' |
                            xargs
                        )

                        u_pass=$(
                            echo "$linea_usu" |
                            grep -oP 'Pass: \K[^|]+' |
                            xargs
                        )

                        u_dias=$(
                            echo "$linea_usu" |
                            grep -oP 'Dias: \K.*' |
                            xargs
                        )

                        local exp_date
                        local dias_restantes="N/A"

                        exp_date=$(
                            chage -l "$u_name" 2>/dev/null |
                            grep "Account expires" |
                            cut -d: -f2 |
                            xargs
                        )

                        if [ "$exp_date" != "never" ] &&
                           [ -n "$exp_date" ]; then

                            local t_exp
                            local t_hoy

                            t_exp=$(
                                date -d "$exp_date" +%s 2>/dev/null ||
                                echo 0
                            )

                            t_hoy=$(date +%s)

                            if [ "$t_exp" -gt "$t_hoy" ]; then

                                dias_restantes=$(
                                    (
                                        t_exp - t_hoy
                                    ) / 86400
                                )" días"

                            else

                                dias_restantes="Expirado"

                            fi

                        else

                            dias_restantes="Ilimitado"

                        fi

                        echo -e "  ${NEON_ORANGE}[$idx]${RESET} Usuario : ${NEON_GREEN}$u_name${RESET}"
                        echo -e "      Contraseña : ${WHITE}$u_pass${RESET}"
                        echo -e "      Vigencia   : ${CYAN}$u_dias${RESET}"
                        echo -e "      Restantes  : ${YELLOW}$dias_restantes${RESET}"
                        echo -e "  ----------------------------------------------------------"

                        idx=$((idx + 1))

                    done < "$USERS_FILE"

                else

                    info "No hay usuarios registrados."

                fi

                pausa
                ;;

            3)

                titulo

                seccion "ELIMINAR USUARIO POR NUMERACIÓN"

                if [ -f "$USERS_FILE" ] &&
                   [ -s "$USERS_FILE" ]; then

                    local idx=1

                    declare -a arr_users

                    while IFS= read -r linea_usu; do

                        local u_name

                        u_name=$(
                            echo "$linea_usu" |
                            grep -oP 'User: \K[^|]+' |
                            xargs
                        )

                        arr_users[$idx]="$u_name"

                        echo -e \
                            "  ${NEON_ORANGE}[$idx]${RESET} $u_name"

                        idx=$((idx + 1))

                    done < "$USERS_FILE"

                    echo

                    echo -ne \
                        " ${NEON_ORANGE}◆${RESET} Ingresa el número de usuario a eliminar (0 para cancelar): "

                    read -r num_del

                    if [[ "$num_del" =~ ^[0-9]+$ ]] &&
                       [ "$num_del" -gt 0 ] &&
                       [ -n "${arr_users[$num_del]:-}" ]; then

                        local target_user="${arr_users[$num_del]}"

                        userdel -r \
                            "$target_user" \
                            2>/dev/null

                        sed -i \
                            "/^User: $target_user /d" \
                            "$USERS_FILE" \
                            2>/dev/null

                        ok \
                            "¡Usuario $target_user eliminado con éxito!"

                    else

                        info \
                            "Operación cancelada o número inválido."

                    fi

                else

                    info "No hay usuarios para eliminar."

                fi

                pausa
                ;;

            4)

                titulo

                seccion "EDITAR USUARIO (DIAS Y CONTRASEÑA)"

                if [ -f "$USERS_FILE" ] &&
                   [ -s "$USERS_FILE" ]; then

                    local idx=1

                    declare -a arr_users

                    while IFS= read -r linea_usu; do

                        local u_name

                        u_name=$(
                            echo "$linea_usu" |
                            grep -oP 'User: \K[^|]+' |
                            xargs
                        )

                        arr_users[$idx]="$u_name"

                        echo -e \
                            "  ${NEON_ORANGE}[$idx]${RESET} $u_name"

                        idx=$((idx + 1))

                    done < "$USERS_FILE"

                    echo

                    echo -ne \
                        " ${NEON_ORANGE}◆${RESET} Ingresa el número de usuario a editar: "

                    read -r num_edit

                    if [[ "$num_edit" =~ ^[0-9]+$ ]] &&
                       [ "$num_edit" -gt 0 ] &&
                       [ -n "${arr_users[$num_edit]:-}" ]; then

                        local target_user="${arr_users[$num_edit]}"

                        echo -ne \
                            " Nueva contraseña (deja en blanco para no cambiar): "

                        read -r n_pass

                        echo -ne \
                            " Añadir días de vigencia (ej. 30, deja en blanco para no cambiar): "

                        read -r n_dias

                        local p_actual

                        p_actual=$(
                            grep "^User: $target_user " \
                                "$USERS_FILE" |
                            grep -oP 'Pass: \K[^|]+' |
                            xargs
                        )

                        [ -z "$n_pass" ] &&
                            n_pass="$p_actual"

                        local pass_hash

                        pass_hash="$(
                            openssl passwd -6 "$n_pass" 2>/dev/null
                        )"

                        usermod \
                            -p "$pass_hash" \
                            "$target_user" \
                            2>/dev/null

                        if [[ "$n_dias" =~ ^[0-9]+$ ]] &&
                           [ "$n_dias" -gt 0 ]; then

                            chage -E "$(
                                date -d "+${n_dias} days" +%Y-%m-%d 2>/dev/null ||
                                date -v +${n_dias}d +%Y-%m-%d 2>/dev/null
                            )" "$target_user" 2>/dev/null

                            DIAS_FINAL="${n_dias} días"

                        else

                            DIAS_FINAL="Actualizado"

                        fi

                        sed -i \
                            "/^User: $target_user /d" \
                            "$USERS_FILE" \
                            2>/dev/null

                        echo \
                            "User: $target_user | Pass: $n_pass | Dias: $DIAS_FINAL" \
                            >> "$USERS_FILE"

                        ok \
                            "¡Usuario $target_user actualizado correctamente!"

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
                seccion "ESTADO DE USUARIOS CONECTADOS EN VIVO"

                if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then

                    while IFS= read -r linea_usu; do

                        u_name=$(
                            echo "$linea_usu" |
                            grep -oP 'User: \K[^|]+' |
                            xargs
                        )

                        [ -z "$u_name" ] && continue

                        if ! id "$u_name" >/dev/null 2>&1; then
                            continue
                        fi

                        conns=0

                        # ==================================================
                        # MÉTODO 1: LOGINCTL
                        # Cuenta sesiones PAM/SSH registradas por systemd
                        # ==================================================

                        if command -v loginctl >/dev/null 2>&1; then

                            conns=$(
                                loginctl list-sessions --no-legend 2>/dev/null |
                                awk -v user="$u_name" '$3 == user {count++}
                                END {print count+0}'
                            )

                        fi

                        # ==================================================
                        # MÉTODO 2: PROCESOS SSHD DEL USUARIO
                        # Busca específicamente sshd: usuario@...
                        # ==================================================

                        if [ "${conns:-0}" -eq 0 ]; then

                            conns=$(
                                ps -eo user=,pid=,args= 2>/dev/null |
                                awk -v user="$u_name" '
                                    $1 == user &&
                                    $0 ~ /sshd:/ &&
                                    $0 ~ /@/ {
                                        count++
                                    }
                                    END {
                                        print count+0
                                    }
                                '
                            )

                        fi

                        # ==================================================
                        # MÉTODO 3: Pgrep
                        # ==================================================

                        if [ "${conns:-0}" -eq 0 ]; then

                            conns=$(
                                pgrep -u "$u_name" -af 'sshd' 2>/dev/null |
                                grep -E 'sshd:.*@' |
                                wc -l
                            )

                        fi

                        # ==================================================
                        # MÉTODO 4: WHO
                        # ==================================================

                        if [ "${conns:-0}" -eq 0 ] &&
                           command -v who >/dev/null 2>&1; then

                            conns=$(
                                who 2>/dev/null |
                                awk -v user="$u_name" '
                                    $1 == user {
                                        count++
                                    }
                                    END {
                                        print count+0
                                    }
                                '
                            )

                        fi

                        # Seguridad
                        [[ "$conns" =~ ^[0-9]+$ ]] || conns=0

                        # ==================================================
                        # RESULTADO
                        # ==================================================

                        if [ "$conns" -gt 0 ]; then

                            echo -e \
                                "  👤 Usuario: ${NEON_GREEN}${u_name}${RESET} / ${NEON_ORANGE}${conns} conexión(es) activa(s)${RESET} 🟢"

                        else

                            echo -e \
                                "  👤 Usuario: ${GRAY}${u_name}${RESET} / ${RED}0 en línea${RESET} 🔴"

                        fi

                    done < "$USERS_FILE"

                else

                    info "No hay usuarios registrados."

                fi

                echo

                echo -ne \
                    "${GRAY}Presiona ${NEON_GREEN}[Enter]${GRAY} para regresar al menú...${RESET}"

                read -r
                ;;

# ==============================================================================
# BADVPN
# ==============================================================================
menu_optimizar_vps() {

    while true; do

        titulo

        local bv_txt

        if [ "$BADVPN_STATE" = "ON" ]; then

            bv_txt="${NEON_GREEN}ACTIVO (ON) - Puerto $BADVPN_PORT${RESET}"

        else

            bv_txt="${RED}INACTIVO (OFF)${RESET}"

        fi

        seccion \
            "CONFIGURACIÓN DE BADVPN GATEWAY (UDP PARA JUEGOS Y VOIP)"

        echo -e \
            "  ${WHITE}Estado Actual BadVPN:${RESET} [ $bv_txt ]"

        echo -e \
            "  ${GRAY}BadVPN mejora la latencia y asegura estabilidad UDP para llamadas y juegos.${RESET}"

        linea

        echo -e \
            "  ${NEON_GREEN}[1]${RESET} Activar / Encender BadVPN en el Puerto ${YELLOW}7300${RESET}"

        echo -e \
            "  ${NEON_GREEN}[2]${RESET} Activar / Encender BadVPN en el Puerto ${YELLOW}7200${RESET}"

        echo -e \
            "  ${NEON_GREEN}[3]${RESET} Apagar BadVPN Gateway (OFF)"

        echo -e \
            "  ${RED}[0]${RESET} Regresar"

        linea

        echo -ne \
            " ${NEON_ORANGE}◆${RESET} Selecciona una opción: "

        read -r opt_opt

        case $opt_opt in

            1)

                BADVPN_PORT=7300

                instalar_badvpn

                systemctl enable \
                    "$BADVPN_SERVICE" >/dev/null 2>&1

                systemctl restart \
                    "$BADVPN_SERVICE"

                abrir_puerto_sistema \
                    "$BADVPN_PORT"

                BADVPN_STATE="ON"

                guardar_config

                ok \
                    "¡BadVPN activado exitosamente en el puerto 7300!"

                pausa

                ;;

            2)

                BADVPN_PORT=7200

                instalar_badvpn

                systemctl enable \
                    "$BADVPN_SERVICE" >/dev/null 2>&1

                systemctl restart \
                    "$BADVPN_SERVICE"

                abrir_puerto_sistema \
                    "$BADVPN_PORT"

                BADVPN_STATE="ON"

                guardar_config

                ok \
                    "¡BadVPN activado exitosamente en el puerto 7200!"

                pausa

                ;;

            3)

                systemctl stop \
                    "$BADVPN_SERVICE" \
                    2>/dev/null

                systemctl disable \
                    "$BADVPN_SERVICE" \
                    2>/dev/null

                BADVPN_STATE="OFF"

                guardar_config

                ok "¡BadVPN apagado correctamente!"

                pausa

                ;;

            0)

                return
                ;;

        esac

    done
}

# ==============================================================================
# BHTTP BBR
# ==============================================================================
menu_bhttp_bbr() {

    while true; do

        titulo

        seccion \
            "BHTTP BBR • ACELERACIÓN DE TRANSPORTE TCP MÁXIMA"

        echo -e \
            "  ${WHITE}Estado Actual BBR:${RESET} [ ${NEON_ORANGE}${BBR_STATUS}${RESET} ]"

        echo -e \
            "  ${GRAY}Optimiza los búferes del kernel y el algoritmo de congestión TCP.${RESET}"

        linea

        echo -e \
            "  ${NEON_GREEN}[1]${RESET} Fuerza Bruta (Máxima velocidad y búferes)"

        echo -e \
            "  ${NEON_GREEN}[2]${RESET} Estabilidad + Velocidad (BBR + FQ)"

        echo -e \
            "  ${NEON_GREEN}[3]${RESET} Apagar BHTTP BBR (Restaurar valores por defecto)"

        echo -e \
            "  ${RED}[0]${RESET} Regresar al Menú Principal"

        linea

        echo -ne \
            " ${NEON_ORANGE}◆${RESET} Selecciona una opción: "

        read -r bbr_op

        case $bbr_op in

            1)

                info \
                    "Aplicando perfil de Fuerza Bruta TCP en el Kernel..."

                sysctl -w \
                    net.core.default_qdisc=fq \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_congestion_control=bbr \
                    >/dev/null 2>&1

                sysctl -w \
                    net.core.rmem_max=67108864 \
                    >/dev/null 2>&1

                sysctl -w \
                    net.core.wmem_max=67108864 \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_rmem="4096 87380 33554432" \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_wmem="4096 65536 33554432" \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_window_scaling=1 \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_fastopen=3 \
                    >/dev/null 2>&1

                cat >> /etc/sysctl.conf << 'EOF'
# BHTTP BBR Fuerza Bruta Config
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_fastopen=3
EOF

                sysctl -p >/dev/null 2>&1

                BBR_STATUS="FUERZA BRUTA (ON)"

                guardar_config

                ok \
                    "¡Aceleración de Fuerza Bruta aplicada!"

                pausa

                ;;

            2)

                info \
                    "Aplicando perfil Estabilidad + Velocidad (BBR Optimizado)..."

                sysctl -w \
                    net.core.default_qdisc=fq_codel \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_congestion_control=bbr \
                    >/dev/null 2>&1

                sysctl -w \
                    net.core.rmem_max=33554432 \
                    >/dev/null 2>&1

                sysctl -w \
                    net.core.wmem_max=33554432 \
                    >/dev/null 2>&1

                sysctl -w \
                    net.ipv4.tcp_fastopen=3 \
                    >/dev/null 2>&1

                cat >> /etc/sysctl.conf << 'EOF'
# BHTTP BBR Estabilidad y Velocidad Config
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_fastopen=3
EOF

                sysctl -p >/dev/null 2>&1

                BBR_STATUS="ESTABILIDAD+VELOCIDAD (ON)"

                guardar_config

                ok \
                    "¡Perfil de Estabilidad y Velocidad aplicado con éxito!"

                pausa

                ;;

            3)

                info \
                    "Apagando BBR y restaurando valores estándar..."

                sed -i \
                    '/BHTTP BBR/d' \
                    /etc/sysctl.conf \
                    2>/dev/null

                sed -i \
                    '/net.ipv4.tcp_congestion_control/d' \
                    /etc/sysctl.conf \
                    2>/dev/null

                sed -i \
                    '/net.core.default_qdisc/d' \
                    /etc/sysctl.conf \
                    2>/dev/null

                sysctl -w \
                    net.ipv4.tcp_congestion_control=cubic \
                    >/dev/null 2>&1

                sysctl -w \
                    net.core.default_qdisc=pfifo_fast \
                    >/dev/null 2>&1

                sysctl -p >/dev/null 2>&1

                BBR_STATUS="OFF"

                guardar_config

                ok \
                    "¡BHTTP BBR apagado y sistema restaurado!"

                pausa

                ;;

            0)

                return
                ;;

        esac

    done
}

# ==============================================================================
# AUTO INICIO
# ==============================================================================
menu_autostart() {

    while true; do

        titulo

        seccion \
            "AUTO INICIAR SCRIPT AL ABRIR TERMINAL"

        echo -e \
            "  ${WHITE}Estado actual Auto-Iniciar:${RESET} [ ${NEON_ORANGE}$AUTOSTART_STATUS${RESET} ]"

        echo -e \
            "  ${GRAY}Si está en ON, al entrar por SSH entrará directo al panel.${RESET}"

        linea

        echo -e \
            "  ${NEON_GREEN}[1]${RESET} Encender (ON)"

        echo -e \
            "  ${NEON_GREEN}[2]${RESET} Apagar (OFF)"

        echo -e \
            "  ${RED}[0]${RESET} Regresar"

        linea

        echo -ne \
            " ${NEON_ORANGE}◆${RESET} Opción: "

        read -r as_op

        case $as_op in

            1)

                AUTOSTART_STATUS="ON"

                guardar_config

                for rc in \
                    /root/.bashrc \
                    /root/.zshrc \
                    /etc/bash.bashrc; do

                    if [ -f "$rc" ] ||
                       [ "$rc" = "/root/.bashrc" ]; then

                        sed -i \
                            '/intalar\.sh/d' \
                            "$rc" \
                            2>/dev/null

                        echo \
                            "[[ \$- == *i* ]] && [ -z \"\$TMUX\" ] && sudo bash $SCRIPT_PATH" \
                            >> "$rc"

                    fi

                done

                ok \
                    "¡Auto iniciar activado (ON)!"

                pausa

                ;;

            2)

                AUTOSTART_STATUS="OFF"

                guardar_config

                for rc in \
                    /root/.bashrc \
                    /root/.zshrc \
                    /etc/bash.bashrc; do

                    if [ -f "$rc" ] ||
                       [ "$rc" = "/root/.bashrc" ]; then

                        sed -i \
                            '/intalar\.sh/d' \
                            "$rc" \
                            2>/dev/null

                    fi

                done

                ok \
                    "¡Auto iniciar desactivado (OFF)!"

                pausa

                ;;

            0)

                return
                ;;

        esac

    done
}

# ==============================================================================
# OPTIMIZACIÓN AUTOMÁTICA
# ==============================================================================
ejecutar_optimizacion_manual() {

    sync

    echo 3 > /proc/sys/vm/drop_caches \
        2>/dev/null || true

    swapoff -a

    swapon -a \
        2>/dev/null || true
}

menu_optimizacion_automatica() {

    while true; do

        titulo

        seccion \
            "OPTIMIZACIÓN AUTOMÁTICA CADA 6 HORAS (RAM Y CPU)"

        echo -e \
            "  ${WHITE}Estado actual Optimización Automática:${RESET} [ ${NEON_ORANGE}$CRON_STATUS${RESET} ]"

        linea

        echo -e \
            "  ${NEON_GREEN}[1]${RESET} Activar optimización automática cada 6 horas (ON)"

        echo -e \
            "  ${NEON_GREEN}[2]${RESET} Desactivar optimización automática (OFF)"

        echo -e \
            "  ${NEON_GREEN}[3]${RESET} Ejecutar optimización de memoria y CPU ahora mismo"

        echo -e \
            "  ${RED}[0]${RESET} Regresar"

        linea

        echo -ne \
            " ${NEON_ORANGE}◆${RESET} Opción: "

        read -r cron_op

        case $cron_op in

            1)

                CRON_STATUS="ON"

                guardar_config

                local cron_cmd="0 */6 * * * sync && echo 3 > /proc/sys/vm/drop_caches >/dev/null 2>&1"

                (
                    crontab -l 2>/dev/null |
                    grep -v "drop_caches"

                    echo "$cron_cmd"

                ) | crontab -

                ok \
                    "¡Optimización automática cada 6 horas activada!"

                pausa

                ;;

            2)

                CRON_STATUS="OFF"

                guardar_config

                (
                    crontab -l 2>/dev/null |
                    grep -v "drop_caches"

                ) | crontab - \
                    2>/dev/null || true

                ok \
                    "¡Optimización automática desactivada!"

                pausa

                ;;

            3)

                info \
                    "Liberando búferes y optimizando recursos del servidor..."

                ejecutar_optimizacion_manual

                ok \
                    "¡Sistema optimizado con éxito!"

                pausa

                ;;

            0)

                return
                ;;

        esac

    done
}

# ==============================================================================
# ACTUALIZADOR DESDE GITHUB
# ==============================================================================
actualizar_script() {

    titulo

    seccion \
        "ACTUALIZADOR AUTOMÁTICO DEL SCRIPT"

    info \
        "Conectando con GitHub para buscar cambios..."

    local URL_GITHUB="https://raw.githubusercontent.com/21062022/intalar.sh/main/intalar.sh"
    local TEMP_SCRIPT="/tmp/intalar_update.sh"

    if curl -fsSL \
        "$URL_GITHUB" \
        -o "$TEMP_SCRIPT"; then

        if head -n 3 "$TEMP_SCRIPT" |
           grep -q "bash"; then

            cp \
                "$TEMP_SCRIPT" \
                "$SCRIPT_PATH" \
                2>/dev/null

            chmod +x \
                "$SCRIPT_PATH"

            configurar_atajo_adm

            ok \
                "¡Script actualizado a la versión más reciente!"

            info \
                "Reiniciando el panel automáticamente..."

            sleep 2

            exec sudo bash \
                "$SCRIPT_PATH"

        else

            fail \
                "El archivo descargado de GitHub no tiene un formato válido."

        fi

    else

        fail \
            "No se pudo conectar con GitHub. Revisa tu conexión."

    fi

    pausa
}

# ==============================================================================
# DESTRUCCIÓN TOTAL
# ==============================================================================
destruir_script_total() {

    titulo

    echo -e \
        "${RED}╔══════════════════════════════════════════════════════════════════╗${RESET}"

    echo -e \
        "${RED}║${RESET} ${WHITE}${BOLD}             ADVERTENCIA: DESTRUCCIÓN TOTAL DEL SISTEMA           ${RESET}${RED}║${RESET}"

    echo -e \
        "${RED}╚══════════════════════════════════════════════════════════════════╝${RESET}"

    echo

    echo -e \
        "  ${WHITE}Esta opción eliminará por completo BHTTP, BadVPN, configuraciones,${RESET}"

    echo -e \
        "  ${WHITE}archivos de usuario, comandos rápidos y servicios del sistema.${RESET}"

    echo

    echo -ne \
        " ${RED}◆${RESET} ¿Estás seguro de que deseas desinstalar y borrar todo? (s/n): "

    read -r confirmacion

    if [[ "$confirmacion" =~ ^[sS]$ ]]; then

        info \
            "Deteniendo servicios activos..."

        systemctl stop \
            "$SERVICE" \
            2>/dev/null || true

        systemctl disable \
            "$SERVICE" \
            2>/dev/null || true

        systemctl stop \
            "$BADVPN_SERVICE" \
            2>/dev/null || true

        systemctl disable \
            "$BADVPN_SERVICE" \
            2>/dev/null || true

        info \
            "Eliminando archivos de servicio y binarios..."

        rm -f \
            "$UNIT" \
            "$BADVPN_UNIT" \
            2>/dev/null

        systemctl daemon-reload

        systemctl reset-failed \
            2>/dev/null || true

        rm -rf \
            "$DESTDIR" \
            "$CONFIG_DIR" \
            2>/dev/null

        rm -f \
            "$ADM_BIN" \
            "$ADMIN_BIN" \
            "$SCRIPT_PATH" \
            2>/dev/null

        info \
            "Limpiando accesos directos en terminal..."

        for rc in \
            /root/.bashrc \
            /root/.zshrc \
            /etc/bash.bashrc; do

            if [ -f "$rc" ] ||
               [ "$rc" = "/root/.bashrc" ]; then

                sed -i \
                    '/intalar\.sh/d' \
                    "$rc" \
                    2>/dev/null

                sed -i \
                    '/alias adm=/d' \
                    "$rc" \
                    2>/dev/null

                sed -i \
                    '/alias admin=/d' \
                    "$rc" \
                    2>/dev/null

            fi

        done

        ok \
            "¡Desinstalación y destrucción total completada con éxito!"

        echo -e \
            "${GRAY} El script se cerrará permanentemente.${RESET}"

        exit 0

    else

        info \
            "Operación de destrucción cancelada. Regresando al menú..."

        pausa

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

        estado=$(
            systemctl is-active \
                "$SERVICE" \
                2>/dev/null ||
            echo "inactivo"
        )

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

        echo -e \
            "  ${WHITE}BHTTP Servidor :${RESET} ${estado_color}  |  Puerto: ${bhttp_port_show}"

        echo -e \
            "  ${WHITE}BadVPN Gateway :${RESET} ${bv_color}  |  Puerto: ${badvpn_port_show}"

        echo -e \
            "  ${WHITE}Comandos Ráp.  :${RESET} ${NEON_PINK}adm${RESET} o ${NEON_PINK}admin${RESET}"

        linea

        echo -e \
            "  ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar puerto BHTTP OK"

        echo -e \
            "  ${NEON_GREEN}[2]${RESET} Gestionar Usuarios (Crear, Editar, En línea)"

        echo -e \
            "  ${NEON_GREEN}[3]${RESET} Encender / Apagar BHTTP Server"

        echo -e \
            "  ${NEON_GREEN}[4]${RESET} Abrir Puertos Manuales (Firewall)"

        echo -e \
            "  ${NEON_GREEN}[5]${RESET} BadVPN Gateway (Puertos 7200 o 7300 / UDP Juegos)"

        echo -e \
            "  ${NEON_GREEN}[6]${RESET} Actualizar Script desde GitHub"

        echo -e \
            "  ${NEON_GREEN}[7]${RESET} (Extra) Liberar Memoria RAM Manual"

        echo -e \
            "  ${NEON_GREEN}[8]${RESET} Auto Iniciar Script al Abrir Terminal"

        echo -e \
            "  ${NEON_GREEN}[9]${RESET} Optimización Automática Cada 6 Horas (RAM y CPU)"

        echo -e \
            "  ${NEON_GREEN}[10]${RESET} BHTTP BBR (Aceleración de Velocidad TCP Extrema)"

        echo -e \
            "  ${RED}[11]${RESET} Destrucción Total / Desinstalar Script Completo"

        echo -e \
            "  ${RED}[0]${RESET} Salir del Script"

        linea

        echo -ne \
            " ${NEON_ORANGE}◆${RESET} Selecciona una opción: "

        read -r opc

        case $opc in

            1)

                instalar_servidor

                ;;

            2)

                menu_usuarios

                ;;

            3)

                titulo

                seccion \
                    "CONTROL DE ESTADO BHTTP SERVER"

                if [ "$estado" = "active" ]; then

                    systemctl stop \
                        "$SERVICE" \
                        2>/dev/null

                    systemctl disable \
                        "$SERVICE" \
                        2>/dev/null

                    ok \
                        "¡Servidor BHTTP detenido y apagado (OFF)!"

                else

                    systemctl enable \
                        "$SERVICE" \
                        2>/dev/null

                    systemctl start \
                        "$SERVICE" \
                        2>/dev/null

                    ok \
                        "¡Servidor BHTTP encendido y activo (ON)!"

                fi

                pausa

                ;;

            4)

                menu_activar_puertos

                ;;

            5)

                menu_optimizar_vps

                ;;

            6)

                actualizar_script

                ;;

            7)

                info \
                    "Liberando búferes y optimizando memoria..."

                ejecutar_optimizacion_manual

                ok \
                    "¡Memoria RAM liberada con éxito!"

                pausa

                ;;

            8)

                menu_autostart

                ;;

            9)

                menu_optimizacion_automatica

                ;;

            10)

                menu_bhttp_bbr

                ;;

            11)

                destruir_script_total

                ;;

            0)

                clear_screen

                exit 0

                ;;

            *)

                fail \
                    "Opción inválida."

                pausa

                ;;

        esac

    done
}

# ==============================================================================
# INICIO
# ==============================================================================
check_root
cargar_config
menu_principal
