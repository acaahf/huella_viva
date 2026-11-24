$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. Estilos del panel administrativo (src/css/dashboard.css)
$dashboardCss = @'
.admin-wrapper {
  max-width: 1120px;
  margin: 1.5rem auto;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.admin-header-bar {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 1.5rem 1.75rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}

.admin-header-bar h1 {
  margin: 0 0 0.25rem 0;
  font-size: 1.55rem;
  color: #111827;
}

.admin-actions {
  display: flex;
  gap: 0.65rem;
  flex-wrap: wrap;
}

/* Tarjetas KPI */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
}

.kpi-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 1.25rem 1.4rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
}

.kpi-card.highlight {
  background: linear-gradient(120deg, #166534 0%, #1d4ed8 100%);
  color: #ffffff;
  border: none;
}

.kpi-title {
  font-size: 0.85rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  opacity: 0.8;
  margin-bottom: 0.45rem;
}

.kpi-value {
  font-size: 2rem;
  font-weight: 800;
  line-height: 1.15;
}

.kpi-sub {
  font-size: 0.82rem;
  margin-top: 0.35rem;
  opacity: 0.85;
}

/* Grid de graficos */
.charts-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.15rem;
}

@media (min-width: 860px) {
  .charts-grid {
    grid-template-columns: 1fr 1fr;
  }
}

.panel-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 1.4rem 1.6rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
}

.panel-card h2 {
  margin: 0 0 1rem 0;
  font-size: 1.1rem;
  color: #111827;
}

.chart-row {
  display: grid;
  grid-template-columns: 155px 1fr 85px;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.85rem;
  font-size: 0.9rem;
}

.chart-label {
  font-weight: 600;
  color: #374151;
}

.chart-track {
  width: 100%;
  height: 14px;
  background: #f3f4f6;
  border-radius: 999px;
  overflow: hidden;
}

.chart-fill-blue {
  height: 100%;
  background: #1d4ed8;
  border-radius: 999px;
  min-width: 6px;
}

.chart-fill-green {
  height: 100%;
  background: #15803d;
  border-radius: 999px;
  min-width: 6px;
}

.chart-val {
  text-align: right;
  font-weight: 700;
  color: #1f2937;
  font-size: 0.86rem;
}

/* Filtros y tabla de participantes */
.table-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.filter-group {
  display: flex;
  gap: 0.65rem;
  flex-wrap: wrap;
}

.filter-input, .filter-select {
  padding: 0.55rem 0.85rem;
  border: 1.5px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.9rem;
}

.tabla-datos {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.92rem;
}

.tabla-datos th {
  background: #1e3a8a;
  color: #ffffff;
  padding: 0.75rem 0.85rem;
  text-align: left;
  font-weight: 700;
}

.tabla-datos td {
  border-bottom: 1px solid #e5e7eb;
  padding: 0.75rem 0.85rem;
  color: #1f2937;
}

.tabla-datos tr:hover td {
  background: #f9fafb;
}

.badge-role {
  display: inline-block;
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 700;
  text-transform: capitalize;
  background: #e0e7ff;
  color: #1e40af;
}

.badge-status-ok {
  display: inline-block;
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 700;
  background: #dcfce7;
  color: #166534;
}

.badge-status-draft {
  display: inline-block;
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 700;
  background: #fef3c7;
  color: #92400e;
}
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\css\dashboard.css"), $dashboardCss, $utf8NoBom)

# 2. Actualizar src/admin.html
$adminHtml = @'
<!DOCTYPE html>
<html lang="es-CO">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Panel Administrativo — HuellaViva UAN</title>
  <link rel="stylesheet" href="./css/base.css">
  <link rel="stylesheet" href="./css/componentes.css">
  <link rel="stylesheet" href="./css/dashboard.css">
