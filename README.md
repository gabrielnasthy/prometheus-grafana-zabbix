# Stack de Monitoramento Completo com Zabbix, Grafana e Prometheus em Contêineres Rootless

![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?style=for-the-badge&logo=zabbix) ![Grafana](https://img.shields.io/badge/Grafana-11.1-F46800?style=for-the-badge&logo=grafana) ![Prometheus](https://img.shields.io/badge/Prometheus-v2-E6522C?style=for-the-badge&logo=prometheus) ![Podman](https://img.shields.io/badge/Podman-Rootless-8A2BE2?style=for-the-badge&logo=podman)

## 📖 Visão Geral do Projeto
Este projeto nasceu de uma necessidade real: monitorar de forma proativa uma infraestrutura de múltiplos servidores de clientes, distribuídos em diferentes localidades, para prever e agir sobre falhas antes que impactassem o negócio.

A solução implementada é uma plataforma de monitoramento completa, segura e automatizada, totalmente orquestrada com **Podman Compose** em modo **rootless**. O repositório contém todos os arquivos de configuração e scripts de implantação de agentes para colocar o ambiente em funcionamento de forma rápida e consistente.

## 🚀 Tecnologias Utilizadas
* **Containerização:** Podman & Podman Compose (Rootless)
* **Monitoramento de Infraestrutura:** Zabbix 7.0 LTS
* **Coleta de Métricas:** Prometheus & Node Exporter
* **Visualização e Dashboards:** Grafana
* **Banco de Dados:** MySQL 8.0
* **Proxy Reverso:** Nginx
* **Scripts de Implantação:** Bash (Linux) e PowerShell (Windows)

---

## ⚡ Instalação Rápida (Quick Start)

### Pré-requisitos
* Git, Podman e Podman Compose instalados.
* Um servidor Linux para hospedar o stack.

### Passos
1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/gabrielnasthy/stack-monitoramento-podman.git](https://github.com/gabrielnasthy/stack-monitoramento-podman.git)
    cd stack-monitoramento-podman
    ```

2.  **Configure seu ambiente:**
    Copie o arquivo de exemplo `.env.example` para um novo arquivo chamado `.env`.
    ```bash
    cp .env.example .env
    ```
    Agora, **edite o arquivo `.env`** com um editor de texto (ex: `nano .env`) e **substitua os valores** das senhas e do `ZABBIX_HOSTNAME` com suas informações. Este é o único arquivo que você precisa configurar para o stack principal.

3.  **(Opcional) Configure o Servidor Host para Produção:**
    Para que o stack inicie automaticamente com o servidor, aplique as configurações descritas na seção "Configuração Avançada do Servidor Host" abaixo.

4.  **Inicie o stack:**
    ```bash
    podman-compose up -d
    ```
Aguarde alguns minutos para a inicialização. Seus serviços estarão disponíveis nos endereços como `http://SEU_HOSTNAME/zabbix`.

## 🤖 Scripts de Implantação de Agentes
Na pasta `scripts/`, você encontrará scripts para automatizar a instalação do Zabbix Agent e do Tailscale em novas máquinas:
* `deploy_zabbix_linux.sh`: Para distribuições Linux (Debian, RHEL, Arch).
* `deploy_zabbix_windows.ps1`: Para servidores Windows.

Edite a variável da chave de autenticação do Tailscale (`TAILSCALE_AUTH_KEY`) dentro do script desejado antes de executá-lo na máquina cliente.