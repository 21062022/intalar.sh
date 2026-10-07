#!/bin/bash
# ════════════════════════════════════════════════════════════
# HAZEL MORENO MULTI SCRIPT - BHTTP & BADVPN & PROXY PYTHON
# ════════════════════════════════════════════════════════════

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Variables globales
SCRIPT_NAME="HAZEL MORENO MULTI SCRIPT"
SCRIPT_VERSION="3.0-FIXED"
BHTTP_PORT="8080"
BADVPN_PORT="7300"
WSPY_PORT="80"
WSPY_SSH_PORT="22"
WSPY_DIR="/usr/local/lib/ws-proxy"
WSPY_SCRIPT="$WSPY_DIR/ws-proxy.py"
WSPY_SERVICE="/etc/systemd/system/ws-proxy.service"
WSPY_CONF_DIR="/etc/ws-proxy"

# ════════════════════════════════════════════════════════════
# FUNCIONES UTILITARIAS
# ════════════════════════════════════════════════════════════

msg() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script debe ejecutarse como root"
        exit 1
    fi
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

verificar_estado_servicio() {
    local servicio=$1
    if systemctl is-active --quiet "$servicio" 2>/dev/null; then
        echo "ACTIVE"
    elif systemctl list-unit-files | grep -q "^$servicio"; then
        echo "DETENIDO"
    else
        echo "NO_INSTALADO"
    fi
}

# ════════════════════════════════════════════════════════════
# SCRIPT PYTHON WEBSOCKET PROXY (CORREGIDO)
# ════════════════════════════════════════════════════════════

