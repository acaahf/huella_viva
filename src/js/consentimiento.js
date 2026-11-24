import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser } from "./ui.js";

const user = await requireUser();
if (user) {
  const { data: v } = await supabase.from("consent_versions").select("*").eq("active", true)
    .order("id", { ascending: false }).limit(1).maybeSingle();
  if (!v) msg("No hay un aviso de consentimiento activo.", true);
  else {
    $("#texto").textContent = v.texto; $("#version").textContent = v.version;
    $("#aceptar").addEventListener("click", async () => {
      if (!$("#chk").checked) return msg("Marca la casilla para continuar.", true);
      const { error } = await supabase.from("consents").insert({ profile_id: user.id, consent_version_id: v.id });
      if (error) return msg(error.message, true);
      location.href = "encuesta.html";
    });
  }
}
