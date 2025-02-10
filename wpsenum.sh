#!/bin/bash

# Solicitar la URL al inicio del script
read -p "Ingrese la URL de la web a analizar: " url

# Validar que la URL no esté vacía
if [[ -z "$url" ]]; then
    echo "[❌] Error: No ingresaste ninguna URL. Saliendo..."
    exit 1
fi

echo "[✔] URL establecida: $url"
sleep 2.0
clear

# Función para ejecutar whatweb y verificar WordPress
ejecutar_whatweb() {
    clear
    echo "Escaneando $url con whatweb..."
    
    resultado=$(whatweb "$url")
    
    echo "--------------------------------------"
    echo "$resultado"
    echo "--------------------------------------"

    if echo "$resultado" | grep -qi "WordPress"; then
        echo "[+] El sitio web usa WordPress."
    else
        echo "[-] No se detectó WordPress en la URL proporcionada."
    fi
    echo "--------------------------------------"
    read -p "Presione ENTER para volver al menú..."
    clear
}

# Función para buscar usuarios en WordPress
buscar_usuarios_wp() {
    clear
    echo "Buscando usuarios en $url ..."

    resultado1=$(curl -s -I -X GET "$url/?author=1" | grep -i "location" | awk -F '/' '{print $(NF-1)}')
    resultado2=$(curl -s "$url/wp-json/wp/v2/users" | grep -o '"name":"[^"]*"' | awk -F ':' '{print $2}' | tr -d '"' | sort -u)

    echo "--------------------------------------"
    if [ -n "$resultado1" ] || [ -n "$resultado2" ]; then
        echo "[+] Usuarios encontrados:"
        if [ -n "$resultado1" ]; then echo " - $resultado1"; fi
        if [ -n "$resultado2" ]; then echo "$resultado2" | awk '{print " - " $0}'; fi
    else
        echo "[-] No se encontraron usuarios en la web."
    fi
    echo "--------------------------------------"
    read -p "Presione ENTER para volver al menú..."
    clear
}

# Función para verificar seguridad en directorios sensibles
verificar_seguridad_wp() {
    clear
    echo "Verificando seguridad en $url ..."

    rutas=(
        "/wp-content/"
        "/wp-content/uploads/"
        "/wp-includes/"
        "/wp-admin/login.php"
        "/wp-admin/wp-login.php"
        "/login.php"
        "/wp-login.php"
        "/admin"
        "/administrator"
        "/administrador"
    )

    for ruta in "${rutas[@]}"; do
        status_code=$(curl -s -o /dev/null -w "%{http_code}" -I -X GET "$url$ruta")

        echo "--------------------------------------"
        echo "Verificando $url$ruta"

        if [[ "$status_code" == "403" || "$status_code" == "301" || "$status_code" == "302" ]]; then
            echo "[✔] La ruta está protegida. (Código HTTP: $status_code)"
        elif [[ "$status_code" == "200" ]]; then
            echo "[⚠] ¡Alerta! La ruta es accesible. (Código HTTP: $status_code)"
        else
            echo "[?] Respuesta inesperada: Código HTTP $status_code"
        fi
    done

    echo "--------------------------------------"
    read -p "Presione ENTER para volver al menú..."
    clear
}

# Función para verificar cabeceras de seguridad HTTP
verificar_cabeceras_http() {
    clear
    echo "Verificando cabeceras de seguridad en $url ..."

    headers=$(curl -s -I "$url")

    declare -A required_headers=(
        ["Strict-Transport-Security"]="Protege contra ataques de downgrade a HTTP."
        ["Content-Security-Policy"]="Ayuda a prevenir ataques XSS."
        ["X-Frame-Options"]="Evita ataques de clickjacking."
        ["X-Content-Type-Options"]="Evita la manipulación del tipo de contenido."
        ["Referrer-Policy"]="Controla la información enviada en el encabezado Referer."
        ["Permissions-Policy"]="Restringe APIs y funciones disponibles en el navegador."
    )

    for header in "${!required_headers[@]}"; do
        if echo "$headers" | grep -qi "$header"; then
            echo "[✔] $header detectada."
        else
            echo "[⚠] Falta $header - ${required_headers[$header]}"
        fi
    done

    echo "--------------------------------------"
    read -p "Presione ENTER para volver al menú..."
    clear
}

# Función para verificar si wp-cron.php está habilitado
verificar_wpcron() {
    clear
    cron_url="$url/wp-cron.php"

    echo "Verificando $cron_url ..."

    status_code=$(curl -s -o /dev/null -w "%{http_code}" -I -X GET "$cron_url")

    echo "--------------------------------------"
    if [[ "$status_code" == "200" ]]; then
        echo "[⚠] ¡Alerta! wp-cron.php está habilitado y puede ser vulnerable a ataques DoS."
    else
        echo "[✔] wp-cron.php parece estar protegido."
    fi
    echo "--------------------------------------"
    read -p "Presione ENTER para volver al menú..."
    clear
}

# Función para verificar si xmlrpc.php está habilitado con GET
verificar_xmlrpc() {
    clear
    xmlrpc_url="$url/xmlrpc.php"

    echo "Verificando $xmlrpc_url ..."

    response=$(curl -s -X GET "$xmlrpc_url" | head -n 3)

    echo "--------------------------------------"
    echo "$response"
    echo "--------------------------------------"

    if echo "$response" | grep -q "XML-RPC server accepts POST requests only."; then
        echo "[⚠] ¡Alerta! xmlrpc.php está habilitado."
    else
        echo "[✔] xmlrpc.php no está habilitado o está protegido."
    fi
    echo "--------------------------------------"
    read -p "Presione ENTER para volver al menú..."
    clear
}


# Menú 
mostrar_menu() {
    while true; do
    	echo "
__        __         _____                       
\ \      / / __  ___| ____|_ __  _   _ _ __ ___  
 \ \ /\ / / '_ \/ __|  _| | '_ \| | | | '_   _ \ 
  \ V  V /| |_) \__ \ |___| | | | |_| | | | | | |
   \_/\_/ | .__/|___/_____|_| |_|\__,_|_| |_| |_|
          |_|                                    "
	echo "   	Creado por @hacking.con.h"          
	echo ""
        echo ""
        echo "	1) Verificar si la web es WordPress"
        echo "	2) Verificar la enumeración de usuarios"
        echo "	3) Verificar seguridad de directorios"
        echo "	4) Verificar si la web es vuknerable a ataques DOS"
        echo "	5) Verificar xmlrpc.php"
        echo "	6) Verificar cabeceras de seguridad HTTP"
        echo "	7) Salir"
        echo ""
        read -p "	Seleccione una opción: " opcion

        case $opcion in
            1) ejecutar_whatweb ;;
            2) buscar_usuarios_wp ;;
            3) verificar_seguridad_wp ;;
            4) verificar_wpcron ;;
            5) verificar_xmlrpc ;;
            6) verificar_cabeceras_http ;;
            7) echo "Saliendo..."; exit 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

mostrar_menu
