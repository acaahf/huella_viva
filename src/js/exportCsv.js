const FORMULA_PREFIXES = ["=", "+", "-", "@", "\t", "\r"];

export function sanitizarCeldaCsv(valor) {
  if (valor === null || valor === undefined) return "";
  let texto = String(valor);
  if (FORMULA_PREFIXES.some((p) => texto.startsWith(p))) texto = `'${texto}`;
  if (texto.includes(",") || texto.includes('"') || texto.includes("\n")) {
    texto = `"${texto.replace(/"/g, '""')}"`;
  }
  return texto;
}

export function generarCsvAgregado(filas) {
  const encabezados = ["Tipo de Usuario", "Campus", "Participantes", "Promedio (kg CO2e)", "Mediana (kg CO2e)", "Oculto (<10)"];
  const lineas = [encabezados.map(sanitizarCeldaCsv).join(",")];
  for (const f of filas) {
    const oculto = Boolean(f.oculto_por_privacidad) || Number(f.participantes) < 10;
    lineas.push([
      f.tipo_usuario, f.campus, f.participantes,
      oculto ? "OCULTO (<10)" : f.promedio_kgco2e,
      oculto ? "OCULTO (<10)" : f.mediana_kgco2e,
      oculto ? "Si" : "No"
    ].map(sanitizarCeldaCsv).join(","));
  }
  return "\uFEFF" + lineas.join("\r\n");
}