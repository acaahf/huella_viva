$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. Proteger src/js/dashboard.js para redirigir si el correo no es acaamano287@uan.edu.co
$dashPath = Join-Path (Get-Location) "src\js\dashboard.js"
$dashCode = [System.IO.File]::ReadAllText($dashPath, $utf8NoBom)

$guard = @'
const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function cargarDashboard() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }
  if ((user.email || "").toLowerCase() !== ADMIN_EMAIL) {
    window.location.href = "./encuesta.html";
    return;
  }
'@

$dashCode = $dashCode -replace '(?s)async function cargarDashboard\(\)\s*\{.*?return;\s*\}', $guard
[System.IO.File]::WriteAllText($dashPath, $dashCode, $utf8NoBom)

# 2. Ocultar el boton Admin en la barra superior para cualquier otro usuario
$navGuardJs = @'
import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function filtrarNavAdmin() {
  const linksAdmin = document.querySelectorAll('a[href$="admin.html"], a[href$="factores.html"], a[href$="periodos.html"]');
  if (linksAdmin.length === 0) return;

  const { data: { user } } = await supabase.auth.getUser();
  const esAdmin = user && (user.email || "").toLowerCase() === ADMIN_EMAIL;

  if (!esAdmin) {
    linksAdmin.forEach((el) => { el.style.display = "none"; });
    const ruta = window.location.pathname.toLowerCase();
    if (ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html")) {
      window.location.href = user ? "./encuesta.html" : "./login.html";
    }
  }
}

filtrarNavAdmin();
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\js\navGuard.js"), $navGuardJs, $utf8NoBom)

# 3. Inyectar navGuard.js en todas las paginas HTML de src/
Get-ChildItem -Path src -Filter *.html -File | ForEach-Object {
    $html = [System.IO.File]::ReadAllText($_.FullName, $utf8NoBom)
    if ($html -notmatch 'navGuard\.js') {
        $html = $html -replace '(?i)(</body>)', "  <script type=`"module`" src=`"./js/navGuard.js`"></script>`r`n`$1"
        [System.IO.File]::WriteAllText($_.FullName, $html, $utf8NoBom)
    }
}

git add src/
git commit -m "Restringe acceso administrativo exclusivamente a acaamano287@uan.edu.co"
git push