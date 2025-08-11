@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Ruta de archivos SQL
set "FOLDER=D:\sql\SCRIPTS_REPORTE INFORME FINAL\SCRIPTSV2\1.BDUCCI\1.InformeFinal_y_certificaciones_progresivas"

:: Parámetros de conexión
set "SERVER=20.0.3.240,1433"
set "DATABASE=BDUCCI"
set "USER=ssapplinux"
set "PASS=killbducci4me"

:: Ejecutar cada archivo .sql
for %%f in ("%FOLDER%\*.sql") do (
    echo.
    echo --- Ejecutando: %%~nxf ---
    sqlcmd -S %SERVER% -d %DATABASE% -U %USER% -P %PASS% -i "%%f" -f 65001
)
pause