crear_script_python_proxy() {
    msg "Creando script Python del proxy WebSocket..."
    
    mkdir -p "$WSPY_DIR"
    mkdir -p "$WSPY_CONF_DIR"
    
    cat > "$WSPY_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
# WebSocket to SSH Proxy - Compatible con HTTP Custom
# Corregido: Detecta correctamente WebSocket vs HTTP normal

import socket
import select
import threading
import sys
import logging
import re
import hashlib
import base64
import struct
import os

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuración
LISTEN_PORT = int(os.environ.get('WS_PORT', 80))
SSH_HOST = os.environ.get('SSH_HOST', '127.0.0.1')
SSH_PORT = int(os.environ.get('SSH_PORT', 22))

# GUID para WebSocket
WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

def es_websocket(headers):
    """Detecta si es una petición WebSocket válida"""
    connection = headers.get('connection', '').lower()
    upgrade = headers.get('upgrade', '').lower()
    
    # Debe tener Upgrade: websocket
    if 'websocket' not in upgrade:
        return False
    
    # Connection debe contener Upgrade
    if 'upgrade' not in connection:
        return False
    
    return True

def parsear_headers(data):
    """Parsea headers HTTP"""
    headers = {}
    try:
        lines = data.decode('utf-8', errors='ignore').split('\r\n')
        for line in lines[1:]:
            if ':' in line:
                key, value = line.split(':', 1)
                headers[key.strip().lower()] = value.strip()
    except Exception as e:
        logger.error(f"Error parseando headers: {e}")
    return headers

def generar_respuesta_websocket(key):
    """Genera la respuesta de handshake WebSocket"""
    accept = base64.b64encode(
        hashlib.sha1((key + WS_GUID).encode()).digest()
    ).decode()
    
    response = (
        "HTTP/1.1 101 Switching Protocols\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        f"Sec-WebSocket-Accept: {accept}\r\n"
        "\r\n"
    )
    return response.encode()

def generar_respuesta_http():
    """Genera respuesta HTTP 200 para conexiones normales (HTTP Custom)"""
    body = "Connection established"
    response = (
        "HTTP/1.1 200 Connection established\r\n"
        "Content-Type: text/plain\r\n"
        f"Content-Length: {len(body)}\r\n"
        "Connection: close\r\n"
        "\r\n"
        f"{body}"
    )
    return response.encode()

def generar_error_400():
    """Genera error 400 Bad Request"""
    body = "Bad Request"
    response = (
        "HTTP/1.1 400 Bad Request\r\n"
        "Content-Type: text/plain\r\n"
        f"Content-Length: {len(body)}\r\n"
        "Connection: close\r\n"
        "\r\n"
        f"{body}"
    )
    return response.encode()

def decode_websocket_frame(data):
    """Decodifica un frame WebSocket"""
    if len(data) < 2:
        return None, None
    
    opcode = data[0] & 0x0f
    masked = (data[1] & 0x80) != 0
    payload_len = data[1] & 0x7f
    
    if payload_len == 126:
        if len(data) < 4:
            return None, None
        payload_len = struct.unpack('>H', data[2:4])[0]
        mask_start = 4
    elif payload_len == 127:
        if len(data) < 10:
            return None, None
        payload_len = struct.unpack('>Q', data[2:10])[0]
        mask_start = 10
    else:
        mask_start = 2
    
    if masked:
        if len(data) < mask_start + 4:
            return None, None
        masks = data[mask_start:mask_start + 4]
        payload_start = mask_start + 4
        payload = bytearray()
        for i in range(payload_len):
            if payload_start + i < len(data):
                payload.append(data[payload_start + i] ^ masks[i % 4])
        return bytes(payload), opcode
    else:
        payload_start = mask_start
        return data[payload_start:payload_start + payload_len], opcode

def encode_websocket_frame(data, opcode=0x02):
    """Codifica datos en frame WebSocket (binary por defecto)"""
    header = bytearray()
    header.append(0x80 | opcode)  # FIN + opcode
    
    payload_len = len(data)
    if payload_len < 126:
        header.append(payload_len)
    elif payload_len < 65536:
        header.append(126)
        header.extend(struct.pack('>H', payload_len))
    else:
        header.append(127)
        header.extend(struct.pack('>Q', payload_len))
    
    return bytes(header) + data

def manejar_cliente(client_socket, addr):
    """Maneja un cliente entrante"""
    logger.info(f"Nueva conexión desde {addr}")
    
    try:
        # Recibir headers HTTP
        data = b""
        while b"\r\n\r\n" not in data:
            chunk = client_socket.recv(1024)
            if not chunk:
                logger.warning(f"Conexión cerrada por {addr} antes de headers")
                return
            data += chunk
            if len(data) > 8192:
                logger.error(f"Headers demasiado grandes de {addr}")
                client_socket.send(generar_error_400())
                return
        
        # Separar headers
        header_end = data.find(b"\r\n\r\n")
        headers_data = data[:header_end]
        remaining_data = data[header_end + 4:]
        
        # Parsear headers
        headers = parsear_headers(headers_data)
        logger.info(f"Headers recibidos: {dict(headers)}")
        
        # Detectar si es WebSocket
        if es_websocket(headers):
            # Es WebSocket
            ws_key = headers.get('sec-websocket-key', '')
            if not ws_key:
                logger.error(f"No hay Sec-WebSocket-Key de {addr}")
                client_socket.send(generar_error_400())
                return
            
            logger.info(f"Handshake WebSocket de {addr}")
            client_socket.send(generar_respuesta_websocket(ws_key))
            
            # Conectar a SSH
            ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            ssh_socket.settimeout(30)
            ssh_socket.connect((SSH_HOST, SSH_PORT))
            logger.info(f"Conectado a SSH {SSH_HOST}:{SSH_PORT} para {addr}")
            
            # Enviar datos pendientes si los hay (raro en WS)
            if remaining_data:
                ssh_socket.send(remaining_data)
            
            # Modo WebSocket: decodificar/encodificar frames
            manejar_websocket(client_socket, ssh_socket, addr)
            
        else:
            # Es HTTP normal (HTTP Custom)
            logger.info(f"Conexión HTTP normal de {addr}")
            client_socket.send(generar_respuesta_http())
            
            # Conectar a SSH
            ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            ssh_socket.settimeout(30)
            ssh_socket.connect((SSH_HOST, SSH_PORT))
            logger.info(f"Conectado a SSH {SSH_HOST}:{SSH_PORT} para {addr}")
            
            # Enviar datos pendientes
            if remaining_data:
                ssh_socket.send(remaining_data)
            
            # Modo transparente: tunnel directo
            manejar_tunnel(client_socket, ssh_socket, addr)
            
    except socket.timeout:
        logger.warning(f"Timeout en conexión {addr}")
    except Exception as e:
        logger.error(f"Error manejando cliente {addr}: {e}")
    finally:
        try:
            client_socket.close()
        except:
            pass
        logger.info(f"Conexión cerrada {addr}")

def manejar_websocket(client_socket, ssh_socket, addr):
    """Maneja tunnel WebSocket con framing"""
    try:
        while True:
            readable, _, _ = select.select([client_socket, ssh_socket], [], [], 30)
            
            if not readable:
                continue
            
            for sock in readable:
                if sock is client_socket:
                    # Datos del cliente (WebSocket)
                    data = sock.recv(4096)
                    if not data:
                        return
                    
                    # Decodificar frame WebSocket
                    payload, opcode = decode_websocket_frame(data)
                    if payload is None:
                        continue
                    
                    if opcode == 0x08:  # Close
                        logger.info(f"WebSocket close de {addr}")
                        return
                    
                    if opcode in (0x01, 0x02):  # Text o Binary
                        ssh_socket.send(payload)
                        
                elif sock is ssh_socket:
                    # Datos de SSH
                    data = sock.recv(4096)
                    if not data:
                        return
                    
                    # Encodificar en frame WebSocket
                    framed = encode_websocket_frame(data, 0x02)
                    client_socket.send(framed)
                    
    except Exception as e:
        logger.error(f"Error en tunnel WebSocket {addr}: {e}")
    finally:
        try:
            ssh_socket.close()
        except:
            pass

def manejar_tunnel(client_socket, ssh_socket, addr):
    """Maneja tunnel transparente (HTTP Custom)"""
    try:
        while True:
            readable, _, _ = select.select([client_socket, ssh_socket], [], [], 30)
            
            if not readable:
                continue
            
            for sock in readable:
                data = sock.recv(4096)
                if not data:
                    return
                
                if sock is client_socket:
                    ssh_socket.send(data)
                else:
                    client_socket.send(data)
                    
    except Exception as e:
        logger.error(f"Error en tunnel {addr}: {e}")
    finally:
        try:
            ssh_socket.close()
        except:
            pass

def main():
    logger.info(f"Iniciando WebSocket Proxy en puerto {LISTEN_PORT}")
    logger.info(f"Redirigiendo a SSH {SSH_HOST}:{SSH_PORT}")
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind(('0.0.0.0', LISTEN_PORT))
        server.listen(100)
        logger.info("Servidor escuchando...")
        
        while True:
            client, addr = server.accept()
            client.settimeout(60)
            thread = threading.Thread(target=manejar_cliente, args=(client, addr))
            thread.daemon = True
            thread.start()
            
    except KeyboardInterrupt:
        logger.info("Servidor detenido")
    except Exception as e:
        logger.error(f"Error en servidor: {e}")
    finally:
        server.close()

if __name__ == "__main__":
    main()
PYTHON_EOF

    chmod +x "$WSPY_SCRIPT"
    success "Script Python creado en $WSPY_SCRIPT"
}

