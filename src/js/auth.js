import { supabase } from "./supabaseClient.js";
import { mostrarMensaje } from "./ui.js";

const form = document.getElementById("form-login");
const estado = document.getElementById("estado-auth");

form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;
  const tipoUsuario = document.getElementById("tipo_usuario").value;

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    mostrarMensaje(estado, `Error de acceso: ${error.message}`, "error");
    return;
  }
  await supabase.from("profiles").upsert({ id: data.user.id, tipo_usuario: tipoUsuario });
  window.location.href = "./consentimiento.html";
});