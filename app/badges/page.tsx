import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Brand } from "@/components/brand";

type Badge = {
  id: string;
  course_title: string;
  badge_title: string;
  badge_description: string;
  issued_at: string;
};

export default async function BadgesPage() {
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data, error } = await supabase
    .from("course_badges")
    .select("id, course_title, badge_title, badge_description, issued_at")
    .eq("user_id", auth.user.id)
    .order("issued_at", { ascending: false });

  if (error) throw new Error("Your badges could not be loaded. Please refresh.");

  const badges = (data ?? []) as Badge[];

  return (
    <main className="badges-page">
      <header className="site-header">
        <Brand />
        <nav aria-label="Badge navigation">
          <Link href="/dashboard">Dashboard</Link>
          <Link href="/account">My account</Link>
          <Link href="/courses">Explore courses</Link>
        </nav>
      </header>
      <section className="badges-content">
        <p className="eyebrow">YOUR ACHIEVEMENTS</p>
        <h1>My badges</h1>
        <p className="badges-intro">A record of the courses you have completed at Kaizora.</p>
        {badges.length === 0 ? (
          <div className="badges-empty">
            <h2>Your first badge is waiting.</h2>
            <p>Complete every published lesson in an enrolled course to earn its completion badge.</p>
            <Link className="button button-primary" href="/courses">Explore courses <span>→</span></Link>
          </div>
        ) : (
          <div className="badges-grid">
            {badges.map((badge) => (
              <article className="learner-badge-card" key={badge.id}>
                <div className="learner-badge-mark" aria-hidden="true"><span>✓</span></div>
                <p className="eyebrow">KAIZORA AI ACADEMY</p>
                <h2>{badge.badge_title}</h2>
                <h3>{badge.course_title}</h3>
                <p>{badge.badge_description}</p>
                <time dateTime={badge.issued_at}>Issued {new Date(badge.issued_at).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" })}</time>
              </article>
            ))}
          </div>
        )}
        <Link className="account-back-link" href="/dashboard">← Back to dashboard</Link>
      </section>
    </main>
  );
}