crear_servicio_systemd() {
    msg "Creando servicio systemd..."
    
    cat > "$WSPY_SERVICE" << EOF
[Unit]
Description=WebSocket to SSH Proxy
After=network.target

[Service]
Type=simple
Environment=WS_PORT=$WSPY_PORT
Environment=SSH_HOST=127.0.0.1
Environment=SSH_PORT=$WSPY_SSH_PORT
ExecStart=/usr/bin/python3 $WSPY_SCRIPT
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    success "Servicio systemd creado"
}

# ════════════════════════════════════════════════════════════
# MENÚ PROXY PYTHON (CORREGIDO)
# ════════════════════════════════════════════════════════════

menu_proxy_python() {
    while true; do
        clear
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}           PROXY WEBSOCKET PYTHON${NC}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        # Verificar estado real
        local estado=$(verificar_estado_servicio "ws-proxy")
        local estado_color="${RED}"
        local estado_texto="NO INSTALADO"
        
        if [[ "$estado" == "ACTIVE" ]]; then
            estado_color="${GREEN}"
            estado_texto="ACTIVO"
        elif [[ "$estado" == "DETENIDO" ]]; then
            estado_color="${YELLOW}"
            estado_texto="DETENIDO"
        fi
        
        echo -e "\n${CYAN}Estado del servicio:${NC} ${estado_color}${estado_texto}${NC}"
        
        if [[ "$estado" == "ACTIVE" ]]; then
            local puerto=$(systemctl show ws-proxy -p Environment 2>/dev/null | grep -o 'WS_PORT=[0-9]*' | cut -d= -f2)
            echo -e "${CYAN}Puerto:${NC} ${puerto:-$WSPY_PORT}"
            echo -e "${CYAN}Redirige a:${NC} 127.0.0.1:$WSPY_SSH_PORT (SSH)"
        fi
        
        echo -e "\n${YELLOW}[1]${NC} Instalar Proxy WebSocket"
        echo -e "${YELLOW}[2]${NC} Iniciar Servicio"
        echo -e "${YELLOW}[3]${NC} Detener Servicio"
        echo -e "${YELLOW}[4]${NC} Reiniciar Servicio"
        echo -e "${YELLOW}[5]${NC} Ver Logs"
        echo -e "${YELLOW}[6]${NC} Desinstalar"
        echo -e "${YELLOW}[0]${NC} Volver al Menú Principal"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        read -p "Seleccione una opción: " opcion
        
        case $opcion in
            1)
                if [[ "$estado" != "NO_INSTALADO" ]]; then
                    warning "El proxy ya está instalado. Use 'Reinstalar' o desinstale primero."
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                read -p "Puerto para WebSocket [${WSPY_PORT}]: " input_port
                WSPY_PORT=${input_port:-$WSPY_PORT}
                
                read -p "Puerto SSH local [${WSPY_SSH_PORT}]: " input_ssh
                WSPY_SSH_PORT=${input_ssh:-$WSPY_SSH_PORT}
                
                # Verificar que el puerto no esté ocupado
                if ss -tlnp | grep -q ":$WSPY_PORT "; then
                    error "El puerto $WSPY_PORT ya está en uso"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                crear_script_python_proxy
                crear_servicio_systemd
                
                systemctl enable ws-proxy
                systemctl start ws-proxy
                
                sleep 2
                
                if systemctl is-active --quiet ws-proxy; then
                    success "Proxy WebSocket instalado y activado correctamente"
                    success "Puerto: $WSPY_PORT -> SSH $WSPY_SSH_PORT"
                    success "Compatible con HTTP Custom"
                else
                    error "El servicio no se pudo iniciar. Verifique: journalctl -u ws-proxy -n 50"
                fi
                read -p "Presione Enter para continuar..."
                ;;
            2)
                if [[ "$estado" == "NO_INSTALADO" ]]; then
                    error "El proxy no está instalado. Instálelo primero (opción 1)"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                if [[ "$estado" == "ACTIVE" ]]; then
                    warning "El servicio ya está activo"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                systemctl start ws-proxy
                sleep 2
                
                if systemctl is-active --quiet ws-proxy; then
                    success "Servicio iniciado correctamente"
                else
                    error "No se pudo iniciar el servicio"
                    echo -e "${CYAN}Últimos logs:${NC}"
                    journalctl -u ws-proxy -n 20 --no-pager
                fi
                read -p "Presione Enter para continuar..."
                ;;
            3)
                if [[ "$estado" != "ACTIVE" ]]; then
                    warning "El servicio no está activo"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                systemctl stop ws-proxy
                success "Servicio detenido"
                read -p "Presione Enter para continuar..."
                ;;
            4)
                if [[ "$estado" == "NO_INSTALADO" ]]; then
                    error "El proxy no está instalado"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                systemctl restart ws-proxy
                sleep 2
                
                if systemctl is-active --quiet ws-proxy; then
                    success "Servicio reiniciado correctamente"
                else
                    error "Error al reiniciar"
                fi
                read -p "Presione Enter para continuar..."
                ;;
            5)
                if [[ "$estado" == "NO_INSTALADO" ]]; then
                    error "El proxy no está instalado"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                echo -e "${CYAN}Logs del servicio (Ctrl+C para salir):${NC}"
                journalctl -u ws-proxy -f --no-pager
                ;;
            6)
                if [[ "$estado" == "NO_INSTALADO" ]]; then
                    error "No hay nada que desinstalar"
                    read -p "Presione Enter para continuar..."
                    continue
                fi
                
                read -p "¿Está seguro de desinstalar el Proxy WebSocket? [s/N]: " confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    systemctl stop ws-proxy 2>/dev/null
                    systemctl disable ws-proxy 2>/dev/null
                    rm -f "$WSPY_SERVICE"
                    rm -rf "$WSPY_DIR"
                    rm -rf "$WSPY_CONF_DIR"
                    systemctl daemon-reload
                    success "Proxy WebSocket desinstalado completamente"
                fi
                read -p "Presione Enter para continuar..."
                ;;
            0)
                break
                ;;
            *)
                error "Opción inválida"
                sleep 1
                ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
