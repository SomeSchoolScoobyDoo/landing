# Kaizora AI Academy

Kaizora's public-facing website and the starting point for the wider learning-platform project.

## Current website
- `index.html` — responsive public landing page, course catalogue, individual learning overview, institutional pathways, FAQ and SEO metadata.
- `styles.css` — site styling, including the course catalogue and institutional cards.
- `script.js` — accessible mobile navigation and progressive-enhancement animations.
- `assets/kaizora-logo.svg` — supplied Kaizora brand mark.
- `assets/kaizora-logo.png` — supplied PNG logo asset.

## Positioning represented on the public site
- Foundational learning is free for individual learners.
- Professional standalone courses are presented separately.
- AI-Powered Content Creation & Video Editing and AI Workflow Automation show a ₦6,000 certificate fee.
- Schools and organizations are invited to enquire about institutional training, learner groups, reporting and tailored programmes.
- The existing Kaizora logo, navy and orange/gold brand palette, canonical domain and Google site-verification token are preserved.

## Important implementation boundary
This repository currently contains a static marketing website. The landing page describes the intended learning experience, but student authentication, lesson delivery, quizzes, randomized retakes, payment processing, certificate issuance, school/corporate portals, administrator tools, moderation workflows and account controls are **not implemented by this static site yet**. Those require a separate application architecture and backend, which should be designed and built as subsequent phases rather than represented as already-working features.

## Rendering and accessibility
- Main page content is available without JavaScript.
- Mobile navigation uses a real button with `aria-expanded`.
- Reduced-motion preferences are respected by the existing enhancement script.
- Supplied logo assets are retained.

## SEO and deployment checks
The site retains canonical metadata for `https://www.kaizoraaiacademy.com/`, Open Graph/Twitter metadata, Organization structured data, `robots.txt`, `sitemap.xml` and the existing Google verification token. Before deployment, verify the production domain, social preview image, contact details and social profile URLs.
