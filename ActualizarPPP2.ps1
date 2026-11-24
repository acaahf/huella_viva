$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$win1252 = [System.Text.Encoding]::GetEncoding(1252)

function Fix-Mojibake([string]$s) {
    $result = $s
    for ($i = 0; $i -lt 3; $i++) {
        $bytes = $win1252.GetBytes($result)
        $decoded = $utf8NoBom.GetString($bytes)
        if ($decoded -notmatch '\uFFFD' -and $decoded -ne $result) {
            $result = $decoded
        } else {
            break
        }
    }
    return $result
}

$archivos = Get-ChildItem -Path . -Recurse -Include *.html,*.js,*.css,*.sql -File |
    Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\dist\\' }

$reparados = 0

foreach ($archivo in $archivos) {
    $bytes = [System.IO.File]::ReadAllBytes($archivo.FullName)
    $texto = $utf8NoBom.GetString($bytes)
    $original = $texto

    $texto = Fix-Mojibake $texto

    if ($archivo.Extension -eq ".html" -and $texto -notmatch '(?i)<meta\s+charset=["'']?utf-8["'']?') {
        $texto = $texto -replace '(?i)(<head[^>]*>)', "`$1`r`n  <meta charset=`"UTF-8`">"
    }

    [System.IO.File]::WriteAllText($archivo.FullName, $texto, $utf8NoBom)

    if ($texto -ne $original) {
        Write-Host "  [UTF-8 REPARADO] $($archivo.Name)" -ForegroundColor Green
        $reparados++
    }
}

Write-Host "`nTotal de archivos reparados en UTF-8: $reparados" -ForegroundColor Cyan

git add .
git commit -m "Normaliza informe y proyecto completo en UTF-8 sin BOM"
git push