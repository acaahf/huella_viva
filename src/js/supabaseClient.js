import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";
export const configurado = Boolean(SUPABASE_URL && SUPABASE_ANON_KEY);
export const supabase = createClient(SUPABASE_URL || "https://example.supabase.co", SUPABASE_ANON_KEY || "anon-no-configurada");
