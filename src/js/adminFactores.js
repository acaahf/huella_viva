import { supabase } from "./supabaseClient.js";
const el = document.getElementById("lista-factores");
supabase.from("emission_factors").select("factor_code, value, activity_unit, version, source_name").then(({ data }) => {
  if (el && data) el.textContent = JSON.stringify(data, null, 2);
});