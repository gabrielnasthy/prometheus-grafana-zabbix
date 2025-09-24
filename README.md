# Stack de Monitoramento Completo com Zabbix, Grafana e Prometheus em Contêineres Rootless

![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?style=for-the-badge&logo=zabbix) ![Grafana](https://img.shields.io/badge/Grafana-11.1-F46800?style=for-the-badge&logo=grafana) ![Prometheus](https://img.shields.io/badge/Prometheus-v2-E6522C?style=for-the-badge&logo=prometheus) ![Podman](https://img.shields.io/badge/Podman-Rootless-8A2BE2?style=for-the-badge&logo=podman)

## 📖 Visão Geral do Projeto
Este projeto nasceu de uma necessidade real: monitorar de forma proativa uma infraestrutura de 15 servidores de clientes, distribuídos em diferentes localidades, para prever e agir sobre falhas de hardware ou software antes que impactassem o negócio.

A solução implementada é uma plataforma de monitoramento completa, segura e automatizada, construída do zero com as melhores ferramentas open-source. O ambiente é totalmente orquestrado com **Podman Compose** em modo **rootless**, garantindo maior segurança e seguindo as práticas modernas de DevOps.

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

2.  **Crie e configure o arquivo de senhas e hostname:**
    Copie o arquivo de exemplo `.env.example` para um novo arquivo chamado `.env`.
    ```bash
    cp .env.example .env
    ```
    Agora, **edite o arquivo `.env`** com um editor de texto (ex: `nano .env`) e **substitua os valores** das senhas e do `ZABBIX_HOSTNAME` com suas informações.

3.  **Configure o Nginx:**
    **Edite o arquivo `nginx.conf`** e troque a linha `server_name seu_servidor_aqui;` para usar o mesmo hostname que você colocou na variável `ZABBIX_HOSTNAME` do passo anterior.

4.  **(Opcional) Configure o Servidor Host:**
    Para funcionalidade completa (porta 80 e auto-start), aplique as configurações de host descritas na seção "Configuração Avançada do Servidor Host" abaixo.

5.  **Inicie o stack:**
    ```bash
    podman-compose up -d
    ```
Aguarde alguns minutos para a inicialização. Seus serviços estarão disponíveis nos endereços como `http://SEU_HOSTNAME/zabbix`.

---
## 🎓 Jornada de Troubleshooting e Aprendizados
A implementação deste projeto envolveu a resolução de múltiplos desafios técnicos, servindo como grandes pontos de aprendizado:
* **Banco de Dados:** Corrigido erro de `SUPER privilege` e problemas de `collation` no MySQL.
* **Volumes Persistentes:** Solucionado o problema de "banco de dados corrompido" em reinicializações com `podman volume prune`.
* **Contêineres Rootless:** Superado o desafio de expor portas privilegiadas (< 1024) por um usuário não-root com `sysctl`.
* **Sistemas Imutáveis:** Realizada a instalação do Zabbix Agent no Fedora Kinoite utilizando `rpm-ostree`.
* **Proxy Reverso:** Depurado o redirecionamento incorreto do Prometheus com a flag `web.external-url`.

---
Projeto desenvolvido por **Gabriel** ([@gabrielnasthy](https://github.com/gabrielnasthy)).