</head>
<body>
  <aside class="banner-institucional" role="note">
    <strong>Prototipo Académico — HuellaViva UAN:</strong> Estimador educativo y de diagnóstico institucional. NO es un inventario verificado, certificación ambiental ni resultado oficial de RENARE.
  </aside>
  <header class="cabecera-principal">
    <a class="marca" href="./index.html">
      <img src="../assets/logo-huellaviva.svg" alt="Icono HuellaViva UAN">
      <span>HuellaViva UAN</span>
    </a>
    <nav aria-label="Principal">
      <a class="btn-nav" href="./encuesta.html">Encuesta</a>
      <a class="btn-nav" href="./informe.html">Mi Informe</a>
      <a class="btn-nav" href="./derechos.html">Derechos</a>
      <a class="btn-nav" href="./admin.html">Admin</a>
    </nav>
  </header>

  <main class="contenedor">
    <div class="admin-wrapper">
      <section class="admin-header-bar">
        <div>
          <h1>Panel Administrativo — HuellaViva UAN</h1>
          <p id="admin-periodo-info" style="margin:0; color:#4b5563;">Verificando periodo activo y permisos...</p>
        </div>
        <div class="admin-actions">
          <a class="btn-secundario" href="./factores.html">Gestionar Factores</a>
          <a class="btn-secundario" href="./periodos.html">Gestionar Periodos</a>
          <button id="btn-exportar-csv" class="btn-primario" type="button">Exportar CSV</button>
        </div>
      </section>

      <div id="admin-contenido" aria-live="polite">
        <div class="panel-card"><p>Cargando indicadores y encuestas registradas...</p></div>
      </div>
    </div>
  </main>

  <script type="module" src="./js/dashboard.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\admin.html"), $adminHtml, $utf8NoBom)

# 3. Actualizar src/js/dashboard.js con KPIs, graficos y listado de participantes
$dashboardJs = @'
import { supabase } from "./supabaseClient.js";

const adminContenido = document.getElementById("admin-contenido");
const periodoInfoEl = document.getElementById("admin-periodo-info");
const btnCsv = document.getElementById("btn-exportar-csv");

let participantesGlobal = [];
let categoriasGlobal = [];

function formatNum(n, dec = 1) {
  return Number(n || 0).toFixed(dec).replace(".", ",");
}

function traducirCategoria(cat) {
  const map = {
    desplazamiento_campus: "🚌 Movilidad al campus",
    electricidad: "⚡ Energía en casa",
    gas_combustibles: "🔥 Gas / Cocina"
  };
  return map[cat] || cat;
}

function renderTablaParticipantes(lista) {
  const tbody = document.getElementById("tbody-participantes");
  const contadorEl = document.getElementById("contador-filtrados");
  if (!tbody) return;

  if (contadorEl) {
    contadorEl.textContent = `Mostrando ${lista.length} de ${participantesGlobal.length} registros`;
  }

  if (lista.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:#6b7280;">No se encontraron encuestas con ese filtro.</td></tr>`;
    return;
  }

  tbody.innerHTML = lista.map((p) => {
    const fecha = p.submitted_at
      ? new Date(p.submitted_at).toLocaleString("es-CO", { dateStyle: "medium", timeStyle: "short" })
      : "Sin enviar";
    const anual = Number(p.total_kgco2e || 0);
    const mensual = anual / 12;
    const badgeEstado = p.estado === "enviada"
      ? `<span class="badge-status-ok">Enviada</span>`
      : `<span class="badge-status-draft">Borrador</span>`;

    return `
      <tr>
        <td><strong>${p.correo}</strong></td>
        <td><span class="badge-role">${p.tipo_usuario}</span></td>
        <td>${badgeEstado}</td>
        <td>${fecha}</td>
        <td><strong>${formatNum(mensual, 1)} kg</strong> / mes</td>
        <td>${formatNum(anual, 2)} kg / año</td>
      </tr>
    `;
  }).join("");
}

