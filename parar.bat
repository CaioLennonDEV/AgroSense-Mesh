@echo off
chcp 65001 >nul
title AgroSense Mesh - Parar Sistema

cd /d "%~dp0"

echo ======================================================================
echo           AGROSENSE MESH - PAUSANDO CONTAINERS E TUNEIS
echo ===========================================================
echo.

echo [1/3] Parando tuneis Cloudflare...
docker stop agrosense-tunnel agrosense-tunnel-dashboard >nul 2>&1
docker rm agrosense-tunnel agrosense-tunnel-dashboard >nul 2>&1

echo [2/3] Parando aplicativo Mobile Web...
docker stop agrosense-mobile-web >nul 2>&1

echo [3/3] Parando cluster distribuido (docker-compose)...
docker compose stop

echo.
echo ======================================================================
echo [OK] Todos os servicos e tuneis foram pausados com sucesso!
echo      Nenhum recurso de CPU/RAM esta sendo consumido agora.
echo ======================================================================
echo.
pause
