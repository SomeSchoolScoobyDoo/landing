import Link from "next/link";
import { Brand } from "@/components/brand";

const nav = [
  ["About", "/about"],
  ["Courses", "/courses"],
  ["Learners", "/learners"],
  ["Institutes", "/institutes"],
  ["Organisations", "/organisations"],
] as const;

export function MarketingShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="marketing-site">
      <header className="marketing-header">
        <Link href="/" aria-label="Kaizora AI Academy home"><Brand /></Link>
        <nav aria-label="Main navigation">
          {nav.map(([label, href]) => <Link key={href} href={href}>{label}</Link>)}
        </nav>
        <Link className="marketing-cta" href="/courses">Explore courses <span aria-hidden="true">↗</span></Link>
      </header>
      {children}
      <footer className="marketing-footer">
        <div className="marketing-footer-brand">
          <Link href="/" aria-label="Kaizora AI Academy home"><Brand /></Link>
          <p>Practical learning. Real work. Skills you can put to use.</p>
        </div>
        <nav aria-label="Footer navigation">
          {nav.map(([label, href]) => <Link key={href} href={href}>{label}</Link>)}
          <Link href="/login">Learner sign in</Link>
        </nav>
        <small>© {new Date().getFullYear()} Kaizora AI Academy</small>
      </footer>
    </div>
  );
}

type AudienceFeature = { number: string; title: string; description: string };
type AudienceStep = { title: string; description: string };

export function AudiencePage({ eyebrow, title, accent, description, features, steps, cta, href, note }: {
  eyebrow: string;
  title: string;
  accent: string;
  description: string;
  features: AudienceFeature[];
  steps: AudienceStep[];
  cta: string;
  href: string;
  note: string;
}) {
  return (
    <MarketingShell>
      <main className="audience-page">
        <section className="audience-hero">
          <p className="marketing-eyebrow">{eyebrow}</p>
          <h1>{title} <em>{accent}</em></h1>
          <p className="audience-intro">{description}</p>
          <div className="audience-actions">
            <Link className="marketing-button" href={href}>{cta} <span aria-hidden="true">→</span></Link>
            <Link className="marketing-text-link" href="/courses">Browse the course catalogue ↗</Link>
          </div>
          <p className="audience-note">{note}</p>
        </section>
        <section className="audience-features" aria-label="What this space offers">
          {features.map((feature) => (
            <article key={feature.number}>
              <span className="audience-number">{feature.number}</span>
              <h2>{feature.title}</h2>
              <p>{feature.description}</p>
            </article>
          ))}
        </section>
        <section className="audience-journey">
          <div className="audience-journey-heading">
            <p className="marketing-eyebrow">HOW IT FITS TOGETHER</p>
            <h2>A clearer route from <em>learning to doing.</em></h2>
          </div>
          <div className="audience-steps">
            {steps.map((step, index) => (
              <article key={step.title}>
                <span>0{index + 1}</span>
                <div><h3>{step.title}</h3><p>{step.description}</p></div>
              </article>
            ))}
          </div>
        </section>
        <section className="audience-bottom">
          <div><p className="marketing-eyebrow">YOUR NEXT STEP</p><h2>Start with a skill. <em>Build real capability.</em></h2><p>Explore the learning options available through Kaizora AI Academy.</p></div>
          <Link className="marketing-button" href={href}>{cta} <span aria-hidden="true">→</span></Link>
        </section>
      </main>
    </MarketingShell>
  );
}
