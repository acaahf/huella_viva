$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. Eliminar fisicamente el enlace Admin de TODOS los archivos HTML del proyecto
$htmlFiles = Get-ChildItem -Path . -Recurse -Filter *.html -File | Where-Object { $_.FullName -notmatch '\\\.git\\' }
foreach ($f in $htmlFiles) {
    $html = [System.IO.File]::ReadAllText($f.FullName, $utf8NoBom)
    # Borrar cualquier <a ... href="...admin.html">Admin</a>
    $html = $html -replace '(?i)<a[^>]*href=["''][^"'']*admin\.html["''][^>]*>.*?</a>', ''
    # Asegurar que cargue navGuard.js
    if ($html -notmatch 'navGuard\.js') {
        $html = $html -replace '(?i)(</body>)', "  <script type=`"module`" src=`"./js/navGuard.js`"></script>`r`n`$1"
    }
    [System.IO.File]::WriteAllText($f.FullName, $html, $utf8NoBom)
}

# 2. Reescribir src/js/navGuard.js: crea el boton Admin SOLO si el correo es acaamano287@uan.edu.co
$navGuardJs = @'
import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function controlarAccesoAdmin() {
  const ruta = window.location.pathname.toLowerCase();
  const esPaginaAdmin = ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html");

  const { data: { user } } = await supabase.auth.getUser();
  const esAdmin = Boolean(user && (user.email || "").toLowerCase() === ADMIN_EMAIL);

  if (!esAdmin) {
    if (esPaginaAdmin) {
      window.location.replace(user ? "./encuesta.html" : "./login.html");
    }
    return;
  }

  // Solo si el usuario autenticado es acaamano287@uan.edu.co, inyectar el boton Admin en el menu
  const nav = document.querySelector(".cabecera-principal nav");
  if (nav && !nav.querySelector('a[href$="admin.html"]')) {
    const linkAdmin = document.createElement("a");
    linkAdmin.className = "btn-nav";
    linkAdmin.href = "./admin.html";
    linkAdmin.textContent = "Admin";
    nav.appendChild(linkAdmin);
  }
}

controlarAccesoAdmin();
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\js\navGuard.js"), $navGuardJs, $utf8NoBom)

# 3. Ocultar el cuerpo de admin.html, factores.html y periodos.html hasta validar el correo
foreach ($page in @("admin.html", "factores.html", "periodos.html")) {
    $p = Join-Path (Get-Location) "src\$page"
    if (Test-Path $p) {
        $h = [System.IO.File]::ReadAllText($p, $utf8NoBom)
        if ($h -notmatch 'id="admin-guard-style"') {
            $style = '<style id="admin-guard-style">body { visibility: hidden; }</style>'
            $h = $h -replace '(?i)(</head>)', "  $style`r`n`$1"
            [System.IO.File]::WriteAllText($p, $h, $utf8NoBom)
        }
    }
}

# 4. Hacer visible el cuerpo solo cuando navGuard confirme que es acaamano287@uan.edu.co
$navGuardConReveal = $navGuardJs -replace 'if \(!esAdmin\) \{', 'if (!esAdmin) {' -replace 'const nav = document\.querySelector', 'document.body.style.visibility = "visible"; const nav = document.querySelector'
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\js\navGuard.js"), $navGuardConReveal, $utf8NoBom)

# 5. Subir cambios a GitHub
git add .
git commit -m "Elimina boton Admin del HTML publico y bloquea acceso no autorizado"
git push