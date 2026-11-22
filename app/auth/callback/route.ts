import { NextResponse, type NextRequest } from "next/server";
import { randomUUID } from "node:crypto";
import { createClient } from "@/lib/supabase/server";

function safePath(value: string | null) {
  if (!value || !value.startsWith("/") || value.startsWith("//") || value.includes(String.fromCharCode(92))) return "/dashboard";
  return value;
}

function errorDetails(error: unknown) {
  if (!error || typeof error !== "object") {
    return { message: typeof error === "string" ? error.slice(0, 240) : "Unknown callback error" };
  }
  const value = error as { name?: unknown; message?: unknown; code?: unknown; status?: unknown; statusCode?: unknown };
  return {
    name: typeof value.name === "string" ? value.name : undefined,
    code: typeof value.code === "string" ? value.code : undefined,
    status: typeof value.status === "number" ? value.status : undefined,
    statusCode: typeof value.statusCode === "number" ? value.statusCode : undefined,
    message: typeof value.message === "string" ? value.message.slice(0, 240) : "Unknown callback error",
  };
}

export async function GET(request: NextRequest) {
  const current = new URL(request.url);
  const traceId = randomUUID();
  const next = safePath(current.searchParams.get("next"));
  const cookies = request.cookies.getAll();
  const verifierCookies = cookies
    .filter(({ name }) => name.includes("code-verifier"))
    .map(({ name }) => name);
  const context = {
    traceId,
    phase: "callback_received",
    hasAuthorizationCode: current.searchParams.has("code"),
    hasProviderError: current.searchParams.has("error"),
    providerErrorCode: current.searchParams.get("error_code")?.slice(0, 80) ?? null,
    next,
    verifierCookiePresent: verifierCookies.length > 0,
    verifierCookieNames: verifierCookies,
    authCookieNames: cookies.map(({ name }) => name).filter((name) => name.startsWith("sb-")),
    userAgent: request.headers.get("user-agent")?.slice(0, 240) ?? null,
    refererOrigin: (() => {
      try {
        const value = request.headers.get("referer");
        return value ? new URL(value).origin : null;
      } catch {
        return null;
      }
    })(),
  };

  const code = current.searchParams.get("code");
  if (code) {
    try {
      const supabase = await createClient();
      const { error } = await supabase.auth.exchangeCodeForSession(code);
      if (!error) {
        console.info("[auth-callback-debug]", JSON.stringify({ ...context, phase: "code_exchange_succeeded" }));
        return NextResponse.redirect(new URL(next, current.origin));
      }
      console.error("[auth-callback-debug]", JSON.stringify({
        ...context,
        phase: "code_exchange_failed",
        error: errorDetails(error),
      }));
    } catch (error) {
      console.error("[auth-callback-debug]", JSON.stringify({
        ...context,
        phase: "code_exchange_threw",
        error: errorDetails(error),
      }));
    }
  } else {
    console.error("[auth-callback-debug]", JSON.stringify({
      ...context,
      phase: "authorization_code_missing",
    }));
  }

  const destination = new URL("/login", current.origin);
  destination.searchParams.set("error", "confirmation");
  destination.searchParams.set("debug", traceId);
  return NextResponse.redirect(destination);
}
