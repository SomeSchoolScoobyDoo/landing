import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import {
  addOrganisationDomainAction,
  verifyOrganisationDomainAction,
  requestOrganisationVerificationCallAction,
} from "../../verification-actions";

type DomainClaim = {
  id: string;
  domain: string;
  challenge_token: string;
  verification_status: string;
  verified_at: string | null;
  created_at: string;
};

type VerificationRequest = {
  id: string;
  method: string;
  status: string;
  submitted_at: string;
  requested_call_at: string | null;
  scheduled_call_at: string | null;
};

export default async function OrganisationVerificationPage({
  params,
  searchParams,
}: {
  params: Promise<{ organisationId: string }>;
  searchParams: Promise<{ error?: string; domain?: string; request?: string }>;
}) {
  const { organisationId } = await params;
  const query = await searchParams;
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
    notFound();
  }

  const { data: organisation } = await supabase
    .from("organizations")
    .select("id, name, organization_type, status, verification_status, verification_method")
    .eq("id", organisationId)
    .maybeSingle();

  if (!organisation) notFound();

  const admin = createAdminClient();
  let domains: DomainClaim[] = [];
  let requests: VerificationRequest[] = [];

  if (admin) {
    const [domainResult, requestResult] = await Promise.all([
      admin.from("organization_domains").select("id, domain, challenge_token, verification_status, verified_at, created_at").eq("organization_id", organisationId).order("created_at", { ascending: false }),
      admin.from("organization_verification_requests").select("id, method, status, submitted_at, requested_call_at, scheduled_call_at").eq("organization_id", organisationId).order("submitted_at", { ascending: false }),
    ]);
    domains = (domainResult.data ?? []) as DomainClaim[];
    requests = (requestResult.data ?? []) as VerificationRequest[];
  }

  const messages: Record<string, string> = {
    domain: "Enter a valid domain such as example.com, without https:// or a page path.",
    config: "Verification is not configured yet. The platform administrator needs to add the server-side Supabase service key.",
    "domain-save": "We could not save this domain claim. It may already be attached to another organisation.",
    claim: "That domain claim could not be found or is no longer active.",
    dns: "The DNS TXT record was not found yet. Add the exact record below, allow time for DNS propagation, then check again.",
    verify: "The DNS record was found, but we could not save the verification result.",
    details: "Check the contact details and make sure the reason is at least 10 characters.",
    request: "We could not submit your verification-call request. Please try again.",
  };

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "42px 22px 72px", color: "var(--foreground, #f4f4f4)" }}>
      <Link href="/organisations" style={{ color: "#c5f36b", textDecoration: "none", fontSize: 14 }}>← Your organisations</Link>
      <p style={{ color: "#9ca3af", fontSize: 12, letterSpacing: "0.14em", textTransform: "uppercase", margin: "28px 0 10px" }}>Organisation verification</p>
      <h1 style={{ fontSize: "clamp(28px, 5vw, 40px)", lineHeight: 1.1, margin: 0 }}>{organisation.name}</h1>
      <p style={{ color: "#a7adb5", lineHeight: 1.6, marginTop: 12 }}>
        Account status: {organisation.status.replaceAll("_", " ")} · Verification: {organisation.verification_status.replaceAll("_", " ")}
      </p>

      {query.error && <p role="alert" style={{ padding: 14, border: "1px solid #7b3d3d", borderRadius: 10, color: "#ffb4a9" }}>{messages[query.error] ?? "Something went wrong. Please try again."}</p>}
      {query.domain === "added" && <p role="status" style={{ padding: 14, border: "1px solid #526d37", borderRadius: 10, color: "#d7f5ad" }}>Domain claim created. Add the DNS TXT record shown below, then verify it.</p>}
      {query.domain === "verified" && <p role="status" style={{ padding: 14, border: "1px solid #526d37", borderRadius: 10, color: "#d7f5ad" }}>Domain control confirmed. Kaizora still needs to verify that you are authorised to represent this organisation.</p>}
      {query.request === "submitted" && <p role="status" style={{ padding: 14, border: "1px solid #526d37", borderRadius: 10, color: "#d7f5ad" }}>Your call request has been submitted for manual review. It is not an automatic verification.</p>}

      {!admin && <p role="alert" style={{ color: "#ffcf8a" }}>The server-side verification service is not configured. No challenge or request can be submitted yet.</p>}

      <section style={{ marginTop: 28, padding: 22, border: "1px solid #30363d", borderRadius: 16, background: "rgba(255,255,255,0.025)" }}>
        <h2 style={{ margin: "0 0 8px", fontSize: 22 }}>Verify your website domain</h2>
        <p style={{ color: "#a7adb5", lineHeight: 1.6, marginTop: 0 }}>Prove control by adding a DNS TXT record. You can attach more than one domain to this organisation.</p>
        <form action={addOrganisationDomainAction} style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <input type="hidden" name="organisation_id" value={organisationId} />
          <label style={{ display: "grid", flex: "1 1 260px", gap: 7, fontSize: 13, fontWeight: 600 }}>Website domain
            <input name="domain" type="text" required placeholder="example.com" autoComplete="url" style={{ minHeight: 46, borderRadius: 9, border: "1px solid #4b5563", padding: "0 12px", background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
          </label>
          <button type="submit" disabled={!admin} style={{ alignSelf: "end", minHeight: 46, padding: "0 16px", border: 0, borderRadius: 9, background: "#c5f36b", color: "#10130b", fontWeight: 700, cursor: admin ? "pointer" : "not-allowed" }}>Add domain</button>
        </form>

        {domains.length > 0 && <div style={{ display: "grid", gap: 14, marginTop: 22 }}>
          {domains.map((domain) => (
            <article key={domain.id} style={{ borderTop: "1px solid #30363d", paddingTop: 16 }}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
                <strong>{domain.domain}</strong>
                <span style={{ color: domain.verification_status === "verified" ? "#c5f36b" : "#a7adb5", fontSize: 13 }}>{domain.verification_status.replaceAll("_", " ")}</span>
              </div>
              {domain.verification_status !== "verified" && (
                <>
                  <p style={{ color: "#a7adb5", fontSize: 13, lineHeight: 1.5 }}>Create a TXT record with this host/name and exact value:</p>
                  <p style={{ fontSize: 13, overflowWrap: "anywhere" }}><strong>Host:</strong> _kaizora-verification.{domain.domain}</p>
                  <p style={{ fontSize: 13, overflowWrap: "anywhere" }}><strong>Value:</strong> {domain.challenge_token}</p>
                  <form action={verifyOrganisationDomainAction}>
                    <input type="hidden" name="organisation_id" value={organisationId} />
                    <input type="hidden" name="domain_id" value={domain.id} />
                    <button type="submit" disabled={!admin} style={{ minHeight: 42, padding: "0 14px", border: "1px solid #59636f", borderRadius: 9, background: "transparent", color: "#f4f4f4", fontWeight: 600, cursor: "pointer" }}>Check DNS record</button>
                  </form>
                </>
              )}
              {domain.verified_at && <p style={{ color: "#a7adb5", fontSize: 12 }}>Domain verified {new Date(domain.verified_at).toLocaleString("en-GB")}</p>}
            </article>
          ))}
        </div>}
      </section>

      <section style={{ marginTop: 20, padding: 22, border: "1px solid #30363d", borderRadius: 16, background: "rgba(255,255,255,0.025)" }}>
        <h2 style={{ margin: "0 0 8px", fontSize: 22 }}>No website? Request a verification call</h2>
        <p style={{ color: "#a7adb5", lineHeight: 1.6, marginTop: 0 }}>A verification officer will review the organisation and your authority to represent it. A call is evidence-gathering, not automatic approval.</p>
        <form action={requestOrganisationVerificationCallAction} style={{ display: "grid", gap: 14 }}>
          <input type="hidden" name="organisation_id" value={organisationId} />
          <label style={{ display: "grid", gap: 7, fontSize: 13, fontWeight: 600 }}>Your full name
            <input name="contact_name" required minLength={2} maxLength={120} style={{ minHeight: 44, borderRadius: 9, border: "1px solid #4b5563", padding: "0 12px", background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
          </label>
          <label style={{ display: "grid", gap: 7, fontSize: 13, fontWeight: 600 }}>Your position in the organisation
            <input name="applicant_position" required minLength={2} maxLength={120} placeholder="e.g. Founder, Principal, HR Manager" style={{ minHeight: 44, borderRadius: 9, border: "1px solid #4b5563", padding: "0 12px", background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
          </label>
          <label style={{ display: "grid", gap: 7, fontSize: 13, fontWeight: 600 }}>Organisation&apos;s operating address
            <textarea name="operating_address" required minLength={5} maxLength={500} rows={2} style={{ borderRadius: 9, border: "1px solid #4b5563", padding: 12, background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
          </label>
          <label style={{ display: "grid", gap: 7, fontSize: 13, fontWeight: 600 }}>Why are you creating this organisation account?
            <textarea name="reason" required minLength={10} maxLength={2000} rows={3} style={{ borderRadius: 9, border: "1px solid #4b5563", padding: 12, background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
          </label>
          <label style={{ display: "grid", gap: 7, fontSize: 13, fontWeight: 600 }}>Preferred call time (optional)
            <input name="requested_call_at" type="datetime-local" style={{ minHeight: 44, borderRadius: 9, border: "1px solid #4b5563", padding: "0 12px", background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
          </label>
          <button type="submit" disabled={!admin} style={{ minHeight: 46, border: 0, borderRadius: 9, background: "#c5f36b", color: "#10130b", fontWeight: 700, cursor: admin ? "pointer" : "not-allowed" }}>Request verification call</button>
        </form>

        {requests.length > 0 && <div style={{ marginTop: 24, borderTop: "1px solid #30363d", paddingTop: 16 }}>
          <h3 style={{ margin: "0 0 12px", fontSize: 16 }}>Previous requests</h3>
          {requests.map((request) => <p key={request.id} style={{ color: "#a7adb5", fontSize: 13, margin: "8px 0" }}>{request.method === "call" ? "Verification call" : "Document review"} · {request.status.replaceAll("_", " ")} · {new Date(request.submitted_at).toLocaleDateString("en-GB")}</p>)}
        </div>}
        <p style={{ color: "#858d96", fontSize: 12, lineHeight: 1.55, marginTop: 16 }}>Document-only review and file uploads are not enabled yet. The manual call route is available as the initial no-website path.</p>
      </section>
    </main>
  );
}
