import type { NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

export async function middleware(request: NextRequest) {
  return updateSession(request);
}

// Keep auth/session refresh scoped to LMS and account routes. Public marketing
// pages deliberately bypass Supabase middleware so they remain available
// during LMS outages or incomplete backend configuration.
export const config = {
  matcher: [
    "/dashboard/:path*",
    "/learn/:path*",
    "/auth/:path*",
    "/login",
    "/signup",
    "/forgot-password",
  ],
};
