# 04_integracion_supabase.ps1 - Conecta persistencia real en Supabase, informe y dashboard
$ErrorActionPreference = "Stop"

function Write-Utf8File($Path, $Content) {
    $fullPath = Join-Path (Get-Location) $Path
    $dir = Split-Path -Parent $fullPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Actualizado: $Path" -ForegroundColor Green
}

# 1. Migracion 003: Trigger de auditoria automatica y factores adicionales con fuente
Write-Utf8File "supabase/migrations/003_factores_y_auditoria.sql" @'
-- 003_factores_y_auditoria.sql
-- Auditoria automatica en cambios de factores y periodos + carga de factores documentados

CREATE OR REPLACE FUNCTION public.log_admin_changes()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    INSERT INTO public.admin_audit_log (actor_user_id, table_name, record_id, action, before_json, after_json, justification)
    VALUES (
      auth.uid(),
      TG_TABLE_NAME,
      COALESCE(NEW.id, OLD.id),
      TG_OP,
      CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
      CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
      'Operacion administrativa registrada desde interfaz web'
    );
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_factors ON public.emission_factors;
CREATE TRIGGER trg_audit_factors
AFTER INSERT OR UPDATE ON public.emission_factors
FOR EACH ROW EXECUTE FUNCTION public.log_admin_changes();

DROP TRIGGER IF EXISTS trg_audit_periods ON public.survey_periods;
CREATE TRIGGER trg_audit_periods
AFTER INSERT OR UPDATE ON public.survey_periods
FOR EACH ROW EXECUTE FUNCTION public.log_admin_changes();

-- Factores adicionales documentados (UPME / FECOC+ Colombia)
INSERT INTO public.emission_factors (
  category, factor_code, value, activity_unit, emission_unit, gas_equivalence,
  geography, source_name, source_url, reference_year, valid_from, method, version, is_active
) VALUES
(
  'gas_combustibles', 'GAS_NAT_CO', 1.960000, 'm3', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - Calculadora FECOC+ Gas Natural Residencial (referencia academica)',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 1', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_BUS_CO', 0.089000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - Transporte Sostenible / Referencia pasajeros-km transporte publico',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_AUTO_CO', 0.192000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - FECOC+ Vehiculo particular gasolina promedio',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_MOTO_CO', 0.072000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'UPME - FECOC+ Motocicleta gasolina promedio',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
),
(
  'desplazamiento_campus', 'TRANSP_BICI_PIE', 0.000000, 'km', 'kg CO2e', 'CO2e',
  'Colombia', 'Modo activo sin emisiones directas de combustion',
  'https://www.upme.gov.co/siee/transporte-sostenible/',
  2024, '2024-01-01', 'Adaptacion academica GHG Protocol Alcance 3', '2024.1', true
)
ON CONFLICT (factor_code, version) DO NOTHING;
'@

