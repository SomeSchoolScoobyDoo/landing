const page = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>Temporarily unavailable | Kaizora AI Academy</title>
<style>
:root{color-scheme:light dark;--navy:#112E5D;--orange:#F97316;--ink:#112E5D;--muted:#52627A;--paper:#fff;--line:#e6ebf1}
*{box-sizing:border-box}body{margin:0;min-height:100vh;background:var(--paper);color:var(--ink);font-family:Arial,sans-serif;display:flex;flex-direction:column}
header,footer{padding:26px clamp(22px,6vw,92px)}header{display:flex;align-items:center;gap:12px;font-weight:800;letter-spacing:-.03em}header img{width:30px;height:36px}header span span{color:var(--orange)}
main{width:min(760px,calc(100% - 40px));margin:auto;padding:64px 0}.eyebrow{font-size:12px;font-weight:800;letter-spacing:.13em;color:var(--muted)}.code{margin:20px 0 10px;color:var(--orange);font-size:clamp(76px,16vw,144px);font-weight:900;line-height:.9;letter-spacing:-.08em}
h1{max-width:620px;margin:0 0 18px;font-size:clamp(32px,6vw,54px);line-height:1.08;letter-spacing:-.045em}main>p:not(.eyebrow):not(.code){max-width:560px;color:var(--muted);font-size:17px;line-height:1.75}
.actions{display:flex;flex-wrap:wrap;align-items:center;gap:18px;margin-top:30px}.button{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:0 20px;border-radius:7px;background:var(--navy);color:#fff;text-decoration:none;font-weight:700}.link{color:var(--navy);font-weight:700;text-decoration:none}footer{border-top:1px solid var(--line);color:var(--muted);font-size:13px}
@media(prefers-color-scheme:dark){:root{color-scheme:dark;--ink:#F1F5F9;--muted:#C2CBD6;--paper:#0B0F14;--line:#2B3745}.link{color:var(--orange)}.button{background:var(--orange);color:var(--navy)}}
@media(max-width:600px){main{padding:48px 0}.actions{align-items:stretch;flex-direction:column}.actions a{width:100%}}
</style>
</head>
<body>
<header><img src="/kaizora-logo.svg" alt=""><span>kaizora <span>AI Academy</span></span></header>
<main>
<p class="eyebrow">KAIZORA AI ACADEMY · SERVICE STATUS</p>
<p class="code" aria-hidden="true">503</p>
<h1>We will be back shortly.</h1>
<p>The academy is temporarily unavailable while we work on the service. Your learning space has not been abandoned. Please give us a little time and try again.</p>
<div class="actions"><a class="button" href="/">Return to home</a><a class="link" href="/courses">View course catalogue</a></div>
</main>
<footer>© ${new Date().getFullYear()} Kaizora AI Academy</footer>
</body>
</html>`;

export function GET() {
  return new Response(page, {
    status: 503,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store, max-age=0",
      "Retry-After": "300",
    },
  });
}
