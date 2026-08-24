@echo off
chcp 65001 >nul
title LiveChat V13 - Liberar Porta 8080

echo ==============================================
echo     LiveChat V13 - Liberar porta 8080
echo ==============================================
echo.

echo Este arquivo precisa ser executado como Administrador.
echo.

netsh advfirewall firewall add rule name="LiveChat V13 TCP 8080" dir=in action=allow protocol=TCP localport=8080

if errorlevel 1 (
  echo.
  echo [ERRO] Nao foi possivel criar a regra.
  echo Clique com o botao direito neste arquivo e escolha:
  echo Executar como administrador.
) else (
  echo.
  echo [OK] Porta TCP 8080 liberada no Firewall do Windows.
)

echo.
pause
