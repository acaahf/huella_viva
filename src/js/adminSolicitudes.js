// Atención de solicitudes de derechos (sin identidad; el contacto con el titular es institucional)
import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser, celda } from "./ui.js";
async function listar() {
  const { data, error } = await supabase.rpc("admin_solicitudes");
  if (error) return msg(error.message === "No autorizado" ? "No tienes permisos de administrador." : error.message, true);
  const c = $("#filas"); c.replaceChildren();
  for (const r of data) {
    const tr = document.createElement("tr"), td = document.createElement("td"), s = document.createElement("select"), b = document.createElement("button");
    for (const e of ["recibida", "en_tramite", "atendida"]) { const o = document.createElement("option"); o.value = e; o.textContent = e; o.selected = e === r.estado; s.append(o); }
    s.setAttribute("aria-label", "Estado de la solicitud"); b.type = "button"; b.textContent = "Guardar";
    b.addEventListener("click", async () => {
      const { error: e } = await supabase.rpc("admin_estado_solicitud", { p_id: r.id, p_estado: s.value });
      msg(e ? e.message : "Estado actualizado.", Boolean(e)); });
    td.append(s, b);
    tr.append(celda(new Date(r.created_at).toLocaleDateString("es-CO")), celda(r.tipo), celda(r.detalle ?? ""), td); c.append(tr);
  }
}
const user = await requireUser();
if (user) await listar();
