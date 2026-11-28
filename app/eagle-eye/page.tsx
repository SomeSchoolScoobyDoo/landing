import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getEagleEyeOverview } from "@/lib/eagle-eye/overview";
import { Brand } from "@/components/brand";
import { signOutAction } from "@/app/auth/actions";
import "./eagle-eye.css";

function Metric({ label, value, note }: { label: string; value: number | string; note: string }) {
  return (
    <article className="eagle-metric">
      <span>{label}</span>
      <strong>{typeof value === "number" ? value.toLocaleString() : value}</strong>
      <small>{note}</small>
    </article>
  );
}

export default async function EagleEyePage() {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login?next=/eagle-eye");

  // The allowlist is read only with the server-side service key. A missing
  // configuration, query error, or absent row fails closed.
  const overview = await getEagleEyeOverview(user.id);
  if (!overview.configured || !overview.authorized) notFound();
  const metrics = overview.data;

  return (
    <main className="eagle-page">
      <header className="eagle-header">
        <Brand />
        <div className="eagle-header-right">
          <span className="eagle-private-label">PRIVATE OWNER CONSOLE</span>
          <form action={signOutAction}><button className="signout-button" type="submit">Sign out</button></form>
        </div>
      </header>

      <div className="eagle-layout">
        <aside className="eagle-sidebar" aria-label="Eagle Eye navigation">
          <p className="eyebrow">COMMAND CENTRE</p>
          <a className="active" href="#overview">Overview</a>
          <a href="#acquisition">Visitors & acquisition</a>
          <a href="#learning">Learners & learning</a>
          <a href="#testers">Beta testers</a>
          <a href="#operations">Support & moderation</a>
          <a href="#platform">Platform health</a>
          <a href="#revenue">Revenue</a>
          <div className="eagle-sidebar-footer"><span>KAIZORA AI ACADEMY</span><small>Owner access only</small></div>
        </aside>

        <div className="eagle-main">
          <section className="eagle-heading" id="overview">
            <div><p className="eyebrow">EAGLE EYE · PLATFORM INTELLIGENCE</p><h1>Your platform, <span>in view.</span></h1><p>Monitor learner growth, course activity, acquisition and operational health from one private workspace.</p></div>
            <span className="eagle-live-status"><i /> OWNER VIEW</span>
          </section>

          {!overview.configured && <p className="eagle-setup-notice" role="status">Live platform metrics are waiting for the server-only Supabase service key to be configured in the protected project settings.</p>}
          {overview.configured && !metrics && <p className="eagle-setup-notice" role="status">The database connection is present, but one or more overview queries failed. No partial totals are being presented as complete.</p>}

          <section className="eagle-section" aria-labelledby="growth-heading">
            <div className="eagle-section-heading"><div><p className="eyebrow">GROWTH</p><h2 id="growth-heading">Learners & course activity</h2></div><span>Current totals</span></div>
            <div className="eagle-metric-grid">
              <Metric label="Registered learners" value={metrics?.registeredUsers ?? "—"} note="All learner profiles" />
              <Metric label="New today" value={metrics?.newUsersToday ?? "—"} note="UTC day boundary" />
              <Metric label="Active enrolments" value={metrics?.activeEnrolments ?? "—"} note="Currently active course access" />
              <Metric label="Published courses" value={metrics?.publishedCourses ?? "—"} note="Visible in the public catalogue" />
              <Metric label="Lessons completed" value={metrics?.completedLessons ?? "—"} note="Recorded learner completions" />
              <Metric label="Assessment attempts" value={metrics?.assessmentAttempts ?? "—"} note="Submitted quiz and assessment attempts" />
            </div>
          </section>

          <section className="eagle-section" id="acquisition" aria-labelledby="acquisition-heading">
            <div className="eagle-section-heading"><div><p className="eyebrow">ACQUISITION</p><h2 id="acquisition-heading">Visitors & course discovery</h2></div><span>PostHog connection</span></div>
            <div className="eagle-panel-grid">
              <article className="eagle-panel eagle-panel-wide"><h3>Where course interest starts</h3><p>Course clicks record the source page, page placement, course slug and destination. Course-detail views are tracked separately, so clicks can be compared with actual preview visits once the PostHog project key is configured.</p><span className="eagle-panel-state">EVENT INSTRUMENTATION ADDED · AWAITING PROJECT CONFIGURATION</span></article>
              <article className="eagle-panel"><h3>Visitor funnel</h3><p>Unique visitors, page views, course clicks, registrations and enrolments will be separated into distinct stages.</p><span className="eagle-panel-state">AWAITING EVENT DATA</span></article>
            </div>
          </section>

          <section className="eagle-section" id="learning" aria-labelledby="learning-heading">
            <div className="eagle-section-heading"><div><p className="eyebrow">LEARNING QUALITY</p><h2 id="learning-heading">Course performance</h2></div><span>Operational view</span></div>
            <div className="eagle-panel-grid">
              <article className="eagle-panel"><h3>Course engagement</h3><p>Compare enrolments, lesson progress, assessment participation and completion by course.</p><span className="eagle-panel-state">METRIC FOUNDATION AVAILABLE</span></article>
              <article className="eagle-panel"><h3>Completion & outcomes</h3><p>Track course completion, assessment pass rates and credential eligibility without trusting client-reported results.</p><span className="eagle-panel-state">NEXT ANALYTICS LAYER</span></article>
            </div>
          </section>

          <section className="eagle-section" id="testers" aria-labelledby="testers-heading">
            <div className="eagle-section-heading">
              <div><p className="eyebrow">EARLY ACCESS</p><h2 id="testers-heading">Beta tester recognition</h2></div>
              <span>{metrics?.betaTesters.length ?? 0} registered</span>
            </div>
            <div className="eagle-panel eagle-tester-panel">
              {!metrics || metrics.betaTesters.length === 0 ? (
                <p>No beta testers have been registered yet.</p>
              ) : (
                <div className="eagle-tester-list">
                  {metrics.betaTesters.map((tester) => (
                    <article className="eagle-tester-row" key={tester.id}>
                      <div>
                        <strong>{tester.fullName}</strong>
                        <span>Added {new Date(tester.createdAt).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" })}</span>
                      </div>
                      <div className="eagle-tester-status">
                        <span>{tester.testerStatus === "active" ? "Active tester" : tester.testerStatus}</span>
                        <b>{tester.certificateStatus === "pending_launch" ? "Certificate after launch" : tester.certificateStatus.replaceAll("_", " ")}</b>
                      </div>
                    </article>
                  ))}
                </div>
              )}
            </div>
          </section>

          <section className="eagle-section" id="operations" aria-labelledby="operations-heading">
            <div className="eagle-section-heading"><div><p className="eyebrow">OPERATIONS</p><h2 id="operations-heading">Support & moderation</h2></div></div>
            <div className="eagle-panel-grid">
              <article className="eagle-panel"><h3>Support queue</h3><p>Support requests and complaints will appear here when the support workflow is connected.</p><span className="eagle-panel-state">NOT CONFIGURED</span></article>
              <article className="eagle-panel"><h3>Reports & moderation</h3><p>Review learner reports, flagged content and moderation decisions with an auditable history.</p><span className="eagle-panel-state">NOT CONFIGURED</span></article>
            </div>
          </section>

          <section className="eagle-section" id="platform" aria-labelledby="platform-heading">
            <div className="eagle-section-heading"><div><p className="eyebrow">RELIABILITY</p><h2 id="platform-heading">Platform health</h2></div></div>
            <div className="eagle-panel"><h3>Database configuration</h3><p>{overview.configured ? metrics ? "The protected database overview queries completed successfully." : "The database responded, but one or more overview queries need investigation." : "The service key is not configured. Public application routes remain separate from this owner-only data path."}</p><span className="eagle-panel-state">{overview.configured && metrics ? "DATABASE CHECK PASSED" : "CONFIGURATION REQUIRED"}</span></div>
          </section>

          <section className="eagle-section" id="revenue" aria-labelledby="revenue-heading">
            <div className="eagle-section-heading"><div><p className="eyebrow">FINANCIALS</p><h2 id="revenue-heading">Revenue & payments</h2></div></div>
            <div className="eagle-panel eagle-panel-disabled"><h3>Payment reporting</h3><p>Revenue, payment success, refunds and outstanding transactions remain disabled until a payment provider and credentials are configured.</p><span className="eagle-panel-state">UNCONFIGURED · NO REVENUE ESTIMATES</span></div>
          </section>

          <footer className="eagle-footer"><Link href="/">Open public site</Link><span>Private owner workspace · Kaizora AI Academy</span></footer>
        </div>
      </div>
    </main>
  );
}
