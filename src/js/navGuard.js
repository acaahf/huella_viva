import { supabase } from "./supabaseClient.js";

const ADMIN_EMAIL = "acaamano287@uan.edu.co";

async function filtrarNavAdmin() {
  const linksAdmin = document.querySelectorAll('a[href$="admin.html"], a[href$="factores.html"], a[href$="periodos.html"]');
  if (linksAdmin.length === 0) return;

  const { data: { user } } = await supabase.auth.getUser();
  const esAdmin = user && (user.email || "").toLowerCase() === ADMIN_EMAIL;

  if (!esAdmin) {
    linksAdmin.forEach((el) => { el.style.display = "none"; });
    const ruta = window.location.pathname.toLowerCase();
    if (ruta.endsWith("admin.html") || ruta.endsWith("factores.html") || ruta.endsWith("periodos.html")) {
      window.location.href = user ? "./encuesta.html" : "./login.html";
    }
  }
}

filtrarNavAdmin();