# 2. Actualizar encuesta.html para incluir modo de transporte y gas opcional
Write-Utf8File "src/encuesta.html" @'
<!DOCTYPE html>
<html lang="es-CO">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Encuesta — HuellaViva UAN</title><link rel="stylesheet" href="./css/base.css"><link rel="stylesheet" href="./css/componentes.css"><link rel="stylesheet" href="./css/formularios.css"></head>
<body>
  <aside class="banner-institucional" role="note"><strong>Prototipo Academico — HuellaViva UAN:</strong> Estimador educativo y de diagnostico institucional. NO es un inventario verificado, certificacion ambiental ni resultado oficial de RENARE.</aside>
  <header class="cabecera-principal"><a class="marca" href="./index.html"><img src="../assets/logo-huellaviva.svg" alt="Icono HuellaViva UAN"><span>HuellaViva UAN</span></a><nav aria-label="Principal"><a class="btn-nav" href="./encuesta.html">Encuesta</a><a class="btn-nav" href="./informe.html">Mi Informe</a><a class="btn-nav" href="./derechos.html">Derechos</a><a class="btn-nav" href="./admin.html">Admin</a></nav></header>
  <main class="contenedor">
    <section class="tarjeta">
      <h1>Encuesta de Actividad (Reporte Anualizado)</h1>
      <p id="info-periodo">Verificando periodo activo y consentimiento...</p>
      <form id="form-encuesta">
        <fieldset>
          <legend>1. Electricidad del hogar (Obligatoria)</legend>
          <div class="campo"><label for="personas_hogar">Personas que comparten el hogar <span class="etiqueta-req">*</span></label><input id="personas_hogar" type="number" min="1" max="20" value="1" required></div>
          <div class="campo"><label for="elec_kwh">Consumo anual estimado (kWh/ano) <span class="etiqueta-req">*</span></label><input id="elec_kwh" type="number" min="0" step="0.1" required></div>
          <label><input id="elec_estimado" type="checkbox"> Dato estimado (no conozco el kWh exacto de la factura)</label>
        </fieldset>
        <fieldset>
          <legend>2. Gas natural residencial (Opcional)</legend>
          <div class="campo"><label for="gas_m3">Consumo anual (m3/ano) <span class="etiqueta-opt">(Opcional)</span></label><input id="gas_m3" type="number" min="0" step="0.1"></div>
        </fieldset>
        <fieldset>
          <legend>3. Desplazamiento al campus (Obligatoria)</legend>
          <div class="campo">
            <label for="modo_transporte">Modo principal de transporte <span class="etiqueta-req">*</span></label>
            <select id="modo_transporte">
              <option value="TRANSP_BUS_CO">Transporte publico / Bus / SITP</option>
              <option value="TRANSP_AUTO_CO">Vehiculo particular</option>
              <option value="TRANSP_MOTO_CO">Motocicleta</option>
              <option value="TRANSP_BICI_PIE">Bicicleta o caminata</option>
            </select>
          </div>
          <div class="campo"><label for="km_campus">Kilometros anuales ida y vuelta al campus <span class="etiqueta-req">*</span></label><input id="km_campus" type="number" min="0" step="1" required></div>
        </fieldset>
        <button type="button" id="btn-borrador" class="btn-secundario">Guardar borrador</button>
        <button type="submit" class="btn-primario">Enviar y calcular huella</button>
      </form>
      <div id="estado-encuesta" aria-live="polite"></div>
    </section>
  </main>
  <script type="module" src="./js/encuesta.js"></script>
</body>
</html>
'@

# 3. Actualizar encuesta.js con persistencia real en Supabase (borrador + enviada + calculos)
Write-Utf8File "src/js/encuesta.js" @'
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
'@

# 4. Actualizar informe.js para leer el calculo real desde Supabase
Write-Utf8File "src/js/informe.js" @'
import { supabase } from "./supabaseClient.js";

const contenedor = document.getElementById("contenedor-informe");
const btnImprimir = document.getElementById("btn-imprimir");
btnImprimir?.addEventListener("click", () => window.print());

