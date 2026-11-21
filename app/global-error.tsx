"use client";

import Link from "next/link";
import "./globals.css";
import "./dark-theme.css";

export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="en">
      <body>
        <main className="service-unavailable-page">
          <header className="not-found-header">
            <Link className="brand" href="/" aria-label="Kaizora AI Academy home">
              <span className="brand-mark" aria-hidden="true">K</span>
              <span>kaizora<span className="brand-light"> AI Academy</span></span>
            </Link>
          </header>
          <section className="service-unavailable-content" aria-labelledby="global-error-title">
            <p className="eyebrow">KAIZORA AI ACADEMY · TEMPORARY INTERRUPTION</p>
            <p className="service-unavailable-code" aria-hidden="true">500</p>
            <h1 id="global-error-title">We are restoring your learning space.</h1>
            <p>A technical issue interrupted this page. Please try again. If the problem continues, return to the course catalogue later.</p>
            <div className="service-unavailable-actions">
              <button className="button button-primary" type="button" onClick={() => reset()}>Try again</button>
              <Link className="text-link" href="/">Back to home</Link>
            </div>
          </section>
          <footer className="site-footer"><span>© {new Date().getFullYear()} Kaizora AI Academy</span></footer>
        </main>
      </body>
    </html>
  );
}
