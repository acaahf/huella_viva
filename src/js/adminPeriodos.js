import { supabase } from "./supabaseClient.js";
const el = document.getElementById("lista-periodos");
supabase.from("survey_periods").select("code, name, is_open").then(({ data }) => {
  if (el && data) el.textContent = JSON.stringify(data, null, 2);
});