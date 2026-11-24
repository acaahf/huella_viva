import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function controlarAccesoAdmin() {
  const linksAdmin = document.querySelectorAll('a[href$="admin.html"], a[href$="factores.html"], a[href$="periodos.html"]');
  const ruta = window.location.pathname.toLowerCase();
  const esPaginaAdmin = ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html");

  const { data: { user } } = await supabase.auth.getUser();
  const esAdmin = Boolean(user && (user.email || "").toLowerCase() === ADMIN_EMAIL);

  if (esAdmin) {
    linksAdmin.forEach((el) => el.classList.add("nav-admin-visible"));
  } else {
    linksAdmin.forEach((el) => {
      el.classList.remove("nav-admin-visible");
      el.remove();
    });
    if (esPaginaAdmin) {
      window.location.replace(user ? "./encuesta.html" : "./login.html");
    }
  }
}

controlarAccesoAdmin();