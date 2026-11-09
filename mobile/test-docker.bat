@echo off
echo =====================================================================
echo  Executando Suíte de Testes do AgroSense Mesh Mobile via Docker...
echo =====================================================================
cd /d "%~dp0"
docker compose up --build --abort-on-container-exit
pause

