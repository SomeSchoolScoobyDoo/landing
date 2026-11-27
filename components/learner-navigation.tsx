import Link from "next/link";

export function LearnerNavigation() {
  return (
    <>
      <nav className="kaizora-learner-nav-desktop" aria-label="Learner navigation">
        <Link href="/dashboard">Dashboard</Link>
        <Link href="/courses">Explore courses</Link>
        <Link href="/certificates">Certificates</Link>
        <Link href="/badges">My badges</Link>
        <Link href="/settings">Settings</Link>
      </nav>
      <details className="kaizora-learner-nav-mobile">
        <summary aria-label="Open learner navigation menu">
          <span aria-hidden="true">☰</span>
        </summary>
        <nav aria-label="Learner navigation">
          <Link href="/dashboard">Dashboard</Link>
          <Link href="/courses">Explore courses</Link>
          <Link href="/certificates">Certificates</Link>
          <Link href="/badges">My badges</Link>
          <Link href="/settings">Settings</Link>
        </nav>
      </details>
      <style>{`
        .kaizora-learner-nav-desktop{display:flex;align-items:center;gap:22px}
        .kaizora-learner-nav-desktop a,.kaizora-learner-nav-mobile nav a{color:inherit;text-decoration:none;font-size:14px}
        .kaizora-learner-nav-mobile{display:none;position:relative}
        .kaizora-learner-nav-mobile summary{list-style:none;cursor:pointer;display:grid;place-items:center;width:42px;height:42px;border:1px solid currentColor;border-radius:8px;font-size:22px;line-height:1}
        .kaizora-learner-nav-mobile summary::-webkit-details-marker{display:none}
        .kaizora-learner-nav-mobile nav{position:absolute;right:0;top:calc(100% + 8px);z-index:30;min-width:190px;display:grid;gap:4px;padding:10px;background:var(--surface,#fff);color:var(--text,#14213d);border:1px solid rgba(20,33,61,.16);border-radius:10px;box-shadow:0 12px 28px rgba(0,0,0,.14)}
        .kaizora-learner-nav-mobile nav a{padding:10px 12px;border-radius:6px}
        .kaizora-learner-nav-mobile nav a:focus-visible,.kaizora-learner-nav-mobile nav a:hover{background:rgba(20,33,61,.08);outline:none}
        @media(max-width:760px){.kaizora-learner-nav-desktop{display:none}.kaizora-learner-nav-mobile{display:block}}
      `}</style>
    </>
  );
}
