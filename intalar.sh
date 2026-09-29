
#!/usr/bin/env bash
# ==============================================================================
# INSTALADOR DE SCRIPTS MÚLTIPLES DE HAZAEL MORENO - EDICIÓN ULTRA CIBERNÉTICA
# PROTOCOLO BHTTP V.1 & BADVPN (TIGO Y CLARO NICARAGUA COMPLETO)
# EDICIÓN DE SERVIDOR PREMIUM v6.6 (Puerto Personalizable y Corrección de administrador)
# ==============================================================================

establecer -o fallo de tubería

# ==============================================================================
# PALETA DE COLORES VIBRANTES Y NEÓN
# ==============================================================================
REINICIAR="\e[0m"
NEGRITA="\e[1m"
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
NEÓN_AZUL="\e[38;5;39m"
NEÓN_VERDE="\e[38;5;46m"
NEÓN_ROSA="\e[38;5;198m"
NEÓN_NARANJA="\e[38;5;208m"

# ==============================================================================
#RUTAS Y DIRECTORIOS DEL SISTEMA
# ==============================================================================
DESTDIR="/usr/local/lib/bhttp"
SERVER_PY="$DESTDIR/bhttp-server.py"
UNIT="/etc/systemd/system/bhttp.service"
BADVPN_UNIT="/etc/systemd/system/badvpn.service"
SERVICIO="bhttp"
BADVPN_SERVICE="badvpn"
CONFIG_DIR="/etc/bhttp"
CONFIG="$CONFIG_DIR/nullcore.conf"
USERS_FILE="$CONFIG_DIR/cuentas.txt"
SCRIPT_PATH="/usr/local/bin/intalar.sh"
ADM_BIN="/usr/local/bin/adm"
ADMIN_BIN="/usr/local/bin/admin"
CANDIDATOS=(8080 80 8443 443 2082 2095 8880 2052 3128)

PUERTO=""
Puerto SSH=22
BADVPN_PORT=7300

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

  para rc en /root/.bashrc /root/.zshrc /etc/bash.bashrc; hacer
    if [ -f "$rc" ] || [ "$rc" = "/root/.bashrc" ]; then
      tocar "$rc" 2>/dev/null
      sed -i '/alias adm=/d' "$rc" 2>/dev/null
      sed -i '/alias admin=/d' "$rc" 2>/dev/null
      echo "alias adm='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
      echo "alias admin='sudo bash /usr/local/bin/intalar.sh'" >> "$rc"
    fi
  hecho
}

# ==============================================================================
#GESTIÓN GLOBAL DE FIREWALL (UFW E IPTABLES AUTOMÁTICO)
# ==============================================================================
abrir_puerto_sistema() {
    local p_custom="$1"
    info "Aplicando reglas de red y firewall para el puerto $p_custom..."

    Si el comando -v ufw >/dev/null 2>&1; entonces
        ufw permite "$p_custom"/tcp >/dev/null 2>&1
        ufw permite "$BADVPN_PORT"/tcp >/dev/null 2>&1
        ufw permitir 22/tcp >/dev/null 2>&1
        ufw recargar >/dev/null 2>&1 || verdadero
    fi

    Si el comando -v iptables >/dev/null 2>&1; entonces
        iptables -A INPUT -p tcp --dport "$p_custom" -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport "$BADVPN_PORT" -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 8880 -j ACCEPT 2>/dev/null || true
        
        Si el comando -v netfilter-persistent >/dev/null 2>&1; entonces
            netfilter-persistent save >/dev/null 2>&1 || true
        elif [ -d /etc/iptables ]; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
    fi
    ok "Puerto $p_custom y servicios activados en UFW e IPTables correctamente."
}

# ==============================================================================
# INTERFAZ VISUAL CYBERPUNK
# ==============================================================================
clear_screen() { clear 2>/dev/null || true; }
linea() { eco -e "${NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

título() {
    pantalla limpia
    echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_GREEN}${BOLD} HAZAEL MORENO MULTI SCRIPT${RESET} ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}║${RESET} ${NEON_BLUE}${BOLD} BHTTP V.1 & BADVPN PROTOCOL v6.6${RESET} ${NEON_PINK}║${RESET}"
    echo -e "${NEON_PINK}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${SKY} 🚀 ${NEON_ORANGE}TIGO Y CLARO NICARAGUA${RESET} ${SKY}• TUNELIZACIÓN MÁXIMA PRO 🚀${RESET}"
    eco
}

