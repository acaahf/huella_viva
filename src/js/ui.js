import { supabase, configurado } from "./supabaseClient.js";
export const $ = (s) => document.querySelector(s);
export function msg(t, error = false) {
  const e = $("#msg"); if (!e) return;
  e.textContent = t; e.className = error ? "error" : "ok";
}
export async function requireUser() {
  if (!configurado) { msg("Configura SUPABASE_URL y SUPABASE_ANON_KEY en src/js/config.js", true); return null; }
  const { data } = await supabase.auth.getSession();
  if (!data.session) { location.href = "index.html"; return null; }
  return data.session.user;
}
export function celda(texto, etiqueta = "td") {
  const e = document.createElement(etiqueta); e.textContent = texto ?? ""; return e;
}
$("#salir")?.addEventListener("click", async () => { await supabase.auth.signOut(); location.href = "index.html"; });
