// Retiro del consentimiento (registra revoked_at; la supresión de datos se solicita por el canal institucional)
import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser } from "./ui.js";
const user = await requireUser();
if (user) {
  $("#retirar").addEventListener("click", async () => {
    if (!confirm("¿Retirar tu consentimiento? No podrás enviar nuevas respuestas hasta aceptar de nuevo.")) return;
    const { error } = await supabase.from("consents").update({ revoked_at: new Date().toISOString() })
      .eq("profile_id", user.id).is("revoked_at", null);
    msg(error ? error.message : "Consentimiento retirado. Para suprimir tus datos registra una solicitud de supresión.", Boolean(error));
  });
}
