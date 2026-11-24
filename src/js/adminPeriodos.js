// Gestión de periodos: crear, abrir y cerrar (cambios auditados por trigger)
import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser, celda } from "./ui.js";
async function listar() {
  const { data, error } = await supabase.from("survey_periods").select("*").order("id", { ascending: false });
  if (error) return msg(error.message, true);
  const c = $("#filas"); c.replaceChildren();
  for (const p of data) {
    const tr = document.createElement("tr"), td = document.createElement("td"), b = document.createElement("button");
    b.type = "button"; b.textContent = p.status === "abierto" ? "Cerrar" : "Abrir";
    b.addEventListener("click", async () => {
      const { error: e } = await supabase.from("survey_periods").update({ status: p.status === "abierto" ? "cerrado" : "abierto" }).eq("id", p.id);
      msg(e ? e.message : "Periodo actualizado.", Boolean(e)); await listar(); });
    td.append(b);
    tr.append(celda(p.name), celda(`${p.start_date} a ${p.end_date}`), celda(p.methodology_version), celda(p.status), td); c.append(tr);
  }
}
const user = await requireUser();
if (user) {
  await listar();
  $("#crear").addEventListener("click", async () => {
    const { error } = await supabase.from("survey_periods").insert({ name: $("#nombre").value.trim(), start_date: $("#inicio").value,
      end_date: $("#fin").value, methodology_version: $("#metodo").value.trim() || "v1" });
    if (error) return msg(error.message.includes("row-level") ? "No tienes permisos de administrador." : error.message, true);
    msg("Periodo creado."); await listar();
  });
}
