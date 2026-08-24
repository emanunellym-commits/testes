@echo off
chcp 65001 >nul
title LiveChat V13 - Teste do Servidor

echo ==============================================
echo        LiveChat V13 - Teste local
echo ==============================================
echo.

powershell -NoProfile -Command "try { $r=Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health -TimeoutSec 5; Write-Host '[OK] Servidor respondeu:' $r.Content -ForegroundColor Green } catch { Write-Host '[ERRO] Servidor nao respondeu em http://127.0.0.1:8080/health' -ForegroundColor Red }"

echo.
pause
