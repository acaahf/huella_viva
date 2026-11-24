import { supabase } from "./supabaseClient.js";
import { validarNumeroNoNegativo } from "./validaciones.js";
import { calcularHuella } from "./calculo.js";
import { APP_CONFIG } from "./config.js";
import { mostrarMensaje } from "./ui.js";

const form = document.getElementById("form-encuesta");
const btnBorrador = document.getElementById("btn-borrador");
const estado = document.getElementById("estado-encuesta");
const infoPeriodo = document.getElementById("info-periodo");

let contexto = { user: null, period: null, consent: null };

async function inicializar() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }
  const { data: consent } = await supabase
    .from("consents")
    .select("id")
    .eq("user_id", user.id)
    .is("revoked_at", null)
    .limit(1)
    .maybeSingle();

  if (!consent) {
    window.location.href = "./consentimiento.html";
    return;
  }

  const { data: period } = await supabase
    .from("survey_periods")
    .select("*")
    .eq("is_open", true)
    .limit(1)
    .maybeSingle();

  if (!period) {
    if (infoPeriodo) infoPeriodo.textContent = "No hay periodos abiertos actualmente.";
    return;
  }

  contexto = { user, period, consent };
  if (infoPeriodo) infoPeriodo.textContent = `Periodo activo: ${period.name} (${period.code})`;

  // Cargar borrador o encuesta previa si existe
  const { data: survey } = await supabase
    .from("surveys")
    .select("id, status")
    .eq("user_id", user.id)
    .eq("period_id", period.id)
    .maybeSingle();

  if (survey) {
    const { data: answers } = await supabase.from("activity_answers").select("*").eq("survey_id", survey.id);
    for (const a of answers || []) {
      if (a.question_code === "PERSONAS_HOGAR") document.getElementById("personas_hogar").value = a.numeric_value;
      if (a.question_code === "ELEC_SIN_CO") {
        document.getElementById("elec_kwh").value = a.numeric_value;
        document.getElementById("elec_estimado").checked = a.is_estimated;
      }
      if (a.question_code === "GAS_NAT_CO" && a.numeric_value !== null) document.getElementById("gas_m3").value = a.numeric_value;
      if (a.category === "desplazamiento_campus") {
        document.getElementById("modo_transporte").value = a.question_code;
        document.getElementById("km_campus").value = a.numeric_value;
      }
    }
  }
}

async function guardarEncuesta(statusFinal) {
  const personas = validarNumeroNoNegativo(document.getElementById("personas_hogar").value, "Personas en el hogar");
  const kwh = validarNumeroNoNegativo(document.getElementById("elec_kwh").value, "Electricidad kWh");
  const isEstimated = document.getElementById("elec_estimado").checked;
  const gasRaw = document.getElementById("gas_m3").value;
  const gasM3 = gasRaw !== "" ? validarNumeroNoNegativo(gasRaw, "Gas natural m3") : null;
  const modo = document.getElementById("modo_transporte").value;
  const km = validarNumeroNoNegativo(document.getElementById("km_campus").value, "Kilometros al campus");

  // 1. Upsert encuesta
  const { data: survey, error: errSurvey } = await supabase
    .from("surveys")
    .upsert({
      user_id: contexto.user.id,
      period_id: contexto.period.id,
      consent_id: contexto.consent.id,
      status: statusFinal,
      submitted_at: statusFinal === "enviada" ? new Date().toISOString() : null,
      updated_at: new Date().toISOString()
    }, { onConflict: "user_id,period_id" })
    .select()
    .single();

  if (errSurvey) throw errSurvey;

  // 2. Limpiar respuestas anteriores y guardar actuales
  await supabase.from("activity_answers").delete().eq("survey_id", survey.id);

  const filasRespuestas = [
    { survey_id: survey.id, category: "electricidad", question_code: "PERSONAS_HOGAR", numeric_value: personas, unit: "personas", is_estimated: false },
    { survey_id: survey.id, category: "electricidad", question_code: "ELEC_SIN_CO", numeric_value: kwh, unit: "kWh", is_estimated: isEstimated },
    { survey_id: survey.id, category: "desplazamiento_campus", question_code: modo, numeric_value: km, unit: "km", is_estimated: false }
  ];
  if (gasM3 !== null) {
    filasRespuestas.push({ survey_id: survey.id, category: "gas_combustibles", question_code: "GAS_NAT_CO", numeric_value: gasM3, unit: "m3", is_estimated: false });
  }

  const { data: savedAnswers, error: errAns } = await supabase.from("activity_answers").insert(filasRespuestas).select();
  if (errAns) throw errAns;

  if (statusFinal === "borrador") {
    mostrarMensaje(estado, "Borrador guardado correctamente. Puedes retomarlo cuando desees.", "exito");
    return;
  }

  // 3. Calcular y persistir resultado auditable
  const { data: factors } = await supabase.from("emission_factors").select("*").eq("is_active", true);
  const factorsMap = new Map((factors || []).map((f) => [f.factor_code, f]));

  const inputsCalculo = savedAnswers
    .filter((a) => a.question_code !== "PERSONAS_HOGAR")
    .map((a) => ({ ...a, factor_code: a.question_code }));

  const resultado = calcularHuella(inputsCalculo, factorsMap, { householdSize: personas });

  const { data: calc, error: errCalc } = await supabase
    .from("calculations")
    .insert({
      survey_id: survey.id,
      method_version: APP_CONFIG.METHOD_VERSION,
      total_kgco2e: resultado.total_kgco2e,
      has_estimated_inputs: resultado.has_estimated_inputs,
      excluded_categories: resultado.excluded_categories
    })
    .select()
    .single();

  if (errCalc) throw errCalc;

  if (resultado.details.length > 0) {
    const detalles = resultado.details.map((d) => ({
      calculation_id: calc.id,
      answer_id: d.answer_id,
      factor_id: d.factor_id,
      category: d.category,
      activity_value: d.activity_value,
      converted_value: d.converted_value,
      emissions_kgco2e: d.emissions_kgco2e
    }));
    await supabase.from("calculation_details").insert(detalles);
  }

  window.location.href = "./informe.html";
}

btnBorrador?.addEventListener("click", async () => {
  try { await guardarEncuesta("borrador"); } catch (err) { mostrarMensaje(estado, err.message, "error"); }
});

form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  try { await guardarEncuesta("enviada"); } catch (err) { mostrarMensaje(estado, err.message, "error"); }
});

inicializar();