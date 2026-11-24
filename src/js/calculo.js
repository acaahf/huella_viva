export function calcularHuella(answers, factorsByCode, context = { householdSize: 1 }) {
  const personasHogar = Math.max(1, Number(context.householdSize) || 1);
  const details = [];
  const excludedCategories = new Set();
  let totalKgCo2e = 0;
  let hasEstimatedInputs = false;

  for (const ans of answers) {
    if (ans.numeric_value === null || ans.numeric_value === undefined || Number.isNaN(Number(ans.numeric_value))) continue;
    const factor = factorsByCode.get(ans.factor_code);
    if (!factor) {
      excludedCategories.add(`${ans.category} (sin factor verificado)`);
      continue;
    }
    if (ans.is_estimated) hasEstimatedInputs = true;

    let convertedValue = Number(ans.numeric_value);
    if (ans.category === "electricidad" || ans.category === "gas_combustibles") {
      convertedValue = convertedValue / personasHogar;
    }
    if (ans.unit === "MWh" && factor.activity_unit === "kWh") {
      convertedValue = convertedValue * 1000;
    }

    const emissions = Number((convertedValue * Number(factor.value)).toFixed(4));
    totalKgCo2e += emissions;
    details.push({
      answer_id: ans.id || null,
      factor_id: factor.id,
      factor_version: factor.version,
      category: ans.category,
      activity_value: Number(ans.numeric_value),
      converted_value: Number(convertedValue.toFixed(4)),
      emissions_kgco2e: emissions,
      is_estimated: Boolean(ans.is_estimated)
    });
  }

  return {
    total_kgco2e: Number(totalKgCo2e.toFixed(4)),
    total_tco2e: Number((totalKgCo2e / 1000).toFixed(4)),
    has_estimated_inputs: hasEstimatedInputs,
    excluded_categories: Array.from(excludedCategories),
    details
  };
}