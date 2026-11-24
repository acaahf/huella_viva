import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

function renderBotonAdmin(esAdmin) {
  const ruta = window.location.pathname.toLowerCase();
  const esLogin = ruta.endsWith("login.html");
  const nav = document.querySelector(".cabecera-principal nav");
  if (!nav || esLogin) return;

  const existente = nav.querySelector('a[href$="admin.html"]');
  if (esAdmin && !existente) {
    const linkAdmin = document.createElement("a");
    linkAdmin.className = "btn-nav";
    linkAdmin.href = "./admin.html";
    linkAdmin.textContent = "Admin";
    linkAdmin.style.display = "inline-flex";
    nav.appendChild(linkAdmin);
  } else if (!esAdmin && existente) {
    existente.remove();
  }
}

async function controlarAccesoAdmin() {
  const ruta = window.location.pathname.toLowerCase();
  const esPaginaAdmin = ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html");

  const { data: { session } } = await supabase.auth.getSession();
  const user = session?.user;
  const esAdmin = Boolean(user && (user.email || "").toLowerCase() === ADMIN_EMAIL);

  if (!esAdmin && esPaginaAdmin) {
    window.location.replace(user ? "./encuesta.html" : "./login.html");
    return;
  }

  renderBotonAdmin(esAdmin);
}

supabase.auth.onAuthStateChange((_event, session) => {
  const esAdmin = Boolean(session?.user && (session.user.email || "").toLowerCase() === ADMIN_EMAIL);
  renderBotonAdmin(esAdmin);
});

controlarAccesoAdmin();