#!/bin/bash

# =============================================================================
# Script de Implantação do Zabbix Agent e Tailscale para Linux
# Versão 4.2 - Permite escolher o nome do host a ser registrado
# =============================================================================

# --- Função para carregar variáveis de ambiente ---
load_env() {
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    if [ -f "$SCRIPT_DIR/.env" ]; then
        export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
    else
        echo "[✗] ERRO: Arquivo .env não encontrado."
        exit 1
    fi
}

# --- Funções de Interface ---
print_step() { echo "" && echo "--- $1 ---"; }
print_success() { echo "[✓] $1"; }
print_error() { echo "[✗] ERRO: $1"; exit 1; }

# --- Início do Script ---
clear
load_env

# --- Pergunta pelo nome de host a ser usado ---
print_step "Configuração do Nome de Host"
read -p "Digite o nome de host único para Zabbix e Tailscale (ex: ClienteA-WebServer01): " ZABBIX_HOSTNAME
if [ -z "$ZABBIX_HOSTNAME" ]; then
    print_error "O nome do host não pode ser vazio."
fi
# Remove caracteres especiais para segurança
ZABBIX_HOSTNAME=$(echo "$ZABBIX_HOSTNAME" | sed 's/[^a-zA-Z0-9_-]//g')
print_success "O host será registrado como: $ZABBIX_HOSTNAME"

# --- Define variáveis globais ---
METADATA="Linux-Auto"
CONF_FILE="/etc/zabbix/zabbix_agent2.conf"

# --- Verificação de Root ---
if [ "$EUID" -ne 0 ]; then
    print_error "Este script precisa ser executado como root. Use 'sudo'."
fi

# ... (o resto do script de instalação do Tailscale e Zabbix Agent continua o mesmo) ...
print_step "Iniciando implantação automatizada..."
# ...

# 4. Configurar Zabbix Agent
print_step "Configurando Zabbix Agent para auto-registro"
sed -i "s/^Server=127.0.0.1/Server=$ZABBIX_SERVER_IP/" "$CONF_FILE"
sed -i "s/^ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER_IP/" "$CONF_FILE"
sed -i "s/^Hostname=Zabbix server/Hostname=$ZABBIX_HOSTNAME/" "$CONF_FILE"
sed -i "s/^# HostMetadata=/HostMetadata=$METADATA/" "$CONF_FILE"
sed -i "s/^HostMetadata=.*/HostMetadata=$METADATA/" "$CONF_FILE"
print_success "Arquivo de configuração do Zabbix atualizado."

# 5. Iniciar Serviços
print_step "Iniciando e configurando serviços de rede"
systemctl enable --now tailscaled
systemctl enable --now zabbix-agent2

tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="$ZABBIX_HOSTNAME" --accept-routes
print_success "Tailscale e Zabbix Agent iniciados."

print_step "IMPLANTAÇÃO CONCLUÍda"
echo "O host '$ZABBIX_HOSTNAME' deve aparecer automaticamente no seu Zabbix em alguns minutos."
