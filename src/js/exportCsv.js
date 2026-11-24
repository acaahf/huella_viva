// CSV de agregados. Neutraliza celdas que empiezan con = + - @ (inyección de fórmulas). UTF-8 con BOM.
const seguro = (v) => { let t = String(v ?? ""); if (/^[=+\-@]/.test(t)) t = "'" + t; return `"${t.replace(/"/g, '""')}"`; };
export function descargarCsv(filas, nombre = "huellaviva_agregados.csv") {
  const cols = ["grupo", "categoria", "participantes", "promedio_kgco2e", "mediana_kgco2e"];
  const csv = [cols.join(","), ...filas.map((f) => cols.map((c) => seguro(f[c])).join(","))].join("\r\n");
  const url = URL.createObjectURL(new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8" }));
  const a = document.createElement("a"); a.href = url; a.download = nombre; a.click(); URL.revokeObjectURL(url);
}