function aplicarFiltros() {
  const texto = (document.getElementById("filtro-correo")?.value || "").toLowerCase().trim();
  const rol = document.getElementById("filtro-rol")?.value || "todos";

  const filtrados = participantesGlobal.filter((p) => {
    const coincideCorreo = !texto || (p.correo || "").toLowerCase().includes(texto);
    const coincideRol = rol === "todos" || p.tipo_usuario === rol;
    return coincideCorreo && coincideRol;
  });

  renderTablaParticipantes(filtrados);
}

async function cargarDashboard() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }

  const { data: period } = await supabase
    .from("survey_periods")
    .select("*")
    .eq("is_open", true)
    .limit(1)
    .maybeSingle();

  if (!period) {
    periodoInfoEl.textContent = "No hay periodos abiertos actualmente.";
    adminContenido.innerHTML = `<div class="panel-card"><p>No hay periodos activos para consultar.</p></div>`;
    return;
  }

  periodoInfoEl.textContent = `Periodo activo: ${period.name} (${period.code})`;

  const { data, error } = await supabase.rpc("get_admin_dashboard_data", {
    p_period_id: period.id
  });

  if (error) {
    adminContenido.innerHTML = `
      <div class="panel-card" style="border-color:#fca5a5; background:#fef2f2; color:#991b1b;">
        <h2>Acceso restringido</h2>
        <p>${error.message}</p>
        <p style="font-size:0.88rem;">Asegúrate de haber ejecutado el script SQL de administrador en Supabase para tu cuenta (${user.email}).</p>
      </div>
    `;
    return;
  }

  participantesGlobal = data?.participantes || [];
  categoriasGlobal = data?.categorias || [];

  const enviadas = participantesGlobal.filter((p) => p.estado === "enviada");
  const totalEnviadas = enviadas.length;
  const sumaAnual = enviadas.reduce((acc, p) => acc + Number(p.total_kgco2e || 0), 0);
  const promedioAnual = totalEnviadas > 0 ? sumaAnual / totalEnviadas : 0;
  const promedioMensual = promedioAnual / 12;

  // Agrupar por estamento (tipo_usuario)
  const gruposMap = {};
  for (const p of enviadas) {
    const rol = p.tipo_usuario || "estudiante";
    if (!gruposMap[rol]) gruposMap[rol] = { rol, count: 0, sumaAnual: 0 };
    gruposMap[rol].count += 1;
    gruposMap[rol].sumaAnual += Number(p.total_kgco2e || 0);
  }
  const gruposLista = Object.values(gruposMap).sort((a, b) => b.count - a.count);
  const maxGrupoCount = Math.max(...gruposLista.map((g) => g.count), 1);
  const maxCatTotal = Math.max(...categoriasGlobal.map((c) => Number(c.total_kgco2e || 0)), 1);

  adminContenido.innerHTML = `
    <section class="kpi-grid">
      <div class="kpi-card highlight">
        <div class="kpi-title">Encuestas completadas</div>
        <div class="kpi-value">${totalEnviadas}</div>
        <div class="kpi-sub">${participantesGlobal.length} registros totales (incl. borradores)</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">Huella promedio mensual</div>
        <div class="kpi-value">${formatNum(promedioMensual, 1)} kg</div>
        <div class="kpi-sub">CO₂e por participante / mes</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">Huella promedio anual</div>
        <div class="kpi-value">${formatNum(promedioAnual, 1)} kg</div>
        <div class="kpi-sub">${formatNum(promedioAnual / 1000, 3)} t CO₂e / año</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">Emisiones acumuladas</div>
        <div class="kpi-value">${formatNum(sumaAnual / 1000, 2)} t</div>
        <div class="kpi-sub">${formatNum(sumaAnual, 1)} kg CO₂e totales en el periodo</div>
      </div>
    </section>

    <section class="charts-grid" style="margin-top:1.25rem;">
      <div class="panel-card">
        <h2>Emisiones totales por categoría</h2>
        ${categoriasGlobal.length === 0 ? `<p style="color:#6b7280;">Sin datos de categorías aún.</p>` : categoriasGlobal.map((c) => {
          const val = Number(c.total_kgco2e || 0);
          const pct = Math.max(5, Math.round((val / maxCatTotal) * 100));
          return `
            <div class="chart-row">
              <div class="chart-label">${traducirCategoria(c.categoria)}</div>
              <div class="chart-track"><div class="chart-fill-blue" style="width:${pct}%"></div></div>
              <div class="chart-val">${formatNum(val, 1)} kg</div>
            </div>
          `;
        }).join("")}
      </div>

      <div class="panel-card">
        <h2>Participación y promedio por estamento</h2>
        ${gruposLista.length === 0 ? `<p style="color:#6b7280;">Sin participantes registrados aún.</p>` : gruposLista.map((g) => {
          const pct = Math.max(8, Math.round((g.count / maxGrupoCount) * 100));
          const promMes = (g.sumaAnual / g.count) / 12;
          return `
            <div class="chart-row">
              <div class="chart-label" style="text-transform:capitalize;">${g.rol} (${g.count})</div>
              <div class="chart-track"><div class="chart-fill-green" style="width:${pct}%"></div></div>
              <div class="chart-val">${formatNum(promMes, 1)} kg/mes</div>
            </div>
          `;
        }).join("")}
      </div>
    </section>

    <section class="panel-card" style="margin-top:1.25rem;">
      <div class="table-toolbar">
        <div>
          <h2 style="margin:0;">Registro de participantes (¿Quién hizo la encuesta?)</h2>
          <span id="contador-filtrados" style="font-size:0.84rem; color:#6b7280;"></span>
        </div>
        <div class="filter-group">
          <input type="text" id="filtro-correo" class="filter-input" placeholder="Buscar por correo...">
          <select id="filtro-rol" class="filter-select">
            <option value="todos">Todos los estamentos</option>
            <option value="estudiante">Estudiantes</option>
            <option value="profesor">Profesores</option>
            <option value="administrativo">Administrativos</option>
          </select>
        </div>
      </div>

      <div style="overflow-x:auto;">
        <table class="tabla-datos">
          <thead>
            <tr>
              <th>Correo institucional</th>
              <th>Estamento</th>
              <th>Estado</th>
              <th>Fecha de envío</th>
              <th>Huella mensual</th>
              <th>Huella anual</th>
            </tr>
          </thead>
          <tbody id="tbody-participantes"></tbody>
        </table>
      </div>
    </section>
  `;

  document.getElementById("filtro-correo")?.addEventListener("input", aplicarFiltros);
  document.getElementById("filtro-rol")?.addEventListener("change", aplicarFiltros);
  aplicarFiltros();
}

btnCsv?.addEventListener("click", () => {
  if (participantesGlobal.length === 0) return;
  const encabezados = ["Correo", "Estamento", "Estado", "Fecha_Envio", "Huella_Mensual_kgCO2e", "Huella_Anual_kgCO2e"];
  const filas = participantesGlobal.map((p) => {
    const anual = Number(p.total_kgco2e || 0);
    const mensual = (anual / 12).toFixed(2);
    return [
      `"${p.correo}"`,
      `"${p.tipo_usuario}"`,
      `"${p.estado}"`,
      `"${p.submitted_at || ""}"`,
      mensual,
      anual.toFixed(4)
    ].join(",");
  });
  const csvContent = "\uFEFF" + [encabezados.join(","), ...filas].join("\n");
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "huellaviva_uan_participantes.csv";
  a.click();
});

cargarDashboard();
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "src\js\dashboard.js"), $dashboardJs, $utf8NoBom)

# 4. Subir cambios a GitHub
git add src/css/dashboard.css src/admin.html src/js/dashboard.js
git commit -m "Agrega panel administrativo con dashboards KPI, graficos y listado de participantes"
git push