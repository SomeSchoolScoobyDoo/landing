import Image from "next/image";
import Link from "next/link";

export default function NotFound() {
  return (
    <main className="not-found-page">
      <header className="not-found-header">
        <Link className="brand" href="/" aria-label="Kaizora AI Academy home">
          <Image src="/kaizora-logo.svg" alt="" width={30} height={36} priority />
          <span>kaizora<span className="brand-light"> AI Academy</span></span>
        </Link>
      </header>
      <section className="not-found-content" aria-labelledby="not-found-title">
        <p className="eyebrow"><span className="eyebrow-dot" /> A WRONG TURN</p>
        <p className="not-found-code" aria-hidden="true">404</p>
        <h1 id="not-found-title">This page took a different route.</h1>
        <p className="not-found-description">
          The address may be out of date, or the page may have moved. Your next
          lesson is still waiting. Find your way back to the right place.
        </p>
        <div className="not-found-actions">
          <Link className="button button-primary" href="/">Back to home <span>→</span></Link>
          <Link className="not-found-secondary" href="/courses">Explore courses</Link>
        </div>
        <p className="not-found-footnote">KAIZORA AI ACADEMY · PRACTICAL LEARNING, SKILLS IN USE</p>
      </section>
    </main>
  );
}
