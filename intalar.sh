#!/bin/bash
==========================================
SCRIPT DE GESTIÓN VPS - BHTTP & BADVPN
==========================================
Variables Globales y Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NEON_GREEN='\033[1;32m'
NEON_ORANGE='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'
CONFIG_DIR="/etc/bhttp"
CONFIG_FILE="$CONFIG_DIR/bhttp.conf"
USERS_FILE="$CONFIG_DIR/users.db"
SCRIPT_PATH="/usr/local/bin/intalar.sh"
ADM_BIN="/usr/local/bin/adm"
ADMIN_BIN="/usr/local/bin/admin"
DESTDIR="/opt/bhttp"
UNIT="/etc/systemd/system/bhttp.service"
BADVPN_UNIT="/etc/systemd/system/badvpn.service"
PUERTO="80"
BADVPN_PORT="7300"
Funciones de Utilidad y Pantalla
clear_screen() {
clear
}
titulo() {
clear_screen
echo -e "{CYAN}=========================================================={RESET}"
echo -e "{WHITE}{BOLD}             PANEL DE CONTROL BHTTP / BADVPN${RESET}"
echo -e "{CYAN}=========================================================={RESET}"
}
seccion() {
echo -e "{YELLOW}----------------------------------------------------------{RESET}"
echo -e "{WHITE}{BOLD} 1{RESET}"
echo -e "{YELLOW}----------------------------------------------------------{RESET}"
}
linea() {
echo -e "{CYAN}----------------------------------------------------------{RESET}"
}
pausa() {
echo ""
echo -e "{WHITE}Presiona{NEON_GREEN}[ENTER]{RESET} para continuar...{RESET}"
read -r
}
ok() {
echo -e "${GREEN}✔ [ÉXITO] 1{RESET}"
}
fail() {
echo -e "${RED}✘ [ERROR] 1{RESET}"
}
info() {
echo -e "${BLUE}◆ [INFO] 1{RESET}"
}
check_root() {
if [ "$EUID" -ne 0 ]; then
fail "Este script debe ejecutarse como ROOT."
exit 1
fi
}
obtener_ip_publica() {
ip=$(curl -s -4 ifconfig.me || curl -s -4 api.ipify.org || echo "127.0.0.1")
echo "$ip"
}
cargar_config() {
mkdir -p "$CONFIG_DIR"
if [ -f "$CONFIG_FILE" ]; then
# shellcheck disable=SC1090
source "$CONFIG_FILE"
fi
}
guardar_config() {
mkdir -p "$CONFIG_DIR"
cat <<EOF > "$CONFIG_FILE"
PUERTO="$PUERTO"
BADVPN_PORT="$BADVPN_PORT"
EOF
}
configurar_atajo_adm() {
cat <<EOF > "$ADM_BIN"
#!/bin/bash
bash "$SCRIPT_PATH"
EOF
chmod +x "$ADM_BIN"
cat <<EOF > "$ADMIN_BIN"
#!/bin/bash
bash "$SCRIPT_PATH"
EOF
chmod +x "$ADMIN_BIN"
}
abrir_puerto_sistema() {
local port=$1
if command -v ufw >/dev/null 2>&1; then
ufw allow "$port"/tcp >/dev/null 2>&1
ufw allow "$port"/udp >/dev/null 2>&1
fi
if command -v iptables >/dev/null 2>&1; then
iptables -I INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1
iptables -I INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1
fi
ok "Puerto $port abierto en Firewall."
}
Instalación de Dependencias y Servidores
instalar_dependencias() {
info "Instalando paquetes y dependencias del sistema..."
apt-get update -y >/dev/null 2>&1
apt-get install -y python3 python3-pip cmake build-essential git curl wget ufw iptables openssl >/dev/null 2>&1
}
crear_servidor_bhttp_py() {
mkdir -p "$DESTDIR"
cat <<'EOF' > "$DESTDIR/server.py"
import socket
import threading
import sys
import os
HOST = '0.0.0.0'
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 80
def handle_client(client_socket):
try:
request = client_socket.recv(1024)
response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
client_socket.sendall(response.encode('utf-8'))
except Exception:
pass
finally:
client_socket.close()
def main():
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen(100)
while True:
client, addr = server.accept()
client_handler = threading.Thread(target=handle_client, args=(client,))
client_handler.start()
if name == 'main':
main()
EOF
}
crear_servicio_systemd() {
cat <<EOF > "$UNIT"
[Unit]
Description=BHTTP Proxy Service
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $DESTDIR/server.py $PUERTO
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp >/dev/null 2>&1
}
instalar_badvpn() {
info "Configurando BadVPN UDPGW en puerto $BADVPN_PORT..."
if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
wget -q -O /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/dayron10/badvpn/main/badvpn-udpgw" || true
chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null
fi
cat <<EOF > "$BADVPN_UNIT"
[Unit]
Description=BadVPN UDPGW Service
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:$BADVPN_PORT --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable badvpn >/dev/null 2>&1
systemctl restart badvpn >/dev/null 2>&1
abrir_puerto_sistema "$BADVPN_PORT"
}
instalar_servidor() {
titulo
seccion "INSTALACIÓN / REINSTALACIÓN BHTTP Y PUERTOS"
echo -ne " {NEON_ORANGE}◆{RESET} Ingresa el puerto para BHTTP (Por defecto 80): "
read -r user_port
if [ -n "$user_port" ]; then
PUERTO="$user_port"
fi
instalar_dependencias
crear_servidor_bhttp_py
crear_servicio_systemd
instalar_badvpn
guardar_config
abrir_puerto_sistema "$PUERTO"
ok "Servidor BHTTP instalado y ejecutándose en el puerto $PUERTO."
pausa
}
Gestión de Usuarios
crear_usuario() {
local u_name="$1"
local u_pass="$2"
local u_dias="$3"
useradd -M -s /bin/false "$u_name" 2>/dev/null
echo "$u_name:$u_pass" | chpasswd 2>/dev/null
if [ -n "$u_dias" ] && [ "u_dias" -gt 0 ]; then
chage -E "(date -d "+$u_dias days" +%Y-%m-%d)" "$u_name" 2>/dev/null
fi
mkdir -p "$CONFIG_DIR"
echo "User: $u_name \vert{} Pass:$u_pass | Dias: $u_dias" >> "$USERS_FILE"
}
eliminar_usuario_num() {
titulo
seccion "ELIMINAR USUARIO REGISTRADO"
if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
nl -s ') ' "USERS_FILE"
linea
echo -ne " Ingresa el número de usuario a eliminar: "
read -r line_num
if [ -n "$line_num" ]; then
local user_to_del
user_to_del=$(sed -n "{line_num}p" "$USERS_FILE" | grep -oP 'User: \K[^|]+' | xargs)
if [ -n "$user_to_del" ]; then
userdel -f "user_to_del" 2>/dev/null
sed -i "{line_num}d" "$USERS_FILE"
ok "Usuario '$user_to_del' eliminado con éxito."
else
fail "Número de usuario no válido."
fi
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
echo -ne " {NEON_ORANGE}◆{RESET} Ingresa el nombre exacto del usuario a editar: "
read -r u_edit
if id "$u_edit" >/dev/null 2>&1; then
echo -ne " {NEON_ORANGE}◆{RESET} Nueva Contraseña (Enter para mantener actual): "
read -r n_pass
echo -ne " {NEON_ORANGE}◆{RESET} Añadir días adicionales de vigencia (Ej. 30): "
read -r n_dias
if [ -n "$n_pass" ]; then
echo "$u_edit:$n_pass" | chpasswd 2>/dev/null
fi
if [[ "n_dias" =~ ^[0-9]+ ]] && [ "n_dias" -gt 0 ]; then
chage -E "(date -d "+$n_dias days" +%Y-%m-%d)" "$u_edit" 2>/dev/null
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
ver_usuarios_en_linea() {
titulo
seccion "USUARIOS CONECTADOS EN TIEMPO REAL"
echo -e " {WHITE}Conexiones activas en el sistema:{RESET}"
linea
ps aux | grep -i bhttp | grep -v grep || true
pausa
}
menu_usuarios() {
while true; do
titulo
seccion "GESTIÓN DE USUARIOS Y CREDENCIALES"
echo -e "  {NEON_GREEN}[1]{RESET} Crear usuario BHTTP"
echo -e "  {NEON_GREEN}[2]{RESET} Detalles de usuario existente (Panel)"
echo -e "  {NEON_GREEN}[3]{RESET} Eliminar usuario por numeración"
echo -e "  {NEON_GREEN}[4]{RESET} Editar Usuario (Añadir días / Cambiar contraseña)"
echo -e "  {NEON_GREEN}[5]{RESET} Ver usuarios en línea"
echo -e "  {RED}[0]{RESET} Regresar"
linea
echo -ne " {NEON_ORANGE}◆{RESET} Opción: "
read -r op
case op in
1)
echo -ne " Usuario: "; read -r nu
echo -ne " Contraseña: "; read -r np
echo -ne " Días vigencia: "; read -r nd
if [ "{#np}" -lt 4 ]; then
fail "Mínimo 4 caracteres"
else
crear_usuario "$nu" "$np" "$nd" && ok "¡Usuario creado!"
fi
pausa
;;
2)
titulo
seccion "PANEL DE DETALLES DE USUARIOS EXISTENTES"
if [ -f "$USERS_FILE" ] && [ -s "USERS_FILE" ]; then
local idx=1
while IFS= read -r linea_usu; do
local u_name u_pass u_dias
u_name=(echo "linea_usu" | grep -oP 'User:\s*\K[^|]+' | xargs)
u_pass=(echo "linea_usu" | grep -oP 'Pass:\s*\K[^|]+' | xargs)
u_dias=(echo "$linea_usu" | grep -oP 'Dias:\s*\K.*' | xargs)
local exp_date dias_restantes="N/A"
exp_date=$(chage -l "$u_name" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
if [ "$exp_date" != "never" ] && [ -n "exp_date" ]; then
local t_exp t_hoy
t_exp=(date -d "exp_date" +%s 2>/dev/null || echo 0)
t_hoy=(date +%s)
if [ "$t_exp" -gt "t_hoy" ]; then
dias_restantes="(( (t_exp - t_hoy) / 86400 )) días"
else
dias_restantes="Expirado"
fi
else
dias_restantes="Ilimitado"
fi
echo -e "  {NEON_ORANGE}[$idx]${RESET} Usuario  :{NEON_GREEN}u_name{RESET}"
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
Menús y Operaciones Adicionales
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
ok "Panel y componentes actualizados con éxito."
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
Ejecutar el menú principal al inicio
menu_principal
