import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Brand } from "@/components/brand";
import { AccountProfileForm } from "@/components/account-profile-form";
import { updateProfileAction } from "./actions";

export default async function AccountPage() {
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("full_name, created_at")
    .eq("id", auth.user.id)
    .maybeSingle();

  if (error) throw new Error("Your account profile could not be loaded. Please refresh.");

  const fullName = profile?.full_name || (
    typeof auth.user.user_metadata.full_name === "string" ? auth.user.user_metadata.full_name : ""
  );

  return (
    <main className="account-page">
      <header className="site-header">
        <Brand />
        <nav aria-label="Account navigation">
          <Link href="/dashboard">Dashboard</Link>
          <Link href="/badges">My badges</Link>
          <Link href="/courses">Explore courses</Link>
        </nav>
      </header>
      <section className="account-content">
        <p className="eyebrow">LEARNER SETTINGS</p>
        <h1>My account</h1>
        <p className="account-intro">Manage the details attached to your Kaizora learner profile.</p>
        <section className="account-card">
          <h2>Profile details</h2>
          <p className="account-help">Your name is used on your learner profile and course achievements.</p>
          <AccountProfileForm fullName={fullName} action={updateProfileAction} />
        </section>
        <section className="account-card">
          <h2>Sign-in details</h2>
          <div className="account-detail">
            <span>Email address</span>
            <strong>{auth.user.email ?? "Not available"}</strong>
            <small>{auth.user.email_confirmed_at ? "Email confirmed" : "Email confirmation pending"}</small>
          </div>
          <Link className="account-secondary-link" href="/forgot-password">Reset or change password →</Link>
        </section>
        <Link className="account-back-link" href="/dashboard">← Back to dashboard</Link>
      </section>
    </main>
  );
}
