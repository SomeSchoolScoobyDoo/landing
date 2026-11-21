import "server-only";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";

type AuditEventInput = {
  actorUserId?: string | null;
  organizationId?: string | null;
  action: string;
  targetType?: string | null;
  targetId?: string | null;
  metadata?: Record<string, unknown>;
};

export async function writeAuditEvent(input: AuditEventInput) {
  const action = input.action.trim();
  if (action.length < 1 || action.length > 120) {
    throw new Error("Audit action must be between 1 and 120 characters.");
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceRoleKey) {
    throw new Error("The server-side audit writer is not configured.");
  }

  const admin = createSupabaseClient(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });

  const { error } = await admin.from("audit_events").insert({
    actor_user_id: input.actorUserId ?? null,
    organization_id: input.organizationId ?? null,
    action,
    target_type: input.targetType ?? null,
    target_id: input.targetId ?? null,
    metadata: input.metadata ?? {},
  });

  if (error) {
    throw new Error("The audit event could not be recorded.");
  }
}
