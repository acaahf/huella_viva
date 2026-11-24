import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser, celda } from "./ui.js";

const user = await requireUser();
async function listar() {
  const { data } = await supabase.from("data_rights_requests").select("tipo, estado, created_at").order("created_at", { ascending: false });
  const cuerpo = $("#filas"); cuerpo.replaceChildren();
  for (const r of data || []) { const tr = document.createElement("tr");
    tr.append(celda(new Date(r.created_at).toLocaleDateString("es-CO")), celda(r.tipo), celda(r.estado)); cuerpo.append(tr); }
}
if (user) {
  await listar();
  $("#enviar").addEventListener("click", async () => {
    const { error } = await supabase.from("data_rights_requests").insert({ profile_id: user.id, tipo: $("#tipo").value, detalle: $("#detalle").value });
    if (error) return msg(error.message, true);
    msg("Solicitud registrada. La atención la realiza el canal institucional."); $("#detalle").value = ""; await listar();
  });
}