# DESTRUCCIÓN TOTAL (CORREGIDA)
# ════════════════════════════════════════════════════════════

destruir_script_total() {
    clear
    echo -e "${RED}══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}              DESTRUCCIÓN TOTAL DEL SISTEMA${NC}"
    echo -e "${RED}══════════════════════════════════════════════════════════${NC}"
    echo -e "\n${YELLOW}Esto eliminará:${NC}"
    echo -e "  - Todos los usuarios SSH creados por el script"
    echo -e "  - BHTTP (Banner HTTP)"
    echo -e "  - BadVPN (UDPGW)"
    echo -e "  - ${RED}Proxy WebSocket Python${NC}"
    echo -e "  - Configuraciones y servicios systemd"
    echo -e "  - Reglas de firewall asociadas"
    echo -e "\n${RED}¡ESTA ACCIÓN NO SE PUEDE DESHACER!${NC}"
    
    read -p "¿Está COMPLETAMENTE SEGURO? Escriba 'DESTRUIR' para confirmar: " confirm
    
    if [[ "$confirm" != "DESTRUIR" ]]; then
        warning "Operación cancelada"
        read -p "Presione Enter para continuar..."
        return
    fi
    
    msg "Iniciando destrucción total..."
    
    # Detener y eliminar Proxy WebSocket Python
    msg "Eliminando Proxy WebSocket Python..."
    systemctl stop ws-proxy 2>/dev/null
    systemctl disable ws-proxy 2>/dev/null
    rm -f "$WSPY_SERVICE"
    rm -rf "$WSPY_DIR"
    rm -rf "$WSPY_CONF_DIR"
    
    # Detener BHTTP
    msg "Eliminando BHTTP..."
    systemctl stop bhttp 2>/dev/null
    systemctl disable bhttp 2>/dev/null
    rm -f /etc/systemd/system/bhttp.service
    rm -f /usr/local/bin/bhttp-server
    
    # Detener BadVPN
    msg "Eliminando BadVPN..."
    systemctl stop badvpn 2>/dev/null
    systemctl disable badvpn 2>/dev/null
    rm -f /etc/systemd/system/badvpn.service
    rm -f /usr/local/bin/badvpn-udpgw
    
    # Eliminar usuarios creados (los que tienen /bin/false o similares)
    msg "Eliminando usuarios del script..."
    while IFS=':' read -r user _ _ _ _ home shell; do
        if [[ "$shell" == "/bin/false" ]] || [[ "$shell" == "/usr/sbin/nologin" ]]; then
            if [[ "$home" == "/home/"* ]]; then
                userdel -r "$user" 2>/dev/null && echo "Eliminado: $user"
            fi
        fi
    done < /etc/passwd
    
    # Limpiar firewall
    msg "Limpiando reglas de firewall..."
    iptables -F 2>/dev/null
    iptables -X 2>/dev/null
    iptables -t nat -F 2>/dev/null
    iptables -t nat -X 2>/dev/null
    
    # Recargar systemd
    systemctl daemon-reload
    
    success "Destrucción total completada"
    echo -e "\n${GREEN}Todos los componentes han sido eliminados${NC}"
    read -p "Presione Enter para salir..."
    exit 0
}

