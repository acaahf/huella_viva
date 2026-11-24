// Misma fórmula que calcular_huella() en SQL: actividad / personas del hogar x factor (kgCO2e por unidad).
export function emisionesKg(actividad, factorKgPorUnidad, personas = 1) {
  if (!(personas >= 1)) throw new Error("personas debe ser >= 1");
  if (actividad < 0 || factorKgPorUnidad < 0) throw new Error("valores negativos no permitidos");
  return (actividad / personas) * factorKgPorUnidad;
}
// 1 tCO2e/MWh equivale a 1 kgCO2e/kWh
export const tPorMWhAKgPorKWh = (v) => v;
