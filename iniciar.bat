@echo off
chcp 65001 >nul
title AgroSense Mesh - Inicializador Automatico com Tuneis

cd /d "%~dp0"

echo ======================================================================
echo    AGROSENSE MESH - INICIALIZANDO CLUSTER E TUNEIS PUBLICOS
echo ======================================================================
echo.

:: 1. Verifica se o Docker esta rodando
echo [1/5] Verificando Docker Desktop...
docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [!] O Docker Desktop nao esta ativo. Iniciando automaticamente...
    start "" "C:\Users\Caio Lennon\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe"
    echo Aguardando inicializacao do Docker daemon...
    :wait_docker
    timeout /t 3 /nobreak >nul
    docker info >nul 2>&1
    if %ERRORLEVEL% NEQ 0 goto wait_docker
    echo [OK] Docker Desktop pronto!
) else (
    echo [OK] Docker Desktop ja esta em execucao!
)
echo.

:: 2. Sobe o cluster distribuido (RabbitMQ, Postgres, Workers, Gateway, Simulator, Web)
echo [2/5] Subindo cluster distribuido (docker-compose)...
docker compose up -d
echo [OK] Cluster de backend operacional!
echo.

:: 3. Garante que o App Mobile Flutter Web esta rodando na porta 8080
echo [3/5] Verificando container do Mobile Flutter Web...
docker start agrosense-mobile-web >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Criando container agrosense-mobile-web na porta 8080...
    docker run -d --name agrosense-mobile-web -p 8080:8080 --restart unless-stopped mobile-agrosense-mobile-web >nul 2>&1
)
echo [OK] Mobile Web ativo na porta 8080!
echo.

:: 4. Reinicia os tuneis Cloudflare para gerar URLs limpas e ativas
echo [4/5] Conectando tuneis Cloudflare HTTPS externos...
docker rm -f agrosense-tunnel agrosense-tunnel-dashboard >nul 2>&1
docker run -d --name agrosense-tunnel --restart unless-stopped cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:8080 >nul 2>&1
docker run -d --name agrosense-tunnel-dashboard --restart unless-stopped cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:3000 >nul 2>&1

echo Aguardando conexao dos tuneis (5 segundos)...
timeout /t 5 /nobreak >nul
echo.

:: 5. Captura as URLs publicas geradas
echo [5/5] Resgatando links publicos...
for /f "delims=" %%i in ('powershell -NoProfile -Command "(docker logs agrosense-tunnel 2>&1 | Select-String -Pattern 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' | Select-Object -Last 1).Matches.Value"') do set URL_MOBILE=%%i
for /f "delims=" %%i in ('powershell -NoProfile -Command "(docker logs agrosense-tunnel-dashboard 2>&1 | Select-String -Pattern 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' | Select-Object -Last 1).Matches.Value"') do set URL_DASH=%%i

cls
echo ======================================================================
echo           AGROSENSE MESH - TUDO PRONTO E OPERACIONAL!
echo ======================================================================
echo.
echo [1] APLICATIVO MOBILE (FLUTTER OFFLINE-FIRST - PORTA 8080):
echo     - Local:   http://localhost:8080
echo     - Publico: %URL_MOBILE%
echo.
echo [2] DASHBOARD DISTRIBUIDO (FASTIFY + WEBSOCKET - PORTA 3000):
echo     - Local:   http://localhost:3000
echo     - Publico: %URL_DASH%
echo.
echo ======================================================================
echo  DICA: Copie os links acima ou aponte a camera do celular para testar!
echo  Para desligar tudo depois, basta executar: parar_sistema.bat
echo ======================================================================
echo.

set /p ABRIR="Deseja abrir os links no seu navegador agora? (S/N): "
if /i "%ABRIR%"=="S" (
    if defined URL_MOBILE start %URL_MOBILE%
    if defined URL_DASH start %URL_DASH%
)

echo.
echo Pressione qualquer tecla para fechar esta janela (o sistema continua rodando no Docker)...
pause >nul
