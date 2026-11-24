import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser, celda } from "./ui.js";

$("#imprimir")?.addEventListener("click", () => window.print());
const user = await requireUser();
if (user) {
  const { data: c, error } = await supabase.from("calculations")
    .select("total_kgco2e, calculated_at, methodology_version, calculation_details(activity_value, converted_value, emissions_kgco2e, emission_factors(category, factor_value, unit_activity, source, source_url, reference_year, version), activity_answers(is_estimated))")
    .order("calculated_at", { ascending: false }).limit(1).maybeSingle();
  if (error) msg(error.message, true);
  else if (!c) msg("Aún no tienes un informe. Envía tu encuesta primero.");
  else {
    $("#informe").hidden = false;
    $("#total").textContent = `${Number(c.total_kgco2e).toFixed(2)} kg CO2e`;
    $("#fecha").textContent = `Calculado el ${new Date(c.calculated_at).toLocaleString("es-CO")} · método ${c.methodology_version}`;
    const cuerpo = $("#filas");
    for (const d of c.calculation_details) {
      const f = d.emission_factors, tr = document.createElement("tr");
      tr.append(celda(f.category), celda(`${d.activity_value} (por persona: ${Number(d.converted_value).toFixed(2)} ${f.unit_activity})`),
        celda(`${f.factor_value} kgCO2e/${f.unit_activity} (v${f.version}, ${f.reference_year})`),
        celda(Number(d.emissions_kgco2e).toFixed(2)), celda(d.activity_answers?.is_estimated ? "Estimado" : "Medido/declarado"));
      const td = document.createElement("td");
      if (/^https:\/\//.test(f.source_url)) { const a = document.createElement("a"); a.href = f.source_url; a.textContent = f.source; a.rel = "noopener"; td.append(a); }
      else td.textContent = f.source;
      tr.append(td); cuerpo.append(tr);
    }
  }
}
