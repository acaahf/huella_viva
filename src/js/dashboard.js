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