async function cargarInforme() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }

  const { data: calc } = await supabase
    .from("calculations")
    .select("*, surveys!inner(user_id, period_id), calculation_details(*, emission_factors(source_name, version, value, activity_unit))")
    .eq("surveys.user_id", user.id)
    .order("calculated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!calc) {
    contenedor.textContent = "Aun no tienes una encuesta enviada. Completa la encuesta para generar tu informe.";
    return;
  }

  const totalTon = (Number(calc.total_kgco2e) / 1000).toFixed(4);
  const filasHtml = (calc.calculation_details || []).map((d) => `
    <tr>
      <td>${d.category}</td>
      <td>${d.converted_value} ${d.emission_factors?.activity_unit || ""}</td>
      <td>${d.emission_factors?.value} (v${d.emission_factors?.version})</td>
      <td><strong>${d.emissions_kgco2e} kg CO2e</strong></td>
      <td>${d.emission_factors?.source_name || ""}</td>
    </tr>
  `).join("");

  contenedor.innerHTML = `
    <p><strong>Huella anual estimada:</strong> ${calc.total_kgco2e} kg CO2e (${totalTon} t CO2e/ano)</p>
    <p><strong>Fecha de calculo:</strong> ${new Date(calc.calculated_at).toLocaleString("es-CO")} | <strong>Metodo:</strong> ${calc.method_version}</p>
    <p><strong>Contiene datos estimados:</strong> ${calc.has_estimated_inputs ? "Si (mayor incertidumbre)" : "No (datos directos ingresados)"}</p>
    <table class="tabla-datos">
      <thead><tr><th>Categoria</th><th>Actividad ajustada</th><th>Factor</th><th>Emisiones</th><th>Fuente</th></tr></thead>
      <tbody>${filasHtml}</tbody>
    </table>
    <h3>Limites y recomendaciones</h3>
    <p>Categorias sin factor nacional verificado (alimentacion, residuos) estan excluidas del total. Prioriza movilidad activa o transporte publico y eficiencia energetica en el hogar.</p>
  `;
}

cargarInforme();
'@

# 5. Actualizar dashboard.js para consultar agregados reales (k >= 10)
Write-Utf8File "src/js/dashboard.js" @'
import { supabase } from "./supabaseClient.js";
import { generarCsvAgregado } from "./exportCsv.js";
import { APP_CONFIG } from "./config.js";

let ultimasFilas = [];
const tablaContenedor = document.getElementById("tabla-dashboard");
const btnCsv = document.getElementById("btn-exportar-csv");

async function cargarDashboard() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }

  const { data: period } = await supabase.from("survey_periods").select("*").eq("is_open", true).limit(1).maybeSingle();
  if (!period) {
    tablaContenedor.textContent = "No hay periodos activos para consultar.";
    return;
  }

  const { data, error } = await supabase.rpc("get_aggregated_metrics", {
    p_period_id: period.id,
    p_campus: null,
    p_tipo_usuario: null,
    p_min_cell: APP_CONFIG.MIN_CELL_PRIVACY
  });

  if (error) {
    tablaContenedor.textContent = `Acceso restringido o error: ${error.message}`;
    return;
  }

  ultimasFilas = data || [];
  if (ultimasFilas.length === 0) {
    tablaContenedor.textContent = "Aun no hay encuestas enviadas en este periodo.";
    return;
  }

  const filasHtml = ultimasFilas.map((r) => `
    <tr>
      <td>${r.tipo_usuario}</td>
      <td>${r.campus}</td>
      <td>${r.participantes}</td>
      <td>${r.oculto_por_privacidad ? '<span class="oculto-privacidad">Oculto (&lt;10 respuestas)</span>' : `${r.promedio_kgco2e} kg CO2e`}</td>
      <td>${r.oculto_por_privacidad ? '<span class="oculto-privacidad">Oculto (&lt;10 respuestas)</span>' : `${r.mediana_kgco2e} kg CO2e`}</td>
    </tr>
  `).join("");

  tablaContenedor.innerHTML = `
    <p><strong>Periodo:</strong> ${period.name} | <strong>Denominador institucional:</strong> ${period.expected_population ?? "No cargado (no se calcula tasa de respuesta)"}</p>
    <table class="tabla-datos">
      <thead><tr><th>Grupo</th><th>Campus</th><th>Participantes (n)</th><th>Promedio</th><th>Mediana</th></tr></thead>
      <tbody>${filasHtml}</tbody>
    </table>
  `;
}

btnCsv?.addEventListener("click", () => {
  const csv = generarCsvAgregado(ultimasFilas);
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "huellaviva_uan_agregado.csv";
  a.click();
});

cargarDashboard();
'@

Write-Host "Integracion completada. Recuerda ejecutar 003_factores_y_auditoria.sql en Supabase." -ForegroundColor Cyan