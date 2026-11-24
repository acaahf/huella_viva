$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. Quitar el visibility: hidden de admin.html, factores.html y periodos.html para que nunca queden en blanco
foreach ($page in @("admin.html", "factores.html", "periodos.html")) {
    $p = Join-Path (Get-Location) "src\$page"
    if (Test-Path $p) {
        $h = [System.IO.File]::ReadAllText($p, $utf8NoBom)
        $h = $h -replace '<style id="admin-guard-style">.*?</style>', ''
        [System.IO.File]::WriteAllText($p, $h, $utf8NoBom)
    }
}

# 2. Asegurar que navGuard.js inyecte el boton Admin en TODAS las paginas (excepto login) cuando el correo sea acaamano287@uan.edu.co
$navGuardJs = @'
import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function controlarAccesoAdmin() {
  const ruta = window.location.pathname.toLowerCase();
  const esPaginaAdmin = ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html");
  const esLogin = ruta.endsWith("login.html");

  const { data: { user } } = await supabase.auth.getUser();
  const esAdmin = Boolean(user && (user.email || "").toLowerCase() === ADMIN_EMAIL);

  if (!esAdmin) {
    if (esPaginaAdmin) {
      window.location.replace(user ? "./encuesta.html" : "./login.html");
    }
    return;
  }

  if (!esLogin) {
    const nav = document.querySelector(".cabecera-principal nav");
    if (nav && !nav.querySelector('a[href$="admin.html"]')) {
      const linkAdmin = document.createElement("a");
      linkAdmin.className = "btn-nav";
      linkAdmin.href = "./admin.html";
      linkAdmin.textContent = "Admin";
      nav.appendChild(linkAdmin);
    }
  }
}

controlarAccesoAdmin();
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\js\navGuard.js"), $navGuardJs, $utf8NoBom)

# 3. Corregir redireccion en index.html (raiz y src/) para que funcione en GitHub Pages
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

git add .
git commit -m "Restaura visibilidad de admin.html y enlace dinamico exclusivo para acaamano287@uan.edu.co"
git push