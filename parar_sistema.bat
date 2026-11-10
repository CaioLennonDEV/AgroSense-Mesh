@echo off
title AgroSense Mesh - Parar Sistema
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\parar.ps1"
echo.
echo Pressione qualquer tecla para sair...
pause >nul
