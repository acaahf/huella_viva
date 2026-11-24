export function validarNumeroNoNegativo(valor, nombreCampo) {
  const num = Number(valor);
  if (Number.isNaN(num) || num < 0) {
    throw new Error(`El campo ${nombreCampo} debe ser un numero mayor o igual a 0.`);
  }
  return num;
}