sección() {
    eco
    eco -e "${MAGENTA}┌──────────────────────────────── ──────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${RESET} ${WHITE}${BOLD} $1${RESET}"
    eco -e "${MAGENTA}└──────────────────────────────── ──────────────────────────────────┘${RESET}"
    eco
}

ok() { echo -e " ${NEON_GREEN}✔ [ÉXITO]${RESET} ${WHITE}$1${RESET}"; }
info() { echo -e " ${SKY}◆ [INFO]${RESET} ${WHITE}$1${RESET}"; }
fail() { echo -e " ${RED}✖ [ERROR]${RESET} ${WHITE}$1${RESET}"; }

pausa() {
    eco
    echo -e "${GRAY} Presiona ${NEON_GREEN}[Enter]${GRAY} para regresar...${RESET}"
    leer -r
}

check_root() {
  if [ "$(id -u 2>/dev/null || echo 0)" != 0 ]; then
    fail "Este script debe ejecutarse como root: sudo bash $0"
    Salida 2
  fi
}

cargar_config() {
  mkdir -p "$CONFIG_DIR"
  [ -f "$CONFIG" ] && source "$CONFIG"
  [ -z "${PUERTO:-}" ] && PUERTO="8080"
  [ -z "${SSHPORT:-}" ] && SSHPORT=22
  [ -z "${BADVPN_PORT:-}" ] && BADVPN_PORT=7300
}

guardar_config() {
  mkdir -p "$CONFIG_DIR"
  gato > "$CONFIG" <<EOF
PUERTO=${PUERTO}
SSHPORT=${SSHPORT}
BADVPN_PORT=${BADVPN_PORT}
EOF
}

# ==============================================================================
# INSTALACIÓN DE BADVPN Y BHTTP
# ==============================================================================
instalar_badvpn() {
    apt-get update -y >/dev/null 2>&1
    apt-get install -y cmake g++ make wget curl badvpn iptables-persistent 2>/dev/null || true

    cat > "$BADVPN_UNIT" <<EOF
[Unidad]
Descripción=Puerta de enlace UDP de BadVPN
Después=red.objetivo

[Servicio]
Tipo=simple
Usuario=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 500 --max-connections 1000
Reiniciar=siempre
ReiniciarSec=3

[Instalar]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$BADVPN_SERVICE" >/dev/null 2>&1
    systemctl restart "$BADVPN_SERVICE"
}

ocupados() {
  Si el comando -v ss >/dev/null 2>&1; entonces
    ss -tln 2>/dev/null | tail -n +2 | awk '{print $4}' | sed 's/.*://'
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln 2>/dev/null | awk '/^tcp/ {imprimir $4}' | sed 's/.*://'
  fi | grep -E '^[0-9]+$' | ordenar -u
}
libre() { ! ocupados | grep -qx "$1"; }

