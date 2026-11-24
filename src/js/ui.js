export function mostrarMensaje(elemento, texto, tipo = "exito") {
  if (!elemento) return;
  elemento.textContent = texto;
  elemento.className = `mensaje-estado ${tipo === "error" ? "mensaje-error" : "mensaje-exito"}`;
}