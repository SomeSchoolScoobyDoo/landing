import Link from "next/link";
import { redirect } from "next/navigation";
import { Brand } from "@/components/brand";
import { LearnerNavigation } from "@/components/learner-navigation";
import { signOutAction } from "@/app/auth/actions";
import { CourseCompletionBadge } from "@/components/course-completion-badge";
import { createClient } from "@/lib/supabase/server";

type CourseBadge = {
  id: string;
  course_title: string;
  badge_title: string;
  badge_description: string;
  issued_at: string;
};

export default async function BadgesPage() {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name, certificate_display_name")
    .eq("id", auth.user.id)
    .maybeSingle();
  const learnerName =
    profile?.certificate_display_name?.trim() ||
    profile?.full_name ||
    (typeof auth.user.user_metadata?.full_name === "string"
      ? auth.user.user_metadata.full_name
      : auth.user.email?.split("@")[0]) ||
    "Kaizora Learner";

  const { data, error } = await supabase
    .from("course_badges")
    .select("id, course_title, badge_title, badge_description, issued_at")
    .eq("user_id", auth.user.id)
    .order("issued_at", { ascending: false });

  if (error) throw new Error("Your badges could not be loaded. Please refresh.");

  const badges = (data ?? []) as CourseBadge[];

  return (
    <main className="dashboard-page">
      <header className="site-header">
        <Brand />
        <LearnerNavigation />
        <form action={signOutAction}><button className="signout-button" type="submit">Sign out</button></form>
      </header>
      <section className="learner-dashboard">
        <div className="learner-dashboard-heading">
          <div>
            <p className="eyebrow">YOUR ACHIEVEMENTS</p>
            <h1>Course <span>badges</span>.</h1>
            <p>Every badge marks a course you have completed. Keep building your collection.</p>
          </div>
        </div>
        {badges.length === 0 ? (
          <div className="dashboard-empty">
            <span className="dashboard-placeholder-mark">K</span>
            <h3>Your first badge is waiting.</h3>
            <p>Complete every published lesson in an enrolled course and your Kaizora AI Academy completion badge will appear here automatically.</p>
            <Link className="button button-primary" href="/courses">Explore courses <span>→</span></Link>
          </div>
        ) : (
          <section className="dashboard-section" aria-labelledby="badges-heading">
            <div className="dashboard-section-heading">
              <div><p className="eyebrow">EARNED AND VERIFIED</p><h2 id="badges-heading">Your collection</h2></div>
              <span>{badges.length} earned</span>
            </div>
            <div className="course-badge-grid">
              {badges.map((badge) => (
                <article className="course-badge-card" key={badge.id}>
                  <CourseCompletionBadge
                    learnerName={learnerName}
                    courseTitle={badge.course_title}
                    issuedAt={badge.issued_at}
                  />
                  <p className="course-badge-description">{badge.badge_description}</p>
                </article>
              ))}
            </div>
          </section>
        )}
      </section>
      <style>{`
        .course-badge-grid{display:grid;grid-template-columns:minmax(0,1fr);gap:18px;margin-top:22px}
        .course-badge-card{background:transparent;border:0;border-radius:0;padding:0;color:#493626;text-align:center}
        .course-badge-card .kaizora-completion{margin:0 auto 12px}
        .course-badge-description{max-width:380px;margin:0 auto;color:#80694f;font-size:12px;line-height:1.7}
        @media(prefers-color-scheme:dark){.course-badge-description{color:#b7a48d}}
      `}</style>
    </main>
  );
}