instalar_servidor() {
  título
  sección "INSTALACIÓN Y CONFIGURACIÓN DE PUERTO BHTTP"
  
  comando -v python3 >/dev/null 2>&1 || { falla "Python3 no está instalado."; pausa; devolver 1; }
  
  local sugerido="${PUERTO:-8080}"
  echo -e " ${WHITE}Puerto BHTTP actual/sugerido:${RESET} ${NEON_GREEN}$sugerido${RESET}"
  echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el nuevo puerto BHTTP (Presiona Enter para mantener $sugerido): "
  leer -r nuevo_puerto
  
  si [ -n "$nuevo_puerto" ]; entonces
    if [[ "$nuevo_puerto" =~ ^[0-9]+$ ]] && [ "$nuevo_puerto" -gt 0 ] && [ "$nuevo_puerto" -le 65535 ]; entonces
      PUERTO="$nuevo_puerto"
    demás
      fail "Puerto inválido. Se mantendrá el puerto anterior: $sugerido"
    fi
  fi

  abrir_puerto_sistema "$PUERTO"

  mkdir -p "$DESTDIR"
  cat > "$SERVER_PY" << 'PYEOF'
#!/usr/bin/env python3
import argparse, asyncio, hashlib, struct, sys
MAGIC = b"BHP1"
LONGOPA = 2.0
def keystream(sess, mode, seq, d, n):
    base = hashlib.sha256(sess + bytes([mode]) + seq.to_bytes(8, "big") + bytes([d]))
    out = bytearray(); c = 0
    mientras len(out) < n:
        h = base.copy(); h.update(c.to_bytes(4, "big")); out += h.digest(); c += 1
    devolver bytes(out[:n])
def máscara(datos, sesión, modo, secuencia, d):
    return bytes(a ^ b para a, b en zip(data, keystream(sess, mode, seq, d, len(data))))
def probe_reply(modo, tamaño):
    n = tamaño si (modo == 2 y tamaño >= 10) de lo contrario 10
    out = bytearray(MAGIC + bytes([1, mode]) + size.to_bytes(4, "big"))
    para i en rango(10, n): out.append((i * 31) & 255)
    devolver bytes(salida)
Sesión de clase:
    def __init__(self, sess, backend):
        self.sess = sess; self.backend = backend
        self.cond = asyncio.Condition(); self.up_next = 0; self.up_pending = {}
        self.down_raw = bytearray(); self.down_chunks = {}; self.down_assign = 0
        self.eof = Falso; self.closed = Falso; self.br = Ninguno; self.bw = Ninguno
    async def connect(self):
        host, puerto = self.backend
        self.br, self.bw = await asyncio.open_connection(host, port)
        asyncio.create_task(self._reader())
    async def _reader(self):
        intentar:
            mientras que verdadero:
                datos = esperar a que se lea el texto completo (65536)
                Si no hay datos: salir
                asíncrono con self.cond: self.down_raw += data; self.cond.notify_all()
        excepto Excepción: pasar
        finalmente:
            asíncrono con self.cond: self.eof = True; self.cond.notify_all()
    async def upload(self, seq, data):
        asíncrono con self.cond:
            Si hay datos: self.up_pending[seq] = datos
            mientras self.up_next esté en self.up_pending:
                fragmento = self.up_pending.pop(self.up_next)
                intentar: self.bw.write(chunk); esperar self.bw.drain()
                excepto Exception: self.closed = True
                self.up_next += 1
    async def download(self, seq, maxlen, deadline):
        Si maxlen <= 0: maxlen = 1399
        bucle = asyncio.get_running_loop()
        asíncrono con self.cond:
            mientras que verdadero:
                if seq < self.down_assign: return self.down_chunks.get(seq, b"")
                si seq == self.down_assign:
                    si self.down_raw:
                        tomar = bytes(self.down_raw[:maxlen]); del self.down_raw[:maxlen]
                        self.down_chunks[self.down_assign] = tomar; self.down_assign += 1
                        self.cond.notify_all(); return tomar
                    if self.eof: self.down_assign += 1; self.cond.notify_all(); return b""
                Si no es self.eof y loop.time() < deadline:
                    try: await asyncio.wait_for(self.cond.wait(), timeout=max(0.01, deadline - loop.time()))
                    excepto asyncio.TimeoutError: pasar
                    continuar
                mientras self.down_assign <= seq: self.down_assign += 1
                self.cond.notify_all(); return b""
    async def ack(self, seq):
        asíncrono con self.cond:
            para k en [k para k en self.down_chunks si k <= seq]: del self.down_chunks[k]
    async def close(self):
        asíncrono con self.cond: self.closed = True; self.cond.notify_all()
        intentar: self.bw.close()
        excepto Excepción: pasar
clase Servidor:
    def __init__(self, host, puerto, backend):
        host, puerto, backend = host, puerto, backend
        self.sessions = {}; self.slock = asyncio.Lock()
    async def get_session(self, sess):
        asíncrono con self.slock:
            s = self.sessions.get(sess)
            Si s es None o s.closed:
                para old_sid, old en list(self.sessions.items()):
                    if old_sid != sess: await old.close(); del self.sessions[old_sid]
                s = Session(sess, self.backend); await s.connect(); self.sessions[sess] = s
            retornos
    async def handle(self, reader, writer):
        intentar:
            mientras que verdadero:
                hdr = esperar lector.readexactly(29)
                modo = hdr[0]; sess = hdr[1:17]; seq = int.from_bytes(hdr[17:25], "big"); ln = int.from_bytes(hdr[25:29], "big")
                carga útil = b""
                Si ln y moda están en (0, 1, 2, 3):
                    raw = await reader.readexactly(ln); payload = mask(raw, sess, mode, seq, 0)
                si payload[:4] == MAGIC:
                    tamaño = int.from_bytes(payload[6:10], "big") if len(payload) >= 10 else 0
                    pmode = payload[5] si len(payload) >= 6 sino mode
                    cuerpo = máscara(respuesta_de_probe(pmode, tamaño), sess, modo, seq, 1)
                    escritor.write(bytes([0]) + len(cuerpo).to_bytes(4, "grande") + cuerpo); await escritor.drain(); continuar
                s = await self.get_session(sess)
                si modo == 1:
                    await s.upload(seq, payload); writer.write(bytes([0]) + (0).to_bytes(4, "big")); await writer.drain()
                elif mode == 2:
                    chunk = await s.download(seq, ln if ln > 0 else 1399, asyncio.get_running_loop().time() + LONGPOLL)
                    self._send_data(writer, sess, mode, seq, chunk); await writer.drain()
                elif mode == 3:
                    chunk_size = 1399; count = 1
                    if len(payload) >= 6: chunk_size = int.from_bytes(payload[0:4], "big"); count = payload[5]
                    fecha límite = asyncio.get_running_loop().time() + LONGPOLL
                    para i en rango(conteo):
                        fragmento = esperar s.download(seq + i, tamaño_fragmento, fecha límite)
                        self._send_data(writer, sess, mode, seq + i, chunk)
                    esperar escritor.drenar()
                elif mode == 4:
                    await s.ack(seq); writer.write(bytes([0]) + (0).to_bytes(4, "big")); await writer.drain()
                de lo contrario: regresar
        excepto Excepción: pasar
        finalmente:
            Intentar: escritor.cerrar()
            excepto Excepción: pasar
    def _send_data(self, writer, sess, mode, seq, data):
        real = len(datos)
        enmascarado = máscara(datos, sesión, modo, secuencia, 1) si datos sino b""
        cuerpo = real.to_bytes(4, "grande") + enmascarado
        escritor.write(bytes([2]) + len(cuerpo).to_bytes(4, "grande") + cuerpo)
    async def servir(self):
        srv = await asyncio.start_server(self.handle, self.host, self.port, backlog=512)
        Asíncrono con srv: await srv.serve_forever()
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

  PYBIN="$(comando -v python3)"
  gato > "$UNIDAD" <<EOF
[Unidad]
Descripción=Servidor BHTTP (puerto $PUERTO)
Después=red.objetivo

[Servicio]
Tipo=simple
ExecStart=$PYBIN $SERVER_PY --host 0.0.0.0 --port $PUERTO --backend-host 127.0.0.1 --backend-port $SSHPORT
Reiniciar=en caso de fallo
ReiniciarSec=3

[Instalar]
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
  demás
    falla "El servicio BHTTP no logró inicializarse."
  fi
  pausa
}

