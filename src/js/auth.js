import { supabase } from "./supabaseClient.js";
import { mostrarMensaje } from "./ui.js";

const form = document.getElementById("form-login");
const btnLogin = document.getElementById("btn-login");
const btnRegister = document.getElementById("btn-register");
const estado = document.getElementById("estado-auth");

async function completarAcceso(user, tipoUsuario) {
  await supabase.from("profiles").upsert({ id: user.id, tipo_usuario: tipoUsuario }, { onConflict: "id" });

  const { data: consent } = await supabase
    .from("consents")
    .select("id")
    .eq("user_id", user.id)
    .is("revoked_at", null)
    .limit(1)
    .maybeSingle();

  window.location.href = consent ? "./encuesta.html" : "./consentimiento.html";
}

form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;
  const tipoUsuario = document.getElementById("tipo_usuario").value;

  btnLogin.disabled = true;
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  btnLogin.disabled = false;

  if (error) {
    const msg = error.message.toLowerCase().includes("invalid login credentials")
      ? "Correo o contraseña incorrectos. Si aún no tienes cuenta, pulsa 'Registrarse'."
      : `Error al iniciar sesión: ${error.message}`;
    mostrarMensaje(estado, msg, "error");
    return;
  }

  await completarAcceso(data.user, tipoUsuario);
});

btnRegister?.addEventListener("click", async () => {
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;
  const tipoUsuario = document.getElementById("tipo_usuario").value;

  if (!email || password.length < 6) {
    mostrarMensaje(estado, "Ingresa un correo válido y una contraseña de al menos 6 caracteres para registrarte.", "error");
    return;
  }

  btnRegister.disabled = true;
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { tipo_usuario: tipoUsuario } }
  });
  btnRegister.disabled = false;

  if (error) {
    const msg = error.message.toLowerCase().includes("already registered")
      ? "Este correo ya está registrado. Pulsa 'Iniciar sesión'."
      : `Error al registrarse: ${error.message}`;
    mostrarMensaje(estado, msg, "error");
    return;
  }

  if (!data.session) {
    mostrarMensaje(estado, "Cuenta creada. Revisa tu correo para confirmarla antes de iniciar sesión.", "exito");
    return;
  }

  await completarAcceso(data.user, tipoUsuario);
});