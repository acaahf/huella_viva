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

$archivos = Get-ChildItem -Path src -Recurse -Include *.html,*.js,*.css -File
foreach ($archivo in $archivos) {
    $bytes = [System.IO.File]::ReadAllBytes($archivo.FullName)
    $texto = Fix-Mojibake ($utf8NoBom.GetString($bytes))
    [System.IO.File]::WriteAllText($archivo.FullName, $texto, $utf8NoBom)
}

git add src/
git commit -m "Normaliza UTF-8 en panel administrativo"
git push