# ════════════════════════════════════════════════════════════
# FUNCIONES BHTTP Y BADVPN
# ════════════════════════════════════════════════════════════

instalar_bhttp() {
    msg "Instalando BHTTP (Banner HTTP)..."
    
    cat > /usr/local/bin/bhttp-server << 'EOF'
#!/bin/bash
PORT=${1:-8080}
while true; do
    { echo -ne "HTTP/1.1 200 OK\r\nContent-Length: 23\r\n\r\nHAZEL MORENO MULTI SCRIPT"; } | nc -l -p $PORT -q 1
done
EOF
    chmod +x /usr/local/bin/bhttp-server
    
    cat > /etc/systemd/system/bhttp.service << EOF
[Unit]
Description=Banner HTTP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/bhttp-server $BHTTP_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable bhttp
    systemctl start bhttp
    
    success "BHTTP instalado en puerto $BHTTP_PORT"
}

instalar_badvpn() {
    msg "Instalando BadVPN UDP Gateway..."
    
    # Descargar e instalar badvpn
    apt-get update -qq
    apt-get install -y -qq cmake gcc make || true
    
    cd /tmp
    wget -q https://github.com/ambrop72/badvpn/archive/refs/tags/1.999.130.tar.gz
    tar -xzf 1.999.130.tar.gz
    cd badvpn-1.999.130
    cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
    make >/dev/null 2>&1
    cp badvpn-udpgw/badvpn-udpgw /usr/local/bin/
    chmod +x /usr/local/bin/badvpn-udpgw
    
    cat > /etc/systemd/system/badvpn.service << EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 512
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable badvpn
    systemctl start badvpn
    
    rm -rf /tmp/badvpn-*
    
    success "BadVPN instalado en puerto $BADVPN_PORT"
}

