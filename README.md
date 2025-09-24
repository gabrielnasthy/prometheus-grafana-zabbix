# Stack de Monitoramento Completo com Zabbix, Grafana e Prometheus em Contêineres Rootless

![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?style=for-the-badge&logo=zabbix) ![Grafana](https://img.shields.io/badge/Grafana-11.1-F46800?style=for-the-badge&logo=grafana) ![Prometheus](https://img.shields.io/badge/Prometheus-v2-E6522C?style=for-the-badge&logo=prometheus) ![Podman](https://img.shields.io/badge/Podman-Rootless-8A2BE2?style=for-the-badge&logo=podman)

## 📖 Visão Geral do Projeto
Este projeto nasceu de uma necessidade real: monitorar de forma proativa uma infraestrutura de múltiplos servidores de clientes, distribuídos em diferentes localidades, para prever e agir sobre falhas antes que impactassem o negócio.

A solução implementada é uma plataforma de monitoramento completa, segura e automatizada, totalmente orquestrada com **Podman Compose** em modo **rootless**.

## ⚡ Instalação Rápida (Quick Start)

### Pré-requisitos
* Git, Podman e Podman Compose instalados.
* Um servidor Linux para hospedar o stack.

### Passos
1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/gabrielnasthy/stack-monitoramento-podman.git
    cd stack-monitoramento-podman
    ```

2.  **Configure o ambiente:**
    Copie o arquivo de exemplo `.env.example` para um novo arquivo chamado `.env`.
    ```bash
    cp .env.example .env
    ```
    Agora, **edite apenas o arquivo `.env`** com um editor de texto (ex: `nano .env`) e **substitua os valores** das senhas e do `ZABBIX_HOSTNAME` com suas informações. É o único arquivo que você precisa tocar!

3.  **(Opcional) Configure o Servidor Host para Produção:**
    Para que o stack inicie automaticamente com o servidor, aplique as configurações descritas na seção "Configuração Avançada do Servidor Host" abaixo.

4.  **Inicie o stack:**
    ```bash
    podman-compose up -d
    ```
Aguarde alguns minutos para a inicialização. Seus serviços estarão disponíveis nos endereços como `http://SEU_HOSTNAME/zabbix`.
