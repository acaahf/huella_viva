import { supabase } from "./supabaseClient.js";
import { generarCsvAgregado } from "./exportCsv.js";
import { APP_CONFIG } from "./config.js";

let ultimasFilas = [];
const tablaContenedor = document.getElementById("tabla-dashboard");
const btnCsv = document.getElementById("btn-exportar-csv");

async function cargarDashboard() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }

  const { data: period } = await supabase.from("survey_periods").select("*").eq("is_open", true).limit(1).maybeSingle();
  if (!period) {
    tablaContenedor.textContent = "No hay periodos activos para consultar.";
    return;
  }

  const { data, error } = await supabase.rpc("get_aggregated_metrics", {
    p_period_id: period.id,
    p_campus: null,
    p_tipo_usuario: null,
    p_min_cell: APP_CONFIG.MIN_CELL_PRIVACY
  });

  if (error) {
    tablaContenedor.textContent = `Acceso restringido o error: ${error.message}`;
    return;
  }

  ultimasFilas = data || [];
  if (ultimasFilas.length === 0) {
    tablaContenedor.textContent = "Aun no hay encuestas enviadas en este periodo.";
    return;
  }

  const filasHtml = ultimasFilas.map((r) => `
    <tr>
      <td>${r.tipo_usuario}</td>
      <td>${r.campus}</td>
      <td>${r.participantes}</td>
      <td>${r.oculto_por_privacidad ? '<span class="oculto-privacidad">Oculto (&lt;10 respuestas)</span>' : `${r.promedio_kgco2e} kg CO2e`}</td>
      <td>${r.oculto_por_privacidad ? '<span class="oculto-privacidad">Oculto (&lt;10 respuestas)</span>' : `${r.mediana_kgco2e} kg CO2e`}</td>
    </tr>
  `).join("");

  tablaContenedor.innerHTML = `
    <p><strong>Periodo:</strong> ${period.name} | <strong>Denominador institucional:</strong> ${period.expected_population ?? "No cargado (no se calcula tasa de respuesta)"}</p>
    <table class="tabla-datos">
      <thead><tr><th>Grupo</th><th>Campus</th><th>Participantes (n)</th><th>Promedio</th><th>Mediana</th></tr></thead>
      <tbody>${filasHtml}</tbody>
    </table>
  `;
}

btnCsv?.addEventListener("click", () => {
  const csv = generarCsvAgregado(ultimasFilas);
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "huellaviva_uan_agregado.csv";
  a.click();
});

cargarDashboard();