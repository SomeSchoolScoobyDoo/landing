"use client";

import Link from "next/link";

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const connectionMissing = error.message.includes(
    "Supabase public environment variables are missing",
  );

  return (
    <main className="service-unavailable-page">
      <header className="not-found-header">
        <Link className="brand" href="/" aria-label="Kaizora AI Academy home">
          <span className="brand-mark" aria-hidden="true">K</span>
          <span>kaizora<span className="brand-light"> AI Academy</span></span>
        </Link>
      </header>
      <section className="service-unavailable-content" aria-labelledby="error-title">
        <p className="eyebrow">KAIZORA AI ACADEMY · {connectionMissing ? "SETUP IN PROGRESS" : "TEMPORARY INTERRUPTION"}</p>
        <p className="service-unavailable-code" aria-hidden="true">{connectionMissing ? "SETUP" : "OOPS"}</p>
        <h1 id="error-title">{connectionMissing ? "Your learning space is being connected." : "We hit a temporary problem."}</h1>
        <p>{connectionMissing
          ? "The learning platform is waiting for its secure database connection. Please check back shortly."
          : "This part of the academy did not load correctly. Your saved learning progress is not intentionally changed by this error. Please try again in a moment."}</p>
        {error.digest ? <p className="error-reference">Reference: {error.digest}</p> : null}
        <div className="service-unavailable-actions">
          <button className="button button-primary" type="button" onClick={() => reset()}>Try again</button>
          <Link className="text-link" href="/courses">Explore courses <span aria-hidden="true">→</span></Link>
          <Link className="text-link" href="/">Back to home</Link>
        </div>
      </section>
      <footer className="site-footer"><span>© {new Date().getFullYear()} Kaizora AI Academy</span></footer>
    </main>
  );
}
