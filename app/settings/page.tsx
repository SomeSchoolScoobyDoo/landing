import { redirect } from "next/navigation";
import { Brand } from "@/components/brand";
import { LearnerNavigation } from "@/components/learner-navigation";
import { createClient } from "@/lib/supabase/server";
import { signOutAction } from "@/app/auth/actions";
import { updateCertificateDisplayNameAction, updateProfileNameAction } from "./actions";

type SearchParams = {
  profile?: string;
  certificateName?: string;
};

export default async function SettingsPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const params = await searchParams;
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("full_name, certificate_display_name")
    .eq("id", auth.user.id)
    .maybeSingle();

  if (profileError) throw new Error("Your account settings could not be loaded. Please refresh.");

  return (
    <main className="dashboard-page">
      <header className="site-header">
        <Brand />
        <LearnerNavigation />
        <form action={signOutAction}>
          <button className="signout-button" type="submit">Sign out</button>
        </form>
      </header>

      <section className="learner-dashboard">
        <div className="learner-dashboard-heading">
          <div>
            <p className="eyebrow">ACCOUNT</p>
            <h1>Settings<span>.</span></h1>
            <p>Manage your profile and how your name appears on Kaizora credentials.</p>
          </div>
        </div>

        {params.profile === "saved" && <p className="dashboard-notice" role="status">Your profile name has been updated.</p>}
        {params.certificateName === "saved" && <p className="dashboard-notice" role="status">Your certificate display name has been updated.</p>}

        <section className="dashboard-section" aria-labelledby="account-heading">
          <div className="dashboard-section-heading">
            <div><p className="eyebrow">ACCOUNT DETAILS</p><h2 id="account-heading">Your account</h2></div>
          </div>
          <p className="dashboard-muted">Signed in as <strong>{auth.user.email}</strong></p>
        </section>

        <section className="dashboard-section" aria-labelledby="profile-name-heading">
          <div className="dashboard-section-heading">
            <div><p className="eyebrow">PROFILE</p><h2 id="profile-name-heading">Profile name</h2></div>
          </div>
          <p className="dashboard-muted">This is the name used for your learner account and dashboard greeting.</p>
          <form action={updateProfileNameAction} className="auth-form" style={{ maxWidth: "520px" }}>
            <label className="auth-field">
              <span>Your profile name</span>
              <input name="fullName" type="text" required minLength={2} maxLength={120} defaultValue={profile?.full_name ?? ""} autoComplete="name" />
            </label>
            <button className="auth-submit" type="submit">Save profile name</button>
          </form>
        </section>

        <section className="dashboard-section" aria-labelledby="certificate-name-heading">
          <div className="dashboard-section-heading">
            <div><p className="eyebrow">CERTIFICATES AND BADGES</p><h2 id="certificate-name-heading">Certificate display name</h2></div>
          </div>
          <p className="dashboard-muted">Choose how your name should appear on certificates and future badges. This is separate from your account profile name. Leave it blank to use your profile name.</p>
          <form action={updateCertificateDisplayNameAction} className="auth-form" style={{ maxWidth: "520px" }}>
            <label className="auth-field">
              <span>Name to print on your credentials</span>
              <input name="certificateDisplayName" type="text" maxLength={120} defaultValue={profile?.certificate_display_name ?? ""} autoComplete="name" />
            </label>
            <button className="auth-submit" type="submit">Save certificate name</button>
          </form>
        </section>
      </section>
    </main>
  );
}
