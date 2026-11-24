// Valida un número de la encuesta: rango y (opcionalmente) entero.
export function validar(texto, min, max, entero = false) {
  const n = Number(texto);
  if (texto === "" || Number.isNaN(n)) return { error: "Se requiere un valor numérico." };
  if (n < min || n > max) return { error: `El valor debe estar entre ${min} y ${max}.` };
  if (entero && !Number.isInteger(n)) return { error: "Debe ser un número entero." };
  return { valor: n };
}
