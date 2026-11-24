import { supabase, configurado } from "./supabaseClient.js";
import { $, msg } from "./ui.js";

async function asegurarPerfil(user) {
  const { data } = await supabase.from("profiles").select("id").eq("id", user.id).maybeSingle();
  if (!data) {
    const tipo = user.user_metadata?.tipo || "estudiante";
    const { error } = await supabase.from("profiles").insert({ id: user.id, tipo_usuario: tipo });
    if (error) throw error;
  }
}
if (!configurado) msg("Configura src/js/config.js con tu URL y clave anon de Supabase.", true);

$("#registro")?.addEventListener("click", async () => {
  const { data, error } = await supabase.auth.signUp({
    email: $("#email").value, password: $("#password").value, options: { data: { tipo: $("#tipo").value } } });
  if (error) return msg(error.message, true);
  if (data.session) { await asegurarPerfil(data.user); location.href = "consentimiento.html"; }
  else msg("Revisa tu correo para confirmar la cuenta y luego ingresa.");
});
$("#ingreso")?.addEventListener("click", async () => {
  const { data, error } = await supabase.auth.signInWithPassword({ email: $("#email").value, password: $("#password").value });
  if (error) return msg(error.message, true);
  try { await asegurarPerfil(data.user); location.href = "consentimiento.html"; } catch (e) { msg(e.message, true); }
});
const u = await supabase.auth.getSession();
if (u.data.session) msg("Sesión activa: " + u.data.session.user.email);