# ==============================================================================
# GESTIÓN DE USUARIOS
# ==============================================================================
crear_usuario() {
  local u="$1" p="$2" dias="$3"
  si id "$u" >/dev/null 2>&1; entonces
    sed -i "/^User: $u /d" "$USERS_FILE" 2>/dev/null
  demás
    useradd -M -s /bin/bash "$u" || return 1
  fi
  local pass_hash; pass_hash="$(openssl passwd -6 "$p" 2>/dev/null)"
  usermod -p "$pass_hash" "$u"
  si [[ "$dias" =~ ^[0-9]+$ ]] && [ "$dias" -gt 0 ]; entonces
    cambio -E "$(fecha -d "+${dias} días" +%Y-%m-%d 2>/dev/null || fecha -v +${dias}d +%Y-%m-%d 2>/dev/null)" "$u" 2>/dev/null
    DIAS_FINAL="${dias} días"
  demás
    cambio -E -1 "$u" 2>/dev/null; DIAS_FINAL="Ilimitado"
  fi
  echo "Usuario: $u | Contraseña: $p | Dias: $DIAS_FINAL" >> "$USERS_FILE"
}

menú_usuarios() {
  mientras sea cierto; hacer
    título
    sección "GESTIÓN DE USUARIOS Y CREDENCIALES"
    echo -e " ${NEON_GREEN}[1]${RESET} Crear usuario rápido"
    echo -e " ${NEON_GREEN}[2]${RESET} Listar credenciales"
    echo -e " ${NEON_GREEN}[3]${RESET} Eliminar usuario"
    echo -e " ${RED}[0]${RESET} Regresar"
    línea
    echo -ne " ${NEON_ORANGE}◆${RESET} Opción: "
    leer -r op
    caso $op en
      1)
        echo -ne " Usuario: "; leer -r nu
        echo -ne "Contraseña:"; leer -r np
        echo -ne " Días de vigencia: "; leer -r nd
        if [ ${#np} -lt 4 ]; then fail "Mínimo 4 caracteres"; else
          crear_usuario "$nu" "$np" "$nd" && ok "¡Usuario creado!"
        fi
        pausa
        ;;
      2)
        sección "LISTA DE USUARIOS"
        [ -f "$USERS_FILE" ] && cat "$USERS_FILE" || info "Sin usuarios"
        pausa
        ;;
      3)
        echo -ne " Usuario a eliminar: "; leer -r nu
        userdel -r "$nu" 2>/dev/null && sed -i "/^User: $nu /d" "$USERS_FILE" 2>/dev/null && ok "Eliminado"
        pausa
        ;;
      0) regresar ;;
    esac
  hecho
}

