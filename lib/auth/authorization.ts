import "server-only";

import { createClient } from "@/lib/supabase/server";

export const ORGANIZATION_ROLES = [
  "school_admin",
  "lecturer",
  "student",
  "corporate_admin",
  "employee",
] as const;

export type OrganizationRole = (typeof ORGANIZATION_ROLES)[number];

export class AuthorizationError extends Error {
  constructor(
    message: string,
    public readonly statusCode: 401 | 403,
  ) {
    super(message);
    this.name = "AuthorizationError";
  }
}

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function requireOrganizationRole(
  organizationId: string,
  allowedRoles: readonly OrganizationRole[],
) {
  if (!UUID_PATTERN.test(organizationId)) {
    throw new AuthorizationError("A valid organization is required.", 403);
  }

  if (allowedRoles.length === 0) {
    throw new Error("At least one organization role must be allowed.");
  }

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();

  if (authError || !authData.user) {
    throw new AuthorizationError("Authentication is required.", 401);
  }

  const { data: permitted, error } = await supabase.rpc(
    "has_organization_role",
    {
      target_organization_id: organizationId,
      allowed_roles: [...allowedRoles],
    },
  );

  if (error) {
    throw new Error("Organization authorization could not be verified.");
  }

  if (permitted !== true) {
    throw new AuthorizationError(
      "You do not have permission to perform this action.",
      403,
    );
  }

  return { user: authData.user, organizationId };
}