menu_bhttp() {
    while true; do
        clear
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}              GESTIÓN BHTTP${NC}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        local estado=$(verificar_estado_servicio "bhttp")
        local color="${RED}"
        local texto="NO INSTALADO"
        
        if [[ "$estado" == "ACTIVE" ]]; then
            color="${GREEN}"
            texto="ACTIVO"
        elif [[ "$estado" == "DETENIDO" ]]; then
            color="${YELLOW}"
            texto="DETENIDO"
        fi
        
        echo -e "\n${CYAN}Estado:${NC} ${color}${texto}${NC}"
        echo -e "\n${YELLOW}[1]${NC} Instalar/Iniciar"
        echo -e "${YELLOW}[2]${NC} Detener"
        echo -e "${YELLOW}[3]${NC} Reiniciar"
        echo -e "${YELLOW}[0]${NC} Volver"
        
        read -p "Seleccione: " op
        
        case $op in
            1)
                if [[ "$estado" == "NO_INSTALADO" ]]; then
                    instalar_bhttp
                else
                    systemctl start bhttp
                    success "Iniciado"
                fi
                read -p "Presione Enter..."
                ;;
            2)
                systemctl stop bhttp
                success "Detenido"
                read -p "Presione Enter..."
                ;;
            3)
                systemctl restart bhttp
                success "Reiniciado"
                read -p "Presione Enter..."
                ;;
            0) break ;;
        esac
    done
}

menu_badvpn() {
    while true; do
        clear
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}              GESTIÓN BADVPN${NC}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        local estado=$(verificar_estado_servicio "badvpn")
        local color="${RED}"
        local texto="NO INSTALADO"
        
        if [[ "$estado" == "ACTIVE" ]]; then
            color="${GREEN}"
            texto="ACTIVO"
        elif [[ "$estado" == "DETENIDO" ]]; then
            color="${YELLOW}"
            texto="DETENIDO"
        fi
        
        echo -e "\n${CYAN}Estado:${NC} ${color}${texto}${NC}"
        echo -e "\n${YELLOW}[1]${NC} Instalar/Iniciar"
        echo -e "${YELLOW}[2]${NC} Detener"
        echo -e "${YELLOW}[3]${NC} Reiniciar"
        echo -e "${YELLOW}[0]${NC} Volver"
        
        read -p "Seleccione: " op
        
        case $op in
            1)
                if [[ "$estado" == "NO_INSTALADO" ]]; then
                    instalar_badvpn
                else
                    systemctl start badvpn
                    success "Iniciado"
                fi
                read -p "Presione Enter..."
                ;;
            2)
                systemctl stop badvpn
                success "Detenido"
                read -p "Presione Enter..."
                ;;
            3)
                systemctl restart badvpn
                success "Reiniciado"
                read -p "Presione Enter..."
                ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
