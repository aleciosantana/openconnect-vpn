# Usando uma versão enxuta do Debian
FROM debian:bookworm-slim

# Atualiza os pacotes e instala OpenConnect, iproute2 e iputils-ping
RUN apt-get update && apt-get install -y \
    openconnect \
    iproute2 \
    dnsutils \
    iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cria um diretório para o script de conexão
WORKDIR /usr/src/app

# Adiciona um script de conexão à VPN
COPY connect-vpn.sh /usr/src/app/connect-vpn.sh
RUN chmod +x /usr/src/app/connect-vpn.sh

# Executa o script ao iniciar o container
CMD ["/usr/src/app/connect-vpn.sh"]
