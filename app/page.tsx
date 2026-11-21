import type { Metadata } from "next";
import Link from "next/link";
import { MarketingShell } from "@/components/marketing-shell";

export const metadata: Metadata = {
  title: "Kaizora AI Academy | Practical Technology Learning",
  description: "Practical technology education for independent learners, institutes and organisations. Learn, practise and build useful skills with Kaizora AI Academy.",
  alternates: { canonical: "/" },
};

const audiences = [
  { number: "01", label: "FOR INDIVIDUALS", title: "Learn independently.", copy: "Find a course that matches your goals, build at your own pace and keep your learning progress in one place.", href: "/learners", link: "Explore learning at Kaizora" },
  { number: "02", label: "FOR EDUCATION", title: "Support your learners.", copy: "A dedicated direction for institutes looking to organise digital learning and support structured programmes.", href: "/institutes", link: "Explore institute learning" },
  { number: "03", label: "FOR TEAMS", title: "Grow practical capability.", copy: "Bring technology learning into your organisation and give teams a clearer way to develop useful skills.", href: "/organisations", link: "Explore team learning" },
];

export default function HomePage() {
  return (
    <MarketingShell>
      <main className="home-page">
        <section className="marketing-hero">
          <div className="marketing-hero-copy">
            <p className="marketing-eyebrow">PRACTICAL LEARNING · REAL-WORLD SKILLS</p>
            <h1>Learn boldly.<br /><em>Build what comes next.</em></h1>
            <p>Kaizora AI Academy is a learning platform for curious minds, independent learners and teams. Develop practical skills in AI, automation, software, cybersecurity and emerging technology.</p>
            <div className="marketing-actions">
              <Link className="marketing-button" href="/courses">Explore courses <span aria-hidden="true">→</span></Link>
              <Link className="marketing-text-link" href="/about">Discover Kaizora ↗</Link>
            </div>
          </div>
          <aside className="marketing-hero-card">
            <p className="marketing-eyebrow">THE KAIZORA APPROACH</p>
            <strong>Understand it.<br />Use it. Test it.<br />Make it yours.</strong>
            <p>Learning should move beyond watching and remembering. Work through ideas, practise with purpose and understand the things you create.</p>
            <Link className="marketing-text-link" href="/learners">Explore the learner experience →</Link>
          </aside>
        </section>

        <section className="marketing-proof" aria-label="The Kaizora learning cycle">
          <div><span>01</span><strong>Learn</strong><p>Build understanding through structured material.</p></div>
          <div><span>02</span><strong>Practise</strong><p>Apply concepts with practical exercises and assessment.</p></div>
          <div><span>03</span><strong>Progress</strong><p>Keep track of your work and the next step in your learning.</p></div>
        </section>

        <section className="marketing-section">
          <div className="marketing-section-heading">
            <div><p className="marketing-eyebrow">ONE PLATFORM · DIFFERENT LEARNING NEEDS</p><h2>Built for people who learn, and the teams that help them grow.</h2></div>
            <p>Whether you are learning independently or supporting a group, Kaizora is designed to connect knowledge with practical application.</p>
          </div>
          <div className="marketing-card-grid">
            {audiences.map((item) => <article key={item.number}>
              <span>{item.number} · {item.label}</span><h3>{item.title}</h3><p>{item.copy}</p><Link className="marketing-text-link" href={item.href}>{item.link} →</Link>
            </article>)}
          </div>
        </section>

        <section className="marketing-method">
          <div><p className="marketing-eyebrow">MORE THAN CONTENT</p><h2>Knowledge matters. <em>Knowing what to do with it matters too.</em></h2></div>
          <div className="marketing-method-copy"><p>Kaizora puts practice, testing and explanation alongside learning. The goal is not to collect completed videos. It is to build skills you can use, question and keep improving.</p><Link className="marketing-text-link" href="/about">Read about our approach →</Link></div>
        </section>

        <section className="marketing-band">
          <div><p className="marketing-eyebrow">START WITH WHAT YOU NEED</p><h2>Build useful skills, one practical step at a time.</h2><p>Browse the catalogue and find a course that fits what you want to learn next.</p></div>
          <Link className="marketing-button" href="/courses">Browse courses <span aria-hidden="true">→</span></Link>
        </section>
      </main>
    </MarketingShell>
  );
}
