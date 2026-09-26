# Kaizora AI Academy Website

Production-ready static landing page for Kaizora AI Academy.

## Files
- `index.html` — semantic page content, SEO metadata and structured data.
- `styles.css` — all site styling, separated from HTML.
- `script.js` — mobile navigation and progressive-enhancement animations.
- `assets/kaizora-logo.svg` — supplied Kaizora logo used as the primary brand mark.
- `assets/kaizora-logo.png` — supplied PNG fallback/reference.

## Important rendering choice
The website text is **not hidden by CSS** while waiting for JavaScript. The page remains readable if JavaScript fails or is disabled. Animations are progressive enhancement only.

## SEO
The page includes a descriptive title, meta description, canonical URL, Open Graph/Twitter metadata, Course structured data, Organization structured data, `robots.txt` and `sitemap.xml`. Replace the canonical/domain values if the final production domain differs from `https://www.kaizoraaiacademy.com/`.

## Before deployment
1. Confirm the production domain.
2. Replace the logo-only social preview image with a dedicated, correctly sized preview image when available.
3. Verify all social profile URLs.
4. Verify the application form URL.
