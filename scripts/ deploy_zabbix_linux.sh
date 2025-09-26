# =============================================================================
# Script de Implantação do Zabbix Agent e Tailscale para Windows
# Versão 4.2 - Permite escolher o nome do host a ser registrado
# =============================================================================

# --- Função para carregar .env ---
function Load-Env {
    # ... (função continua a mesma) ...
}

# --- Início do Script ---
Clear-Host
Load-Env

# --- Funções de Interface ---
function Print-Step { param($message) Write-Host "" ; Write-Host "--- $message ---" -ForegroundColor Yellow }
function Print-Success { param($message) Write-Host "[✓] $message" -ForegroundColor Green }
function Print-Error { param($message) Write-Host "[✗] ERRO: $message" -ForegroundColor Red; Read-Host "Pressione Enter para sair"; exit 1 }

# --- Pergunta pelo nome de host a ser usado ---
Print-Step "Configuração do Nome de Host"
$ZabbixHostname = Read-Host "Digite o nome de host único para Zabbix e Tailscale (ex: ClienteA-WebServer01)"
if ([string]::IsNullOrWhiteSpace($ZabbixHostname)) {
    Print-Error "O nome do host não pode ser vazio."
}
$ZabbixHostname = $ZabbixHostname -replace '[^a-zA-Z0-9_-]' # Remove caracteres especiais
Print-Success "O host será registrado como: $ZabbixHostname"

# --- Variáveis de Configuração ---
$TailscaleAuthKey = $env:TAILSCALE_AUTH_KEY
$ZabbixServerIP   = $env:ZABBIX_SERVER_IP
$Metadata         = "Windows-Auto"
$TempDir          = "C:\TempInstall"

# --- Verificação de Admin ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Print-Error "Este script precisa ser executado como Administrador."
}

# ... (o resto do script de instalação do Tailscale e Zabbix Agent continua o mesmo) ...

# 2. Instalação do Zabbix Agent 2
Print-Step "Verificando e instalando o Zabbix Agent 2"
if (-not (Get-Service "Zabbix Agent 2" -ErrorAction SilentlyContinue)) {
    try {
        # ... (download continua o mesmo) ...
        
        # Usa a variável ZabbixHostname que foi digitada pelo usuário
        $MsiArgs = @("/i", "`"$ZabbixInstaller`"", "/qn", "SERVER=$ZabbixServerIP", "SERVERACTIVE=$ZabbixServerIP", "HOSTNAME=$ZabbixHostname", "HOSTMETADATA=$Metadata", "ENABLEPATH=1")
        
        Write-Host "Instalando e configurando o Zabbix Agent 2 com o nome de host: $ZabbixHostname"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -Wait
        Print-Success "Zabbix Agent 2 instalado e configurado."
    } catch { Print-Error "Falha ao baixar ou instalar o Zabbix Agent 2. $($_.Exception.Message)" }
} else { Print-Success "Zabbix Agent 2 já está instalado." }

# 3. Iniciar Serviços
Print-Step "Iniciando e configurando serviços de rede"
try {
    $tailscalePath = "$env:ProgramFiles\Tailscale\tailscale.exe"
    if (-not (Test-Path $tailscalePath)) { Print-Error "Executável do Tailscale não foi encontrado." }
    
    Print-Success "Conectando à rede Tailscale automaticamente..."
    # Usa o nome de host único também para o Tailscale
    $upArgs = @("up", "--authkey", $TailscaleAuthKey, "--hostname", $ZabbixHostname, "--accept-routes")
    Start-Process -FilePath $tailscalePath -ArgumentList $upArgs -Wait -NoNewWindow
    
    Print-Success "Tailscale e Zabbix Agent iniciados."
} catch { Print-Error "Falha ao configurar o Tailscale. $($_.Exception.Message)" }

# ... (o resto do script continua o mesmo) ...

Print-Step "IMPLANTAÇÃO CONCLUÍDA"
Write-Host "O host '$ZabbixHostname' deve aparecer automaticamente no seu Zabbix em alguns minutos."
