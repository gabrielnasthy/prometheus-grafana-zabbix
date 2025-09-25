#!/bin/bash

# =============================================================================
# Script de Implantação do Zabbix Agent e Tailscale para Linux
# Versão 4.0 - Configuração modularizada com arquivo .env
# =============================================================================

# --- Função para carregar variáveis de ambiente do arquivo .env ---
load_env() {
    # Procura pelo .env no mesmo diretório do script
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    if [ -f "$SCRIPT_DIR/.env" ]; then
        export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
    else
        echo "[✗] ERRO: Arquivo .env não encontrado em '$SCRIPT_DIR'."
        echo "Por favor, copie .env.example para .env e preencha os valores."
        exit 1
    fi
}

# --- Funções de Interface ("Menuzinho") ---
print_step() { echo "" && echo "--- $1 ---"; }
print_success() { echo "[✓] $1"; }
print_error() { echo "[✗] ERRO: $1"; exit 1; }

# --- Início do Script ---
clear
load_env # Carrega as variáveis de .env

# O resto do script usa as variáveis carregadas ($TAILSCALE_AUTH_KEY, $ZABBIX_SERVER_IP)
METADATA="Linux-Auto"
HOSTNAME=$(hostname)
CONF_FILE="/etc/zabbix/zabbix_agent2.conf"

# --- Verificação de Root ---
if [ "$EUID" -ne 0 ]; then
    print_error "Este script precisa ser executado como root. Use 'sudo'."
fi

print_step "Iniciando implantação automatizada do Agente de Monitoramento"

# 1. Detectar a Distribuição
if [ -f /etc/debian_version ]; then
    DISTRO="debian"
    PKG_MANAGER="apt-get"
elif [ -f /etc/redhat-release ]; then
    DISTRO="rhel"
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    DISTRO="arch"
    PKG_MANAGER="pacman"
else
    print_error "Distribuição Linux não suportada."
fi
print_success "Sistema operacional detectado: $DISTRO"

# 2. Instalação do Tailscale
print_step "Instalando Tailscale"
if ! command -v tailscale &> /dev/null; then
    if [ "$DISTRO" == "debian" ]; then
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(. /etc/os-release && echo "$VERSION_CODENAME").noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(. /etc/os-release && echo "$VERSION_CODENAME").tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
        $PKG_MANAGER update && $PKG_MANAGER install tailscale -y
    elif [ "$DISTRO" == "rhel" ]; then
        $PKG_MANAGER config-manager --add-repo https://pkgs.tailscale.com/stable/centos/$(rpm -E %rhel)/tailscale.repo
        $PKG_MANAGER install tailscale -y
    elif [ "$DISTRO" == "arch" ]; then
        $PKG_MANAGER -Syu --noconfirm tailscale
    fi
    print_success "Tailscale instalado."
else
    print_success "Tailscale já está instalado."
fi

# 3. Instalação do Zabbix Agent 2
print_step "Instalando Zabbix Agent 2"
if ! command -v zabbix_agent2 &> /dev/null; then
    if [ "$DISTRO" == "debian" ]; then
        wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu$(. /etc/os-release && echo "$VERSION_ID")_all.deb -O /tmp/zabbix-release.deb
        dpkg -i /tmp/zabbix-release.deb
        $PKG_MANAGER update && $PKG_MANAGER install zabbix-agent2 -y
    elif [ "$DISTRO" == "rhel" ]; then
        rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/$(rpm -E %rhel)/x86_64/zabbix-release-7.0-1.el$(rpm -E %rhel).noarch.rpm
        $PKG_MANAGER clean all && $PKG_MANAGER install zabbix-agent2 -y
    elif [ "$DISTRO" == "arch" ]; then
        $PKG_MANAGER -S --noconfirm zabbix-agent2
    fi
    print_success "Zabbix Agent 2 instalado."
else
    print_success "Zabbix Agent 2 já está instalado."
fi

# 4. Configurar Zabbix Agent
print_step "Configurando Zabbix Agent para auto-registro"
sed -i "s/^Server=127.0.0.1/Server=$ZABBIX_SERVER_IP/" "$CONF_FILE"
sed -i "s/^ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER_IP/" "$CONF_FILE"
sed -i "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/" "$CONF_FILE"
sed -i "s/^# HostMetadata=/HostMetadata=$METADATA/" "$CONF_FILE"
sed -i "s/^HostMetadata=.*/HostMetadata=$METADATA/" "$CONF_FILE"
print_success "Arquivo de configuração do Zabbix atualizado."

# 5. Iniciar Serviços
print_step "Iniciando e configurando serviços de rede"
systemctl enable --now tailscaled
systemctl enable --now zabbix-agent2

tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="$HOSTNAME-zabbix" --accept-routes
print_success "Tailscale e Zabbix Agent iniciados."

print_step "IMPLANTAÇÃO CONCLUÍDA"
echo "O host '$HOSTNAME' deve aparecer automaticamente no seu Zabbix em alguns minutos."