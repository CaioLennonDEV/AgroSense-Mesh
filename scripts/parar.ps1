# AgroSense Mesh - Script de Parada Completa
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "           AGROSENSE MESH - PAUSANDO CONTAINERS E TÚNEIS              " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/2] Parando e removendo túneis Cloudflare..." -ForegroundColor Gray
$null = docker rm -f agrosense-tunnel agrosense-tunnel-dashboard 2>&1

Write-Host "[2/2] Pausando todos os serviços do cluster distribuído..." -ForegroundColor Gray
docker compose stop

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[OK] Todos os serviços e túneis foram pausados com sucesso!" -ForegroundColor Green
Write-Host "     Nenhum recurso de CPU ou memória RAM está sendo consumido." -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