# ==============================================================================
# ACTIVADOR Y APERTURA MANUAL DE PUERTOS
# ==============================================================================
menú_activar_puertos() {
  mientras sea cierto; hacer
    título
    sección "ACTIVADOR Y APERTURA MANUAL DE PUERTOS (FIREWALL)"
    echo -e " ${WHITE}Abre cualquier puerto TCP adicional (ej. 443, 80, 8989, 8880, etc.)${RESET}"
    línea
    echo -ne " ${NEON_ORANGE}◆${RESET} Ingresa el número de puerto a abrir (Ej. 443): "
    leer -r p_ingresado

    if [[ "$p_ingresado" =~ ^[0-9]+$ ]] && [ "$p_ingresado" -gt 0 ] && [ "$p_ingresado" -le 65535 ]; entonces
      abrir_puerto_sistema "$p_ingresado"
      ok "¡El puerto $p_ingresado ya está abierto y aceptando tráfico!"
    demás
      fallar "Número de puerto inválido."
    fi
    
    eco
    echo -ne " ${SKY}◆${RESET} ¿Quieres abrir otro puerto? (s/n): "
    leer -r otro
    [[ "$otro" =~ ^[sS]$ ]] || break
  hecho
}

# ==============================================================================
#ACTUALIZADOR AUTOMÁTICO DESDE GITHUB
# ==============================================================================
actualizar_script() {
    título
    sección "ACTUALIZADOR AUTOMÁTICO DEL SCRIPT"
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
            dormir 2
            exec sudo bash "$SCRIPT_PATH"
        demás
            fallar "El archivo descargado de GitHub no tiene un formato válido."
        fi
    demás
        fallar "No se pudo conectar con GitHub. Revisa tu conexión."
    fi
    pausa
}

