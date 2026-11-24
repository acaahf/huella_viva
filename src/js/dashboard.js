import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser, celda } from "./ui.js";
import { descargarCsv } from "./exportCsv.js";

let filas = [];
async function consultar() {
  const periodo = Number($("#periodo").value), grupo = $("#grupo").value || null;
  const r = await supabase.rpc("dashboard_resumen", { p_period: periodo, p_grupo: grupo });
  if (r.error) return msg(r.error.message === "No autorizado" ? "No tienes permisos de administrador." : r.error.message, true);
  const m = await supabase.rpc("dashboard_muestra", { p_period: periodo });
  filas = r.data || [];
  $("#muestra").textContent = m.data ? `Participantes efectivos: ${m.data}. Sin denominador fiable: no se calcula tasa de respuesta ni se extrapola a la comunidad.`
    : "Muestra menor a 10 respuestas: se ocultan las cifras para proteger la privacidad.";
  const cuerpo = $("#filas"); cuerpo.replaceChildren();
  for (const f of filas) { const tr = document.createElement("tr");
    tr.append(celda(f.grupo), celda(f.categoria), celda(f.participantes), celda(f.promedio_kgco2e), celda(f.mediana_kgco2e)); cuerpo.append(tr); }
  msg(filas.length ? "Datos agregados (celdas con 10 o más respuestas)." : "Sin celdas publicables todavía (mínimo 10 respuestas).");
}
const user = await requireUser();
if (user) {
  const { data } = await supabase.from("survey_periods").select("id, name").order("id", { ascending: false });
  for (const p of data || []) { const o = document.createElement("option"); o.value = p.id; o.textContent = p.name; $("#periodo").append(o); }
  $("#consultar").addEventListener("click", consultar);
  $("#csv").addEventListener("click", () => filas.length ? descargarCsv(filas) : msg("No hay datos para exportar.", true));
}
