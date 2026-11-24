import { supabase } from "./supabaseClient.js";

const form = document.getElementById("form-derechos");
form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;
  await supabase.from("data_rights_requests").insert({
    user_id: user.id,
    request_type: document.getElementById("tipo_solicitud").value,
    description: document.getElementById("desc_solicitud").value.trim()
  });
  form.reset();
});