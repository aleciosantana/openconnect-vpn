## Como Conectar-se a uma VPN Usando Docker

Conectar-se a uma VPN pode ser um desafio, especialmente se você precisar gerenciar várias configurações ou se estiver lidando com questões de compatibilidade. Utilizar contêineres Docker pode simplificar esse processo, permitindo que você mantenha um ambiente isolado e fácil de configurar. Neste guia, vamos ensinar como configurar uma VPN usando OpenConnect em um contêiner Docker, aproveitando variáveis de ambiente para facilitar a personalização.

### Por que Usar Docker para Conectar-se a uma VPN?

1. **Isolamento**: Contêineres fornecem um ambiente separado, evitando conflitos com outras aplicações em seu sistema.
2. **Facilidade de Deploy**: Você pode implantar facilmente a configuração em diferentes máquinas ou ambientes, sem necessidade de reconfiguração.
3. **Reprodutibilidade**: Com Docker, é possível replicar a configuração em diferentes sistemas sem problemas de compatibilidade.
4. **Compatibilidade**: Algumas versões mais novas do OpenConnect Client podem não funcionar com firewalls específicos, como o Cisco ASA 5500. A versão 8 do OpenConnect funciona bem em sistemas Linux, garantindo uma conexão estável.

### Estrutura do Projeto

Para configurar a VPN usando Docker, você precisará criar os seguintes arquivos:

#### 1. **Arquivo `.env`**

O arquivo `.env` contém as variáveis de ambiente necessárias para a configuração da VPN.

```plaintext
VPN_USER=seu_usuario_vpn             # Substitua pelo seu usuário da VPN
VPN_PASSWORD=sua_senha_vpn           # Substitua pela sua senha da VPN
VPN_HOST=ip_ou_hostname_da_vpn       # Endereço IP do servidor VPN
VPN_AUTHGROUP=grupo_de_autenticacao  # Grupo de autenticação, se necessário
VPN_SERVERCERT=certificado           # Certificado do servidor
VPN_ROUTES=192.168.100.0/24,10.0.0.0/8  # Rotas específicas que devem passar pela VPN
VPN_DNS=1.1.1.1                      # Servidor DNS a ser usado
```

#### 2. **Script de Conexão: `connect-vpn.sh`**

Este script gerencia a conexão à VPN, define o DNS e adiciona as rotas necessárias.

```bash
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
```

#### 3. **Arquivo `docker-compose.yml`**

O arquivo `docker-compose.yml` define o serviço do Docker e as variáveis de ambiente que serão usadas.

```yaml
services:
  openconnect-vpn:
    build: .
    container_name: openconnect-vpn
    environment:
      - VPN_USER=${VPN_USER}
      - VPN_PASSWORD=${VPN_PASSWORD}
      - VPN_HOST=${VPN_HOST}
      - VPN_AUTHGROUP=${VPN_AUTHGROUP}
      - VPN_SERVERCERT=${VPN_SERVERCERT}
      - VPN_ROUTES=${VPN_ROUTES}
      - VPN_DNS=${VPN_DNS}
    cap_add:
      - NET_ADMIN              # Permite modificações nas configurações de rede
    network_mode: "host"      # Permite que o contêiner utilize a rede do host
    restart: always            # Reinicia o contêiner automaticamente em caso de falhas
```


> - **Capacidades do Contêiner**: A diretiva `cap_add: - NET_ADMIN` é crucial, pois permite que o contêiner modifique as configurações de rede, como adicionar rotas.
> - **Modo de Rede**: O `network_mode: "host"` permite que o contêiner utilize a rede do host, o que é essencial para garantir a conectividade com a VPN.

#### 4. **Arquivo `Dockerfile`**

O Dockerfile é responsável por construir a imagem do contêiner, instalando as dependências necessárias.

```Dockerfile
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
```

### Como Iniciar a VPN

Após criar os arquivos, você pode iniciar a VPN com o seguinte comando:

```bash
docker compose up --build -d
```

Este comando faz o seguinte:
- `up`: Cria e inicia os contêineres definidos no arquivo `docker-compose.yml`.
- `--build`: Reconstrói a imagem do contêiner, garantindo que as últimas alterações sejam aplicadas.
- `-d`: Inicia os contêineres em segundo plano (modo destacado).

### Como Parar o VPN

Para parar o contêiner, você pode usar o comando:

```bash
docker compose down
```

___
### Considerações Finais

Utilizando este guia, você poderá configurar rapidamente uma conexão VPN em um contêiner Docker. A estrutura modular permite que você adapte as configurações conforme necessário, mantendo a flexibilidade e a portabilidade. Sinta-se à vontade para explorar e ajustar o ambiente conforme suas necessidades!

