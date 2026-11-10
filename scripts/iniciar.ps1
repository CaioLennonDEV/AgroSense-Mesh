# AgroSense Mesh - Script de Inicialização Completa
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "    AGROSENSE MESH - INICIALIZANDO CLUSTER E TÚNEIS PÚBLICOS" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verifica se o Docker Desktop está rodando
Write-Host "[1/4] Verificando Docker Desktop..." -ForegroundColor Yellow
$dockerOk = $false
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerOk = $true }
} catch {
    $dockerOk = $false
}

if (-not $dockerOk) {
    Write-Host "[!] Docker não está ativo. Iniciando Docker Desktop..." -ForegroundColor Magenta
    Start-Process "C:\Users\Caio Lennon\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe"
    Write-Host "Aguardando inicialização do Docker..." -NoNewline
    while (-not $dockerOk) {
        Start-Sleep -Seconds 3
        Write-Host "." -NoNewline
        try {
            $null = docker info 2>&1
            if ($LASTEXITCODE -eq 0) { $dockerOk = $true }
        } catch {}
    }
    Write-Host "`n[OK] Docker Desktop pronto!" -ForegroundColor Green
} else {
    Write-Host "[OK] Docker Desktop já está em execução!" -ForegroundColor Green
}
Write-Host ""

# 2. Sobe todos os 10 serviços do docker-compose
Write-Host "[2/4] Subindo cluster distribuído e Mobile Web..." -ForegroundColor Yellow
docker compose up -d
Write-Host "[OK] Todos os serviços (RabbitMQ, Postgres, Workers, Gateway, Web, Mobile) operacionais!" -ForegroundColor Green
Write-Host ""

# 3. Reinicia os túneis Cloudflare para gerar URLs limpas
Write-Host "[3/4] Conectando túneis Cloudflare HTTPS externos..." -ForegroundColor Yellow
$null = docker rm -f agrosense-tunnel agrosense-tunnel-dashboard 2>&1
$null = docker run -d --name agrosense-tunnel --restart unless-stopped cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:8080 2>&1
$null = docker run -d --name agrosense-tunnel-dashboard --restart unless-stopped cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:3000 2>&1

Write-Host "Aguardando conexões dos túneis com a rede global..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Write-Host ""

# 4. Resgata as URLs públicas dos logs
Write-Host "[4/4] Resgatando links públicos HTTPS..." -ForegroundColor Yellow
$urlMobile = ""
$urlDash = ""

for ($tentativa = 1; $tentativa -le 5; $tentativa++) {
    $logMobile = docker logs agrosense-tunnel 2>&1 | Out-String
    $logDash   = docker logs agrosense-tunnel-dashboard 2>&1 | Out-String

    if ($logMobile -match '(https://[a-zA-Z0-9.-]+\.trycloudflare\.com)') {
        $urlMobile = $matches[1]
    }
    if ($logDash -match '(https://[a-zA-Z0-9.-]+\.trycloudflare\.com)') {
        $urlDash = $matches[1]
    }

    if ($urlMobile -and $urlDash) { break }
    Start-Sleep -Seconds 2
}

Clear-Host
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "           AGROSENSE MESH - TUDO PRONTO E OPERACIONAL!                " -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1] APLICATIVO MOBILE (FLUTTER OFFLINE-FIRST - PORTA 8080):" -ForegroundColor White
Write-Host "    - Local:   http://localhost:8080" -ForegroundColor Gray
Write-Host "    - Público: $urlMobile" -ForegroundColor Yellow
Write-Host ""
Write-Host "[2] DASHBOARD DISTRIBUÍDO (FASTIFY + WEBSOCKET - PORTA 3000):" -ForegroundColor White
Write-Host "    - Local:   http://localhost:3000" -ForegroundColor Gray
Write-Host "    - Público: $urlDash" -ForegroundColor Yellow
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " DICA: Copie os links amarelos ou abra no celular (fora do Wi-Fi)!" -ForegroundColor White
Write-Host " Para desligar tudo depois, dê dois cliques em: parar_sistema.bat" -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$resposta = Read-Host "Deseja abrir os dois links públicos no seu navegador agora? (S/N)"
if ($resposta -match '^[Ss]') {
    if ($urlMobile) { Start-Process $urlMobile }
    if ($urlDash)   { Start-Process $urlDash }
}