# GESTIÓN DE USUARIOS
# ════════════════════════════════════════════════════════════

menu_usuarios() {
    while true; do
        clear
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}           GESTIÓN DE USUARIOS SSH${NC}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        echo -e "\n${YELLOW}[1]${NC} Crear usuario"
        echo -e "${YELLOW}[2]${NC} Eliminar usuario"
        echo -e "${YELLOW}[3]${NC} Listar usuarios"
        echo -e "${YELLOW}[4]${NC} Monitorear conexiones"
        echo -e "${YELLOW}[0]${NC} Volver"
        
        read -p "Seleccione: " op
        
        case $op in
            1)
                read -p "Nombre de usuario: " username
                read -p "Contraseña: " password
                read -p "Días de validez: " dias
                
                useradd -m -s /bin/false "$username" 2>/dev/null || usermod -s /bin/false "$username"
                echo "$username:$password" | chpasswd
                chage -M "$dias" "$username"
                
                success "Usuario $username creado (expira en $dias días)"
                read -p "Presione Enter..."
                ;;
            2)
                read -p "Usuario a eliminar: " username
                userdel -r "$username" 2>/dev/null && success "Eliminado" || error "No existe"
                read -p "Presione Enter..."
                ;;
            3)
                echo -e "\n${CYAN}Usuarios del sistema:${NC}"
                awk -F: '$3 >= 1000 && $3 < 65534 {print "  Usuario: " $1 " - Shell: " $7}' /etc/passwd
                read -p "Presione Enter..."
                ;;
            4)
                clear
                echo -e "${CYAN}Conexiones activas (Ctrl+C para salir):${NC}"
                while true; do
                    clear
                    echo "=== $(date) ==="
                    ss -tn | grep -E ':22|:443' | grep ESTAB
                    sleep 2
                done
                ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
# PANEL DE ESTADO
# ════════════════════════════════════════════════════════════

mostrar_panel() {
    while true; do
        clear
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}              PANEL DE ESTADO DEL SISTEMA${NC}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        # Estado de servicios
        local bhttp_estado=$(verificar_estado_servicio "bhttp")
        local badvpn_estado=$(verificar_estado_servicio "badvpn")
        local wspy_estado=$(verificar_estado_servicio "ws-proxy")
        
        echo -e "\n${CYAN}Servicios:${NC}"
        
        # BHTTP
        if [[ "$bhttp_estado" == "ACTIVE" ]]; then
            echo -e "  ${GREEN}●${NC} BHTTP (Banner)     - Puerto $BHTTP_PORT - ${GREEN}ACTIVO${NC}"
        elif [[ "$bhttp_estado" == "DETENIDO" ]]; then
            echo -e "  ${YELLOW}●${NC} BHTTP (Banner)     - ${YELLOW}DETENIDO${NC}"
        else
            echo -e "  ${RED}●${NC} BHTTP (Banner)     - ${RED}NO INSTALADO${NC}"
        fi
        
        # BadVPN
        if [[ "$badvpn_estado" == "ACTIVE" ]]; then
            echo -e "  ${GREEN}●${NC} BadVPN (UDP)       - Puerto $BADVPN_PORT - ${GREEN}ACTIVO${NC}"
        elif [[ "$badvpn_estado" == "DETENIDO" ]]; then
            echo -e "  ${YELLOW}●${NC} BadVPN (UDP)       - ${YELLOW}DETENIDO${NC}"
        else
            echo -e "  ${RED}●${NC} BadVPN (UDP)       - ${RED}NO INSTALADO${NC}"
        fi
        
        # WebSocket Proxy
        if [[ "$wspy_estado" == "ACTIVE" ]]; then
            local wspy_puerto=$(systemctl show ws-proxy -p Environment 2>/dev/null | grep -o 'WS_PORT=[0-9]*' | cut -d= -f2)
            echo -e "  ${GREEN}●${NC} WS→SSH (Python)    - Puerto ${wspy_puerto:-$WSPY_PORT} → 127.0.0.1:$WSPY_SSH_PORT - ${GREEN}ACTIVO${NC}"
        elif [[ "$wspy_estado" == "DETENIDO" ]]; then
            echo -e "  ${YELLOW}●${NC} WS→SSH (Python)    - ${YELLOW}DETENIDO${NC}"
        else
            echo -e "  ${RED}●${NC} WS→SSH (Python)    - ${RED}NO INSTALADO${NC}"
        fi
        
        # Estadísticas
        echo -e "\n${CYAN}Estadísticas:${NC}"
        echo -e "  Usuarios SSH: $(grep -c '/bin/false' /etc/passwd || echo '0')"
        echo -e "  Conexiones activas: $(ss -tn 2>/dev/null | grep ESTAB | wc -l)"
        echo -e "  Uso de RAM: $(free -m 2>/dev/null | awk 'NR==2{printf "%s/%sMB (%.2f%%)", $3,$2,$3*100/$2}' || echo 'N/A')"
        echo -e "  Uso de CPU: $(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo 'N/A')%"
        
        echo -e "\n${YELLOW}[R]${NC} Refrescar | ${YELLOW}[0]${NC} Volver"
        
        read -t 5 -n 1 op || true
        
        case $op in
            0) break ;;
            r|R) continue ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
