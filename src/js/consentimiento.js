import { supabase } from "./supabaseClient.js";
import { mostrarMensaje } from "./ui.js";

const avisoEl = document.getElementById("texto-aviso");
const form = document.getElementById("form-consentimiento");
const estado = document.getElementById("estado-consentimiento");
let versionActiva = null;

async function cargarAviso() {
  const { data } = await supabase.from("consent_versions").select("*").eq("is_active", true).single();
  versionActiva = data;
  if (avisoEl && data) avisoEl.textContent = data.notice_text;
}

form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user || !versionActiva) return mostrarMensaje(estado, "Inicie sesion primero.", "error");
  const { error } = await supabase.from("consents").upsert({ user_id: user.id, consent_version_id: versionActiva.id });
  if (error) return mostrarMensaje(estado, error.message, "error");
  window.location.href = "./encuesta.html";
});

cargarAviso();