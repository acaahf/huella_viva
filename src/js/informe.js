import { supabase } from "./supabaseClient.js";

const contenedor = document.getElementById("contenedor-informe");
const btnImprimir = document.getElementById("btn-imprimir");
btnImprimir?.addEventListener("click", () => window.print());

async function cargarInforme() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }

  const { data: calc } = await supabase
    .from("calculations")
    .select("*, surveys!inner(user_id, period_id), calculation_details(*, emission_factors(source_name, version, value, activity_unit))")
    .eq("surveys.user_id", user.id)
    .order("calculated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!calc) {
    contenedor.textContent = "Aun no tienes una encuesta enviada. Completa la encuesta para generar tu informe.";
    return;
  }

  const totalTon = (Number(calc.total_kgco2e) / 1000).toFixed(4);
  const filasHtml = (calc.calculation_details || []).map((d) => `
    <tr>
      <td>${d.category}</td>
      <td>${d.converted_value} ${d.emission_factors?.activity_unit || ""}</td>
      <td>${d.emission_factors?.value} (v${d.emission_factors?.version})</td>
      <td><strong>${d.emissions_kgco2e} kg CO2e</strong></td>
      <td>${d.emission_factors?.source_name || ""}</td>
    </tr>
  `).join("");

  contenedor.innerHTML = `
    <p><strong>Huella anual estimada:</strong> ${calc.total_kgco2e} kg CO2e (${totalTon} t CO2e/ano)</p>
    <p><strong>Fecha de calculo:</strong> ${new Date(calc.calculated_at).toLocaleString("es-CO")} | <strong>Metodo:</strong> ${calc.method_version}</p>
    <p><strong>Contiene datos estimados:</strong> ${calc.has_estimated_inputs ? "Si (mayor incertidumbre)" : "No (datos directos ingresados)"}</p>
    <table class="tabla-datos">
      <thead><tr><th>Categoria</th><th>Actividad ajustada</th><th>Factor</th><th>Emisiones</th><th>Fuente</th></tr></thead>
      <tbody>${filasHtml}</tbody>
    </table>
    <h3>Limites y recomendaciones</h3>
    <p>Categorias sin factor nacional verificado (alimentacion, residuos) estan excluidas del total. Prioriza movilidad activa o transporte publico y eficiencia energetica en el hogar.</p>
  `;
}

cargarInforme();