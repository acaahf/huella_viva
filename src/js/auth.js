import { supabase } from "./supabaseClient.js";
import { mostrarMensaje } from "./ui.js";

const form = document.getElementById("form-login");
const estado = document.getElementById("estado-auth");

form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;
  const tipoUsuario = document.getElementById("tipo_usuario").value;

  let { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error && error.message.toLowerCase().includes("invalid login credentials")) {
    const signUpRes = await supabase.auth.signUp({
      email,
      password,
      options: { data: { tipo_usuario: tipoUsuario } }
    });

    if (signUpRes.error) {
      const msg = signUpRes.error.message.toLowerCase().includes("already registered")
        ? "ContraseÃ±a incorrecta para este correo."
        : `Error al registrar: ${signUpRes.error.message}`;
      mostrarMensaje(estado, msg, "error");
      return;
    }

    if (!signUpRes.data.session) {
      mostrarMensaje(estado, "Cuenta creada. Revisa tu correo para confirmarla (o desactiva 'Confirm email' en Supabase).", "info");
      return;
    }

    data = signUpRes.data;
    error = null;
  }

  if (error) {
    mostrarMensaje(estado, `Error de acceso: ${error.message}`, "error");
    return;
  }

  await supabase.from("profiles").upsert({ id: data.user.id, tipo_usuario: tipoUsuario });
  window.location.href = "./consentimiento.html";
});