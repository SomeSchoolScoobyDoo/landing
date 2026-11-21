import type { MetadataRoute } from "next";
const siteUrl = "https://www.kaizoraaiacademy.com";
export default function robots(): MetadataRoute.Robots { return { rules: [{ userAgent: "*", allow: ["/", "/about", "/courses", "/learners", "/institutes", "/organisations"], disallow: ["/dashboard", "/learn/", "/login", "/signup", "/forgot-password", "/auth/", "/preview/"] }], sitemap: `${siteUrl}/sitemap.xml`, host: siteUrl }; }