# ==============================================================================
# MENÚ PRINCIPAL
# ==============================================================================
menú_principal() {
  configurar_atajo_adm
  mientras sea cierto; hacer
    título
    estado local
    estado=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactivo")
    [ "$estado" = "activo" ] && estado_color="${NEON_GREEN}ACTIVO 🟢${RESET}" || estado_color="${RED}INACTIVO 🔴${RESET}"

    echo -e " ${WHITE}Estado Servidor:${RESET} ${estado_color} | ${WHITE}Puerto BHTTP:${RESET} ${NEON_GREEN}${PUERTO:-No asignado}${RESET}"
    echo -e " ${WHITE}Comandos Rápidos:${RESET} ${NEON_PINK}adm${RESET} o ${NEON_PINK}admin${RESET}"
    línea
    echo -e " ${NEON_GREEN}[1]${RESET} Instalar / Reinstalar o Cambiar Puerto BHTTP"
    echo -e " ${NEON_GREEN}[2]${RESET} Gestión de Usuarios y Credenciales"
    echo -e " ${NEON_GREEN}[3]${RESET} Activar / Abrir Puerto Personalizado en Firewall"
    echo -e " ${NEON_GREEN}[4]${RESET} Panel de Control de Servicios (Iniciar / Parar / Reiniciar)"
    echo -e " ${NEON_GREEN}[5]${RESET} Diagnóstico General del Sistema"
    echo -e " ${NEON_GREEN}[7]${RESET} Actualizar script desde GitHub"
    echo -e " ${RED}[6]${RESET} Destrucción Total / Desinstalar Script"
    echo -e " ${RED}[0]${RESET} Salir del panel"
    línea
    echo -ne " ${NEON_ORANGE}◆${RESET} Selecciona una opción [1-7, 0]: "
    leer -r opción
    caso $opcion en
      1) instalar_servidor ;;
      2) menú_usuarios ;;
      3) menu_activar_puertos ;;
      4)
        sección "CONTROL DE SERVICIOS"
        echo -e " [1] Iniciar todo"
        echo -e " [2] Detener todo"
        echo -e " [3] Reiniciar todo"
        echo -ne " Selecciona: "
        leer -r st
        caso $st en
          1) systemctl inicio "$SERVICE" "$BADVPN_SERVICE"; ok "Iniciados"; pausa ;;
          2) systemctl detener "$SERVICE" "$BADVPN_SERVICE"; ok "Detenidos"; pausa ;;
          3) reinicio systemctl "$SERVICE" "$BADVPN_SERVICE"; ok "Reiniciados"; pausa ;;
        esac
        ;;
      5)
        título
        sección "DIAGNÓSTICO EN VIVO"
        echo -e " IP Pública : $(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
        echo -e " BHTTP Puerto : ${PUERTO:-No configurado}"
        echo -e " Puerto BadVPN: $BADVPN_PORT"
        echo -e " Atajo 'adm' : Activo y Configurado"
        pausa
        ;;
      7) actualizar_script ;;
      6)
        sección "DESTRUCCIÓN TOTAL"
        echo -ne " ${RED}⚠ ¿Eliminar todo por completo? (s/n): ${RESET}"
        leer -r confirmar
        si [[ "$confirmar" =~ ^[sS]$ ]]; entonces
          systemctl stop "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null
          systemctl disable "$SERVICE" "$BADVPN_SERVICE" 2>/dev/null
          rm -rf "$UNIT" "$BADVPN_UNIT" "$DESTDIR" "$CONFIG_DIR" "$SCRIPT_PATH" "$ADM_BIN" "$ADMIN_BIN" 2>/dev/null
          para rc en /root/.bashrc /root/.zshrc /etc/bash.bashrc; hacer
            [ -f "$rc" ] && sed -i '/alias adm=/d' "$rc" 2>/dev/null && sed -i '/alias admin=/d' "$rc" 2>/dev/null
          hecho
          systemctl daemon-reload
          ok "¡Destrucción total completada!"
          salida 0
        fi
        ;;
      0) echo -e "\n ${NEON_GREEN}¡Hasta luego, Hazael!${RESET}\n"; salir 0;;
      *) falla "Opción inválida"; pausa ;;
    esac
  hecho
}

comprobar_raíz
cargar_config
menú_principal
