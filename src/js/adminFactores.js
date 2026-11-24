// Gestión de factores: lista y publicación de nuevas versiones (auditadas en admin_audit_log)
import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser, celda } from "./ui.js";
async function listar() {
  const { data, error } = await supabase.from("emission_factors")
    .select("question_code, factor_value, unit_activity, source, reference_year, version, valid_from, valid_to, justificacion")
    .order("question_code").order("version", { ascending: false });
  if (error) return msg(error.message, true);
  const c = $("#filas"); c.replaceChildren();
  for (const f of data) { const tr = document.createElement("tr");
    tr.append(celda(f.question_code), celda(`${f.factor_value} kgCO2e/${f.unit_activity}`), celda(`v${f.version}`), celda(f.reference_year),
      celda(`${f.valid_from} a ${f.valid_to ?? "vigente"}`), celda(f.source), celda(f.justificacion ?? "")); c.append(tr); }
}
const user = await requireUser();
if (user) {
  await listar();
  $("#publicar").addEventListener("click", async () => {
    const valor = Number($("#valor").value), anio = Number($("#anio").value);
    if (Number.isNaN(valor) || valor < 0 || !anio) return msg("Valor y año válidos son obligatorios.", true);
    const { error } = await supabase.rpc("publicar_factor", { p_category: $("#categoria").value.trim(), p_question: $("#pregunta").value.trim(),
      p_valor: valor, p_unidad: $("#unidad").value.trim(), p_geo: $("#geo").value.trim(), p_fuente: $("#fuente").value.trim(),
      p_url: $("#url").value.trim(), p_anio: anio, p_desde: $("#desde").value, p_just: $("#just").value.trim() });
    if (error) return msg(error.message === "No autorizado" ? "No tienes permisos de administrador." : error.message, true);
    msg("Nueva versión publicada y auditada."); await listar();
  });
}
