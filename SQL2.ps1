$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. Convertir index.html (tanto en raiz como en src/) en una redireccion directa a login.html
$redirectHtml = @'
<!DOCTYPE html>
<html lang="es-CO">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0; url=./src/login.html">
  <title>HuellaViva UAN</title>
  <script>
    window.location.replace("./src/login.html");
  </script>
</head>
<body></body>
</html>
'@

if (Test-Path "index.html") {
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) "index.html"), $redirectHtml, $utf8NoBom)
}

$srcIndexHtml = @'
<!DOCTYPE html>
<html lang="es-CO">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0; url=./login.html">
  <title>HuellaViva UAN</title>
  <script>
    window.location.replace("./login.html");
  </script>
</head>
<body></body>
</html>
'@

if (Test-Path "src\index.html") {
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\index.html"), $srcIndexHtml, $utf8NoBom)
}

# 2. Quitar los botones del menu superior (Encuesta, Mi Informe, Derechos, Admin) de login.html
$loginPath = Join-Path (Get-Location) "src\login.html"
if (Test-Path $loginPath) {
    $loginHtml = [System.IO.File]::ReadAllText($loginPath, $utf8NoBom)
    $loginHtml = $loginHtml -replace '(?s)<nav[^>]*>.*?</nav>', ''
    $loginHtml = $loginHtml -replace 'href="\./index\.html"', 'href="./login.html"'
    [System.IO.File]::WriteAllText($loginPath, $loginHtml, $utf8NoBom)
}

# 3. Asegurar que los enlaces de la marca en las demas paginas apunten a encuesta.html en lugar de index.html
Get-ChildItem -Path src -Filter *.html -File | Where-Object { $_.Name -ne "index.html" -and $_.Name -ne "login.html" } | ForEach-Object {
    $h = [System.IO.File]::ReadAllText($_.FullName, $utf8NoBom)
    $h = $h -replace 'href="\./index\.html"', 'href="./encuesta.html"'
    [System.IO.File]::WriteAllText($_.FullName, $h, $utf8NoBom)
}

# 4. Subir cambios a GitHub
git add .
git commit -m "Elimina pantalla inicial intermedia y redirige directo a login"
git push