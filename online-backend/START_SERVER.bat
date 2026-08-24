@echo off
chcp 65001 >nul
title LiveChat V13 - Servidor
cd /d "%~dp0"

echo ==============================================
echo        LiveChat V13 - Servidor Windows
echo ==============================================
echo.

where node >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Node.js nao foi encontrado neste Windows Server.
  echo.
  echo Instale o Node.js LTS e execute este arquivo novamente.
  echo https://nodejs.org/
  echo.
  pause
  exit /b 1
)

if not exist node_modules\ws (
  echo [1/2] Instalando dependencias...
  call npm install
  if errorlevel 1 (
    echo.
    echo [ERRO] Falha ao instalar dependencias.
    pause
    exit /b 1
  )
) else (
  echo [1/2] Dependencias ja instaladas.
)

echo [2/2] Iniciando servidor na porta 8080...
echo.
echo Para fechar o servidor, feche esta janela.
echo.
set PORT=8080
node server.js

pause
