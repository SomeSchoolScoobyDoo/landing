import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createOrganisationAction } from "../actions";

export default async function NewOrganisationPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();

  if (authError || !auth.user) redirect("/login");

  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 22px 72px", color: "var(--foreground, #f4f4f4)" }}>
      <Link href="/organisations" style={{ color: "#c5f36b", textDecoration: "none", fontSize: 14 }}>← Your organisations</Link>
      <p style={{ color: "#9ca3af", fontSize: 12, letterSpacing: "0.14em", textTransform: "uppercase", margin: "28px 0 10px" }}>Organisation setup</p>
      <h1 style={{ fontSize: "clamp(30px, 5vw, 42px)", lineHeight: 1.08, margin: 0 }}>Create an organisation account</h1>
      <p style={{ color: "#a7adb5", lineHeight: 1.65, maxWidth: 600, marginTop: 14 }}>
        Use your existing Kaizora account. You can manage multiple organisations, each with its own members, roles and verification.
      </p>

      {error && (
        <p role="alert" style={{ marginTop: 20, padding: 14, border: "1px solid #7b3d3d", borderRadius: 10, color: "#ffb4a9" }}>
          {error === "invalid" ? "Check the organisation name and account type, then try again." : "We could not create the organisation account. Please try again."}
        </p>
      )}

      <form action={createOrganisationAction} style={{ display: "grid", gap: 18, marginTop: 30, padding: 24, border: "1px solid #30363d", borderRadius: 16, background: "rgba(255,255,255,0.025)" }}>
        <label style={{ display: "grid", gap: 8, fontSize: 14, fontWeight: 600 }}>
          Organisation name
          <input name="name" required minLength={2} maxLength={160} placeholder="e.g. Bright Future Academy" style={{ width: "100%", minHeight: 48, borderRadius: 9, border: "1px solid #4b5563", padding: "0 13px", background: "#15191d", color: "#f4f4f4", font: "inherit" }} />
        </label>

        <fieldset style={{ border: 0, padding: 0, margin: 0, display: "grid", gap: 10 }}>
          <legend style={{ fontSize: 14, fontWeight: 600, marginBottom: 10 }}>What kind of organisation is this?</legend>
          <label style={{ display: "flex", gap: 12, alignItems: "flex-start", padding: 15, border: "1px solid #3b434c", borderRadius: 11, cursor: "pointer" }}>
            <input type="radio" name="organization_type" value="school" required style={{ marginTop: 4 }} />
            <span><strong style={{ display: "block" }}>School or training institute</strong><span style={{ display: "block", color: "#a7adb5", fontSize: 13, marginTop: 4 }}>For schools, academies, colleges and training providers.</span></span>
          </label>
          <label style={{ display: "flex", gap: 12, alignItems: "flex-start", padding: 15, border: "1px solid #3b434c", borderRadius: 11, cursor: "pointer" }}>
            <input type="radio" name="organization_type" value="corporation" required style={{ marginTop: 4 }} />
            <span><strong style={{ display: "block" }}>Business or workplace</strong><span style={{ display: "block", color: "#a7adb5", fontSize: 13, marginTop: 4 }}>For companies managing employee learning and development.</span></span>
          </label>
        </fieldset>

        <p style={{ color: "#a7adb5", fontSize: 13, lineHeight: 1.55, margin: 0 }}>
          Creating the account does not verify the organisation. You will be able to complete website/domain verification or request manual review.
        </p>
        <button type="submit" style={{ minHeight: 48, border: 0, borderRadius: 10, background: "#c5f36b", color: "#10130b", fontWeight: 700, fontSize: 15, cursor: "pointer" }}>Create organisation account</button>
      </form>
    </main>
  );
}
