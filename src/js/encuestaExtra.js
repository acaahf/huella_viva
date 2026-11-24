// Reabrir una encuesta ya enviada mientras el periodo siga abierto (RF-03)
import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser } from "./ui.js";
const user = await requireUser();
if (user) {
  const { data: s } = await supabase.from("surveys").select("id, status").eq("profile_id", user.id)
    .order("updated_at", { ascending: false }).limit(1).maybeSingle();
  if (s?.status === "enviada") {
    const b = $("#reabrir"); b.hidden = false;
    b.addEventListener("click", async () => {
      const { error } = await supabase.rpc("reabrir_encuesta", { p_survey: s.id });
      if (error) return msg(error.message, true);
      location.reload();
    });
  }
}
