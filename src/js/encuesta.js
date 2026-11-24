import { supabase } from "./supabaseClient.js";
import { $, msg, requireUser } from "./ui.js";
import { validar } from "./validaciones.js";
import { emisionesKg } from "./calculo.js";

async function iniciar(user) {
  const { data: c } = await supabase.from("consents").select("id").eq("profile_id", user.id).is("revoked_at", null).limit(1);
  if (!c?.length) { location.href = "consentimiento.html"; return; }
  const { data: p } = await supabase.from("survey_periods").select("*").eq("status", "abierto")
    .order("id", { ascending: false }).limit(1).maybeSingle();
  if (!p) return msg("No hay un periodo abierto.", true);
  $("#periodo").textContent = `${p.name} (${p.start_date} a ${p.end_date})`;
  let { data: s } = await supabase.from("surveys").select("*").eq("profile_id", user.id).eq("period_id", p.id).maybeSingle();
  if (!s) {
    const r = await supabase.from("surveys").insert({ profile_id: user.id, period_id: p.id }).select().single();
    if (r.error) return msg(r.error.message, true);
    s = r.data;
  }
  if (s.status === "enviada") { $("#form").hidden = true; return msg("Ya enviaste tu encuesta. Consulta tu informe."); }

  const { data: a } = await supabase.from("activity_answers").select("*").eq("survey_id", s.id);
  for (const r of a || []) {
    if (r.question_code === "elec_kwh") { $("#kwh").value = r.numeric_value; $("#estimado").checked = r.is_estimated; }
    if (r.question_code === "elec_personas") $("#personas").value = r.numeric_value;
  }
  const { data: f } = await supabase.from("emission_factors").select("factor_value").eq("question_code", "elec_kwh")
    .order("version", { ascending: false }).limit(1).maybeSingle();
  const vista = () => {
    const k = validar($("#kwh").value, 0, 20000), n = validar($("#personas").value, 1, 30, true);
    $("#vista").textContent = (f && !k.error && !n.error)
      ? `Vista previa: ${emisionesKg(k.valor, Number(f.factor_value), n.valor).toFixed(2)} kg CO2e (estimación)` : "";
  };
  $("#kwh").addEventListener("input", vista); $("#personas").addEventListener("input", vista); vista();

  const filas = () => {
    const k = validar($("#kwh").value, 0, 20000), n = validar($("#personas").value, 1, 30, true);
    if (k.error || n.error) throw new Error(k.error || n.error);
    return [
      { survey_id: s.id, category: "electricidad", question_code: "elec_kwh", numeric_value: k.valor, unit: "kWh", is_estimated: $("#estimado").checked },
      { survey_id: s.id, category: "electricidad", question_code: "elec_personas", numeric_value: n.valor, unit: "personas", is_estimated: false }];
  };
  const guardar = async () => {
    const { error } = await supabase.from("activity_answers").upsert(filas(), { onConflict: "survey_id,question_code" });
    if (error) throw error;
  };
  $("#guardar").addEventListener("click", async () => { try { await guardar(); msg("Borrador guardado."); } catch (e) { msg(e.message, true); } });
  $("#enviar").addEventListener("click", async () => {
    try {
      await guardar();
      const u = await supabase.from("surveys").update({ status: "enviada", submitted_at: new Date().toISOString(), updated_at: new Date().toISOString() }).eq("id", s.id);
      if (u.error) throw u.error;
      const r = await supabase.rpc("calcular_huella", { p_survey: s.id });
      if (r.error) throw r.error;
      location.href = "informe.html";
    } catch (e) { msg(e.message, true); }
  });
}
const user = await requireUser();
if (user) await iniciar(user);
