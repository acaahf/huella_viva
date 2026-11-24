import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function controlarAccesoAdmin() {
  const ruta = window.location.pathname.toLowerCase();
  const esPaginaAdmin = ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html");
  const esLogin = ruta.endsWith("login.html");

  const { data: { user } } = await supabase.auth.getUser();
  const esAdmin = Boolean(user && (user.email || "").toLowerCase() === ADMIN_EMAIL);

  if (!esAdmin) {
    if (esPaginaAdmin) {
      window.location.replace(user ? "./encuesta.html" : "./login.html");
    }
    return;
  }

  if (!esLogin) {
    const nav = document.querySelector(".cabecera-principal nav");
    if (nav && !nav.querySelector('a[href$="admin.html"]')) {
      const linkAdmin = document.createElement("a");
      linkAdmin.className = "btn-nav";
      linkAdmin.href = "./admin.html";
      linkAdmin.textContent = "Admin";
      nav.appendChild(linkAdmin);
    }
  }
}

controlarAccesoAdmin();