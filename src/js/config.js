export const APP_CONFIG = Object.freeze({
  SUPABASE_URL: window.__ENV__?.PUBLIC_SUPABASE_URL || "",
  SUPABASE_ANON_KEY: window.__ENV__?.PUBLIC_SUPABASE_ANON_KEY || "",
  METHOD_VERSION: "1.0.0-uan-academico",
  MIN_CELL_PRIVACY: 10
});