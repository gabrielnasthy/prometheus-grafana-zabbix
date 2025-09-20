# Stack de Monitoramento Completo com Zabbix, Grafana e Prometheus em Contêineres Rootless

![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?style=for-the-badge&logo=zabbix) ![Grafana](https://img.shields.io/badge/Grafana-11.1-F46800?style=for-the-badge&logo=grafana) ![Prometheus](https://img.shields.io/badge/Prometheus-v2-E6522C?style=for-the-badge&logo=prometheus) ![Podman](https://img.shields.io/badge/Podman-Rootless-8A2BE2?style=for-the-badge&logo=podman)

## 📖 Visão Geral do Projeto

Este projeto nasceu de uma necessidade real: monitorar de forma proativa uma infraestrutura de 15 servidores de clientes, distribuídos em diferentes localidades, para prever e agir sobre falhas de hardware ou software antes que impactassem o negócio.

A solução implementada é uma plataforma de monitoramento completa, segura e automatizada, construída do zero com as melhores ferramentas open-source. O ambiente é totalmente orquestrado com **Podman Compose** em modo **rootless**, garantindo maior segurança e seguindo as práticas modernas de DevOps.

O stack final inclui Zabbix para monitoramento de infraestrutura, Prometheus para métricas de serviços, Grafana para visualização unificada e um Proxy Reverso Nginx para acesso simplificado e profissional.

## 🏛️ Arquitetura Final

O ambiente foi desenhado para ser acessado de forma centralizada pela porta 80, onde um Proxy Reverso Nginx direciona o tráfego para o serviço apropriado com base na URL.

```
            +---------------------------+
            |      Usuário/Admin        |
            +-------------+-------------+
                          |
+-------------------------|--------------------------+
|          Host Server (Arch Linux, Porta 80)        |
+-------------------------+--------------------------+
                          |
          +---------------v---------------+
          |  [reverse-proxy] (Nginx)      |
          +---------------+---------------+
                          |
        +-----------------+-----------------+
        |                 |                 |
/zabbix/|          /grafana/|        /prometheus/|
        v                 v                 v
  +-----------+     +-----------+     +--------------+
  | zabbix-web|     |  grafana  |     |  prometheus  |
  +-----+-----+     +-----+-----+     +------+-------+
        |                 |                    |
        |                 +--------------------+ (Data Sources)
        |
+-------+-----------------+
|                         |
v                         v
+----------------+   +----------------+
| [zabbix-server]|   | [zabbix-mysql] | (MySQL DB)
+----------------+   +----------------+
```

## 🚀 Tecnologias Utilizadas
* **Containerização:** Podman & Podman Compose (Rootless)
* **Monitoramento de Infraestrutura:** Zabbix 7.0 LTS
* **Coleta de Métricas:** Prometheus & Node Exporter
* **Visualização e Dashboards:** Grafana
* **Banco de Dados:** MySQL 8.0
* **Proxy Reverso:** Nginx
* **Sistema Operacional (Servidor):** Arch Linux
* **Agentes Monitorados:** Arch Linux, Fedora Kinoite (Imutável), Windows Server

---

## 🛠️ Como Executar o Projeto

### Pré-requisitos
* Um servidor Linux com `podman` e `podman-compose` instalados.
* Conectividade de rede entre o servidor e os hosts a serem monitorados (recomenda-se VPN como Tailscale).

### Passo 1: Estrutura de Arquivos
Crie um diretório para o projeto e os arquivos de configuração dentro dele. A estrutura final será:
```
zabbix/
├── .env
├── nginx.conf
├── podman-compose.yml
└── prometheus.yml
```

### Passo 2: Arquivo de Variáveis de Ambiente (`.env`)
Crie um arquivo `.env` para armazenar as senhas e outras informações sensíveis. Este arquivo **não deve** ser enviado para repositórios públicos.
```bash
# ~/zabbix/nano .env
```
```env
# Arquivo de variáveis de ambiente para o podman-compose

# Senha para o usuário 'root' do MySQL
MYSQL_ROOT_PASSWORD=Sup3R0312@

# Senha para o usuário 'zabbix' do MySQL
MYSQL_PASSWORD=Sup3R0312@
```

### Passo 3: Arquivos de Configuração
Crie os seguintes arquivos de configuração dentro do diretório `~/zabbix`.

#### `podman-compose.yml`
```yaml
version: "3.8"

services:
  reverse-proxy:
    image: docker.io/library/nginx:latest
    container_name: reverse-proxy
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - zabbix-web
      - grafana

  prometheus:
    image: docker.io/prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.external-url=http://archlinux/prometheus'

  node-exporter:
    image: docker.io/prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'

  zabbix-mysql:
    image: docker.io/library/mysql:8.0
    container_name: zabbix-mysql
    restart: unless-stopped
    expose:
      - "3306"
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_bin
      - --log-bin-trust-function-creators=1
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - zabbix-mysql-data:/var/lib/mysql

  zabbix-server:
    image: docker.io/zabbix/zabbix-server-mysql:7.4-alpine-latest
    container_name: zabbix-server
    restart: unless-stopped
    environment:
      DB_SERVER_HOST: zabbix-mysql
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    depends_on:
      - zabbix-mysql
    ports:
      - "10051:10051"

  zabbix-web:
    image: docker.io/zabbix/zabbix-web-nginx-mysql:7.4-alpine-latest
    container_name: zabbix-web
    restart: unless-stopped
    environment:
      ZBX_SERVER_HOST: zabbix-server
      DB_SERVER_HOST: zabbix-mysql
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      PHP_TZ: America/Sao_Paulo
      ZBX_SERVER_NAME: archlinux/zabbix
    depends_on:
      - zabbix-server
      - zabbix-mysql

  zabbix-agent2:
    image: docker.io/zabbix/zabbix-agent2:7.4-alpine-latest
    container_name: zabbix-agent2
    restart: unless-stopped
    environment:
      ZBX_SERVER_HOST: zabbix-server
      HOSTNAME: Zabbix server
    depends_on:
      - zabbix-server

  grafana:
    image: docker.io/grafana/grafana-oss:11.1.0
    container_name: grafana
    restart: unless-stopped
    volumes:
      - grafana-data:/var/lib/grafana
    environment:
      GF_INSTALL_PLUGINS: alexanderzobnin-zabbix-app
      GF_SERVER_ROOT_URL: "%(protocol)s://%(domain)s:%(http_port)s/grafana"
    depends_on:
      - zabbix-server

volumes:
  zabbix-mysql-data:
  grafana-data:
  prometheus-data:
```

#### `nginx.conf`
```nginx
server {
    listen 80;
    server_name archlinux;

    location /zabbix/ {
        proxy_pass http://zabbix-web:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /grafana/ {
        proxy_pass http://grafana:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /prometheus/ {
        proxy_pass http://prometheus:9090/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### `prometheus.yml`
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Passo 4: Configuração do Servidor Host
Para garantir a funcionalidade completa, as seguintes configurações são necessárias no servidor host.

1.  **Permitir Portas Privilegiadas para Usuários Rootless:**
    ```bash
    echo 'net.ipv4.ip_unprivileged_port_start=80' | sudo tee /etc/sysctl.d/99-podman-ports.conf
    sudo sysctl --system
    ```

2.  **Habilitar Inicialização Automática dos Contêineres no Boot:**
    ```bash
    # (Substitua 'seu_usuario' pelo seu nome de usuário)
    sudo loginctl enable-linger seu_usuario
    systemctl --user enable podman-restart.service
    ```

### Passo 5: Implantação
Com todos os arquivos e configurações no lugar, inicie o stack:
```bash
# Navegue até o diretório do projeto
cd ~/zabbix

# Inicie os serviços
podman-compose up -d
```
Aguarde alguns minutos para a inicialização completa. Acesse os serviços através de `http://<IP_DO_SERVIDOR>/zabbix` e `http://<IP_DO_SERVIDOR>/grafana`.

## 🎓 Jornada de Troubleshooting e Aprendizados
A implementação deste projeto envolveu a resolução de múltiplos desafios técnicos, que serviram como grandes pontos de aprendizado:
* **Banco de Dados Zabbix:** Corrigido erro de `SUPER privilege` e problemas de `collation` (UTF8) no MySQL customizando o comando de inicialização do contêiner.
* **Volumes Persistentes:** Solucionado o problema de "banco de dados corrompido" em reinicializações ao garantir a limpeza completa de volumes (`podman volume prune`) antes de uma nova tentativa.
* **Contêineres Rootless:** Superado o desafio de expor portas privilegiadas (< 1024) por um usuário não-root através de configuração do `sysctl`.
* **Conflitos de Portas:** Resolvido um conflito entre o Prometheus (`9090`) e o serviço Cockpit do host, remapeando a porta externa do Prometheus.
* **Sistemas Imutáveis:** Realizada a instalação do Zabbix Agent no Fedora Kinoite utilizando `rpm-ostree`, incluindo a adição de um repositório externo.
* **Proxy Reverso:** Depurado o redirecionamento incorreto do Prometheus, configurando a `web.external-url` e ajustando as regras do Nginx para funcionar corretamente com subpastas.

---
Projeto desenvolvido por **Gabriel** ([@gabrielnasthy](https://github.com/gabrielnasthy)).
