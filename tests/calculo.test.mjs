import test from "node:test";
import assert from "node:assert/strict";
import { emisionesKg } from "../src/js/calculo.js";
import { validar } from "../src/js/validaciones.js";

test("100 kWh entre 2 personas con 0.22 kgCO2e/kWh = 11 kg", () => assert.equal(emisionesKg(100, 0.22, 2), 11));
test("personas menor a 1 lanza error", () => assert.throws(() => emisionesKg(100, 0.22, 0)));
test("valores negativos lanzan error", () => assert.throws(() => emisionesKg(-1, 0.22, 1)));
test("validar rechaza fuera de rango y no numérico", () => {
  assert.ok(validar("30000", 0, 20000).error); assert.ok(validar("", 0, 20000).error);
  assert.equal(validar("150", 0, 20000).valor, 150); assert.ok(validar("1.5", 1, 30, true).error);
});
