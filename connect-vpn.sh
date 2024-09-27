#!/bin/bash

# Define o DNS usando a variável de ambiente
echo "nameserver $VPN_DNS" > /etc/resolv.conf

# Conecta à VPN usando OpenConnect com as variáveis de ambiente
echo "Conectando à VPN..."
echo "$VPN_PASSWORD" | openconnect $VPN_HOST \
    --user="$VPN_USER" \
    --authgroup="$VPN_AUTHGROUP" \
    --no-xmlpost \
    --no-dtls \
    --servercert="$VPN_SERVERCERT" \
    --passwd-on-stdin &

# Espera a VPN estabelecer a conexão
sleep 10

# Adiciona as rotas da VPN
IFS=',' read -ra ADDR <<< "$VPN_ROUTES"
for route in "${ADDR[@]}"; do
    echo "Adicionando rota para $route via VPN..."
    ip route add $route dev tun0
done

# Mantém o container rodando
tail -f /dev/null
