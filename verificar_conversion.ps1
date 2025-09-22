# Script para verificar y forzar la conversion a ANSI
$sourceFolder = "D:\www\scripts_informe_final\1.BDUCCI"
$files = Get-ChildItem -Path $sourceFolder -Filter *.sql -Recurse

Write-Host "=== VERIFICANDO Y CONVIRTIENDO ARCHIVOS A ANSI ===" -ForegroundColor Green

foreach ($file in $files) {
    Write-Host "Procesando: $($file.Name)" -ForegroundColor Yellow
    
    try {
        # Leer el contenido del archivo
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        
        # Escribir con codificacion ANSI/Windows-1252
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::GetEncoding("windows-1252"))
        
        Write-Host "  Convertido exitosamente" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=== CONVERSION COMPLETADA ===" -ForegroundColor Green