# MENÚ PRINCIPAL
# ════════════════════════════════════════════════════════════

menu_principal() {
    while true; do
        clear
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}     $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
        echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        
        echo -e "\n${CYAN}OPCIONES PRINCIPALES:${NC}"
        echo -e "${YELLOW}[1]${NC} Gestión de Usuarios SSH"
        echo -e "${YELLOW}[2]${NC} Gestionar BHTTP (Banner HTTP)"
        echo -e "${YELLOW}[3]${NC} Gestionar BadVPN (UDP Gateway)"
        echo -e "${YELLOW}[4]${NC} Panel de Estado"
        echo -e "${YELLOW}[5]${NC} Optimizar VPS (BBR, Swap, etc)"
        echo -e ""
        echo -e "${CYAN}OPCIONES AVANZADAS:${NC}"
        echo -e "${YELLOW}[11]${NC} ${RED}DESTRUIR TODO${NC} (Eliminar script completamente)"
        echo -e "${YELLOW}[12]${NC} Proxy WebSocket Python (HTTP Custom compatible)"
        echo -e ""
        echo -e "${YELLOW}[0]${NC} Salir"
        
        echo -e "\n${MAGENTA}══════════════════════════════════════════════════════════${NC}"
        read -p "Seleccione una opción: " opcion
        
        case $opcion in
            1) menu_usuarios ;;
            2) menu_bhttp ;;
            3) menu_badvpn ;;
            4) mostrar_panel ;;
            5) menu_optimizar_vps ;;
            11) destruir_script_total ;;
            12) menu_proxy_python ;;
            0) 
                clear
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                error "Opción inválida"
                sleep 1
                ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
# OPTIMIZACIÓN VPS
# ════════════════════════════════════════════════════════════

menu_optimizar_vps() {
    clear
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              OPTIMIZACIÓN VPS${NC}"
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}[1]${NC} Activar BBR (mejor velocidad)"
    echo -e "${YELLOW}[2]${NC} Crear Swap (2GB)"
    echo -e "${YELLOW}[3]${NC} Optimizar kernel (TCP tuning)"
    echo -e "${YELLOW}[0]${NC} Volver"
    
    read -p "Seleccione: " op
    
    case $op in
        1)
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p >/dev/null 2>&1
            success "BBR activado"
            ;;
        2)
            fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1024 count=2097152
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo "/swapfile none swap sw 0 0" >> /etc/fstab
            success "Swap de 2GB creado"
            ;;
        3)
            cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_syn_backlog = 65536
EOF
            sysctl -p >/dev/null 2>&1
            success "Kernel optimizado"
            ;;
        0) return ;;
    esac
    
    read -p "Presione Enter..."
}

# ════════════════════════════════════════════════════════════
# INICIO
# ════════════════════════════════════════════════════════════

check_root
menu_principal
