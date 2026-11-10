@echo off
title AgroSense Mesh - Inicializador
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\iniciar.ps1"
echo.
echo Janela finalizada. Pressione qualquer tecla para sair...
pause >nul

