@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Ruta de archivos SQL
set "FOLDER=D:\www\scripts_informe_final\1.BDUCCI"
echo "FOLDER: %FOLDER%"

:: Parámetros de conexión
set "SERVER=20.0.3.240,1433"
set "DATABASE=BDUCCI"
set "USER=ssapplinux"
set "PASS=killbducci4me"

echo.
echo ========================================
echo INICIANDO EJECUCION DE SCRIPTS SQL
echo ========================================
echo.

:: Función recursiva para buscar archivos SQL
call :ProcessFolder "%FOLDER%"

echo.
echo ========================================
echo EJECUCION COMPLETADA
echo ========================================
pause
exit /b

:ProcessFolder
set "current_folder=%~1"
echo.
echo ----------------------------------------
echo Procesando carpeta: %current_folder%
echo ----------------------------------------

:: Buscar archivos SQL en la carpeta actual
for %%f in ("%current_folder%\*.sql") do (
    echo.
    echo --- Ejecutando: %%~nxf ---
    sqlcmd -S %SERVER% -d %DATABASE% -U %USER% -P %PASS% -i "%%f" -f 65001
    if !errorlevel! neq 0 (
        echo ERROR: Fallo al ejecutar "%%f"
    )
)

:: Buscar subcarpetas y procesarlas recursivamente
for /d %%d in ("%current_folder%\*") do (
    call :ProcessFolder "%%d"
)
exit /b