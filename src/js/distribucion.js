// Distribución del total individual y versión metodológica del periodo (complementa dashboard.js)
import { supabase } from "./supabaseClient.js";
import { $, msg, celda } from "./ui.js";
$("#consultar")?.addEventListener("click", async () => {
  const p = Number($("#periodo").value);
  const { data: per } = await supabase.from("survey_periods").select("methodology_version, status").eq("id", p).maybeSingle();
  $("#version").textContent = per ? `Versión metodológica: ${per.methodology_version} · periodo ${per.status}` : "";
  const { data, error } = await supabase.rpc("dashboard_distribucion", { p_period: p });
  const cuerpo = $("#dist"); cuerpo.replaceChildren();
  if (error) return msg(error.message, true);
  const max = Math.max(1, ...(data || []).map((d) => Number(d.participantes)));
  for (const d of data || []) {
    const tr = document.createElement("tr"), td = document.createElement("td"), b = document.createElement("div");
    b.className = "barra"; b.style.width = `${(100 * Number(d.participantes)) / max}%`; b.setAttribute("aria-hidden", "true"); td.append(b);
    tr.append(celda(d.rango), celda(d.participantes), td); cuerpo.append(tr);
  }
});
