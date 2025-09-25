# =============================================================================
# Script de Implantação do Zabbix Agent e Tailscale para Windows
# Versão 4.0 - Configuração modularizada com arquivo .env
# =============================================================================

# --- Função para carregar variáveis de ambiente do arquivo .env ---
function Load-Env {
    # Encontra o caminho do script que está sendo executado
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptDir = Split-Path -Parent $scriptPath
    $envPath = Join-Path $scriptDir ".env"

    if (Test-Path $envPath) {
        Get-Content $envPath | ForEach-Object {
            $line = $_.Trim()
            if ($line -and !$line.StartsWith("#")) {
                $parts = $line -split '=', 2
                if ($parts.Length -eq 2) {
                    $key = $parts[0].Trim()
                    $value = $parts[1].Trim()
                    # Define a variável de ambiente para o processo atual do PowerShell
                    [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
                }
            }
        }
    } else {
        Write-Host "[✗] ERRO: Arquivo .env não encontrado no diretório do script." -ForegroundColor Red
        Write-Host "Por favor, copie .env.example para .env e preencha os valores." -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
}

# --- Início do Script ---
Clear-Host
Load-Env # Carrega as variáveis de .env

# --- Variáveis de Configuração (lidas do ambiente) ---
$TailscaleAuthKey = $env:TAILSCALE_AUTH_KEY
$ZabbixServerIP   = $env:ZABBIX_SERVER_IP
$Metadata         = "Windows-Auto"
$TempDir          = "C:\TempInstall"

# --- Funções de Interface ---
function Print-Step { param($message) Write-Host "" ; Write-Host "--- $message ---" -ForegroundColor Yellow }
function Print-Success { param($message) Write-Host "[✓] $message" -ForegroundColor Green }
function Print-Error { param($message) Write-Host "[✗] ERRO: $message" -ForegroundColor Red; Read-Host "Pressione Enter para sair"; exit 1 }

# --- Verificação de Admin ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Print-Error "Este script precisa ser executado como Administrador."
}

Print-Step "Iniciando implantação automatizada do Agente de Monitoramento"
if (-not (Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory | Out-Null }

# 1. Instalação do Tailscale
Print-Step "Verificando e instalando o Tailscale"
if (-not (Test-Path "$env:ProgramFiles\Tailscale\tailscale.exe")) {
    try {
        $TailscaleInstaller = "$TempDir\tailscale-installer.exe"
        Write-Host "Baixando o instalador do Tailscale..."
        Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe" -OutFile $TailscaleInstaller -ErrorAction Stop
        Write-Host "Instalando o Tailscale silenciosamente..."
        Start-Process -FilePath $TailscaleInstaller -ArgumentList "/S" -Wait
        Print-Success "Tailscale instalado com sucesso."
    } catch { Print-Error "Falha ao baixar ou instalar o Tailscale. $($_.Exception.Message)" }
} else { Print-Success "Tailscale já está instalado." }

# 2. Instalação do Zabbix Agent 2
Print-Step "Verificando e instalando o Zabbix Agent 2"
if (-not (Get-Service "Zabbix Agent 2" -ErrorAction SilentlyContinue)) {
    try {
        $ZabbixInstaller = "$TempDir\zabbix_agent2.msi"
        Write-Host "Baixando o instalador do Zabbix Agent 2 (versão 7.0 LTS)..."
        Invoke-WebRequest -Uri "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.0/zabbix_agent2-7.0.0-windows-amd64-openssl.msi" -OutFile $ZabbixInstaller -ErrorAction Stop
        
        $Hostname = $env:COMPUTERNAME
        $MsiArgs = @("/i", "`"$ZabbixInstaller`"", "/qn", "SERVER=$ZabbixServerIP", "SERVERACTIVE=$ZabbixServerIP", "HOSTNAME=$Hostname", "HOSTMETADATA=$Metadata", "ENABLEPATH=1")
        
        Write-Host "Instalando e configurando o Zabbix Agent 2 silenciosamente..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -Wait
        Print-Success "Zabbix Agent 2 instalado e configurado."
    } catch { Print-Error "Falha ao baixar ou instalar o Zabbix Agent 2. $($_.Exception.Message)" }
} else { Print-Success "Zabbix Agent 2 já está instalado." }

# 3. Iniciar Serviços
Print-Step "Iniciando e configurando serviços de rede"
try {
    $tailscalePath = "$env:ProgramFiles\Tailscale\tailscale.exe"
    if (-not (Test-Path $tailscalePath)) { Print-Error "Executável do Tailscale não foi encontrado." }
    
    $hostnameTailscale = "$($env:COMPUTERNAME)-zabbix"
    
    Print-Success "Conectando à rede Tailscale automaticamente..."
    $upArgs = @("up", "--authkey", $TailscaleAuthKey, "--hostname", $hostnameTailscale, "--accept-routes")
    Start-Process -FilePath $tailscalePath -ArgumentList $upArgs -Wait -NoNewWindow
    
    Print-Success "Tailscale e Zabbix Agent iniciados."
} catch { Print-Error "Falha ao configurar o Tailscale. $($_.Exception.Message)" }

# Limpeza
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Print-Step "IMPLANTAÇÃO CONCLUÍDA"
Write-Host "O host '$($env:COMPUTERNAME)' deve aparecer automaticamente no seu Zabbix em alguns minutos."
Read-Host "Pressione Enter para finalizar"