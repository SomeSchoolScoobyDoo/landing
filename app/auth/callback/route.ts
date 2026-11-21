import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
function safePath(value: string | null) {
  if (!value || !value.startsWith("/") || value.startsWith("//") || value.includes(String.fromCharCode(92))) return "/dashboard";
  return value;
}
export async function GET(request: NextRequest) {
  const current = new URL(request.url);
  const code = current.searchParams.get("code");
  const next = safePath(current.searchParams.get("next"));
  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(new URL(next, current.origin));
  }
  return NextResponse.redirect(new URL("/login?error=confirmation", current.origin));
}
