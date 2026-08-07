@echo off
title Inego Industrias - Sistema ERP/CRM
cd /d "%~dp0"
echo ============================================================
echo   Iniciando Sistema Integrado de Gestion - Inego Industrias
echo ============================================================
echo.
py -3 main.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error al iniciar con 'py -3'. Intentando con 'python'...
    python main.py
)
echo.
echo Presione cualquier tecla para salir...
pause
