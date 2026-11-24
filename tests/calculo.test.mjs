import test from "node:test";
import assert from "node:assert/strict";
import { calcularHuella } from "../src/js/calculo.js";
import { sanitizarCeldaCsv } from "../src/js/exportCsv.js";

const FIXTURE_FACTORS = new Map([
  ["ELEC_SIN_CO", { id: "f-1", value: 0.22, activity_unit: "kWh", version: "2024.1" }]
]);

test("Calcula electricidad dividiendo por personas del hogar", () => {
  const res = calcularHuella(
    [{ id: "a-1", category: "electricidad", factor_code: "ELEC_SIN_CO", numeric_value: 200, unit: "kWh", is_estimated: false }],
    FIXTURE_FACTORS,
    { householdSize: 2 }
  );
  assert.equal(res.total_kgco2e, 22);
});

test("Neutraliza inyeccion de formulas en CSV", () => {
  assert.equal(sanitizarCeldaCsv("=SUM(A1:A2)"), "'=SUM(A1:A2)");
});