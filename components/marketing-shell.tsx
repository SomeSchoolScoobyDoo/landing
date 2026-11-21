import Link from "next/link";
import { Brand } from "@/components/brand";

const nav = [
  ["About", "/about"], ["Courses", "/courses"], ["Learners", "/learners"],
  ["Institutes", "/institutes"], ["Organisations", "/organisations"],
];

export function MarketingShell({ children }: { children: React.ReactNode }) {
  return <div className="marketing-site">
    <header className="marketing-header"><Brand /><nav aria-label="Main navigation">{nav.map(([label, href]) => <Link key={href} href={href}>{label}</Link>)}</nav><Link className="marketing-cta" href="/courses">Explore courses <span>↗</span></Link></header>
    {children}
    <footer className="marketing-footer"><div><Brand /><p>Practical learning. Real work. Skills you can put to use.</p></div><nav aria-label="Footer navigation">{nav.map(([label, href]) => <Link key={href} href={href}>{label}</Link>)}</nav><small>© {new Date().getFullYear()} Kaizora AI Academy</small></footer>
  </div>;
}

export function AudiencePage({ eyebrow, title, accent, description, bullets, cta, href }: {
  eyebrow: string; title: string; accent: string; description: string; bullets: string[]; cta: string; href: string;
}) {
  return <MarketingShell><main className="audience-page"><section className="audience-hero"><p className="marketing-eyebrow">{eyebrow}</p><h1>{title} <em>{accent}</em></h1><p>{description}</p><Link className="marketing-button" href={href}>{cta} <span>→</span></Link></section><section className="audience-grid">{bullets.map((item, i) => <article key={item}><span>0{i + 1}</span><p>{item}</p></article>)}</section><section className="audience-bottom"><p className="marketing-eyebrow">THE KAIZORA APPROACH</p><h2>Learning should lead to <em>something you can do.</em></h2><p>Explore practical courses, build at your pace and connect learning to real work.</p><Link href="/courses" className="marketing-text-link">Browse the course catalogue →</Link></section></main></MarketingShell>;
}
