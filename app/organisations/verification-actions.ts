"use server";

import { randomBytes } from "node:crypto";
import { resolveTxt } from "node:dns/promises";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

async function requireOrganisationAdmin(organisationId: string) {
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: membership } = await supabase
    .from("organization_memberships")
    .select("membership_role")
    .eq("organization_id", organisationId)
    .eq("user_id", auth.user.id)
    .maybeSingle();

  if (!membership || !["school_admin", "corporate_admin"].includes(membership.membership_role)) {
    redirect("/organisations");
  }

  return { supabase, user: auth.user };
}

function normalizeDomain(value: FormDataEntryValue | null) {
  const raw = String(value ?? "").trim().toLowerCase().replace(/\.$/, "");
  if (!/^(?=.{3,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(raw)) {
    return null;
  }
  return raw;
}

export async function addOrganisationDomainAction(formData: FormData) {
  const organisationId = String(formData.get("organisation_id") ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(organisationId)) redirect("/organisations");
  const { user } = await requireOrganisationAdmin(organisationId);
  const domain = normalizeDomain(formData.get("domain"));
  if (!domain) redirect(`/organisations/${organisationId}/verification?error=domain`);

  const admin = createAdminClient();
  if (!admin) redirect(`/organisations/${organisationId}/verification?error=config`);

  const challengeToken = `kaizora-verification=${randomBytes(24).toString("hex")}`;
  const { error } = await admin.from("organization_domains").insert({
    organization_id: organisationId,
    domain,
    challenge_token: challengeToken,
    created_by: user.id,
  });

  if (error) redirect(`/organisations/${organisationId}/verification?error=domain-save`);
  redirect(`/organisations/${organisationId}/verification?domain=added`);
}

export async function verifyOrganisationDomainAction(formData: FormData) {
  const organisationId = String(formData.get("organisation_id") ?? "");
  const domainId = String(formData.get("domain_id") ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(organisationId) || !/^[0-9a-f-]{36}$/i.test(domainId)) {
    redirect("/organisations");
  }

  await requireOrganisationAdmin(organisationId);
  const admin = createAdminClient();
  if (!admin) redirect(`/organisations/${organisationId}/verification?error=config`);

  const { data: claim, error: claimError } = await admin
    .from("organization_domains")
    .select("id, domain, challenge_token, verification_status")
    .eq("id", domainId)
    .eq("organization_id", organisationId)
    .maybeSingle();

  if (claimError || !claim || claim.verification_status === "revoked") {
    redirect(`/organisations/${organisationId}/verification?error=claim`);
  }

  const recordName = `_kaizora-verification.${claim.domain}`;
  let records: string[][] = [];
  try {
    records = await resolveTxt(recordName);
  } catch {
    await admin.from("organization_domains").update({ last_checked_at: new Date().toISOString() }).eq("id", domainId);
    redirect(`/organisations/${organisationId}/verification?error=dns`);
  }

  const found = records.some((record) => record.join("").trim() === claim.challenge_token);
  if (!found) {
    await admin.from("organization_domains").update({ last_checked_at: new Date().toISOString() }).eq("id", domainId);
    redirect(`/organisations/${organisationId}/verification?error=dns`);
  }

  const now = new Date().toISOString();
  const { error: updateError } = await admin
    .from("organization_domains")
    .update({ verification_status: "verified", verified_at: now, last_checked_at: now })
    .eq("id", domainId)
    .eq("organization_id", organisationId);

  if (updateError) redirect(`/organisations/${organisationId}/verification?error=verify`);

  // Domain control is verified here. Applicant authority remains a separate
  // review, so this does not activate the organisation or unlock admin features.
  await admin
    .from("organizations")
    .update({ verification_status: "pending", verification_method: "dns_txt" })
    .eq("id", organisationId)
    .neq("verification_status", "verified");

  redirect(`/organisations/${organisationId}/verification?domain=verified`);
}

export async function requestOrganisationVerificationCallAction(formData: FormData) {
  const organisationId = String(formData.get("organisation_id") ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(organisationId)) redirect("/organisations");
  const { user } = await requireOrganisationAdmin(organisationId);
  const admin = createAdminClient();
  if (!admin) redirect(`/organisations/${organisationId}/verification?error=config`);

  const contactName = String(formData.get("contact_name") ?? "").trim();
  const position = String(formData.get("applicant_position") ?? "").trim();
  const address = String(formData.get("operating_address") ?? "").trim();
  const reason = String(formData.get("reason") ?? "").trim();
  const requestedCallRaw = String(formData.get("requested_call_at") ?? "").trim();
  const requestedCallAt = requestedCallRaw ? new Date(requestedCallRaw) : null;

  if (
    contactName.length < 2 || contactName.length > 120 ||
    position.length < 2 || position.length > 120 ||
    address.length < 5 || address.length > 500 ||
    reason.length < 10 || reason.length > 2000 ||
    (requestedCallAt && Number.isNaN(requestedCallAt.getTime()))
  ) {
    redirect(`/organisations/${organisationId}/verification?error=details`);
  }

  const { error } = await admin.from("organization_verification_requests").insert({
    organization_id: organisationId,
    applicant_user_id: user.id,
    method: "call",
    contact_name: contactName,
    applicant_position: position,
    operating_address: address,
    reason,
    requested_call_at: requestedCallAt?.toISOString() ?? null,
  });

  if (error) redirect(`/organisations/${organisationId}/verification?error=request`);

  await admin
    .from("organizations")
    .update({ verification_status: "pending", verification_method: "manual_call" })
    .eq("id", organisationId)
    .neq("verification_status", "verified");

  redirect(`/organisations/${organisationId}/verification?request=submitted`);
}
