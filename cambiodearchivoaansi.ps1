$sourceFolder = "D:\www\scripts_informe_final\1.BDUCCI"   # carpeta con tus .sql 
$files = Get-ChildItem -Path $sourceFolder -Filter *.sql -Recurse

foreach ($file in $files) {
    Write-Host "Convirtiendo: $($file.FullName)"
    
    # Leer contenido con ruta literal (soporta corchetes, espacios, etc.)
    $content = Get-Content -LiteralPath $file.FullName -Raw

    # Sobrescribir con codificación ANSI (Windows-1252) sin agregar línea extra
    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::GetEncoding(1252))
}
