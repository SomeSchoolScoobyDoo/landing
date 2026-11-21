import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { getSupabasePublicEnv } from "@/lib/supabase/env";
export async function createClient() {
  const store = await cookies();
  const env = getSupabasePublicEnv();
  return createServerClient(env.url, env.key, { cookies: {
    getAll() { return store.getAll(); },
    setAll(values) { try { values.forEach(({ name, value, options }) => store.set(name, value, options)); } catch { /* Middleware refreshes cookies for Server Components. */ } },
  }});
}
