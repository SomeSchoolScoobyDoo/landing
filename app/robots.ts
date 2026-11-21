import type { MetadataRoute } from "next";

const siteUrl = "https://www.kaizoraaiacademy.com";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: ["/", "/courses"],
      disallow: ["/dashboard", "/learn/", "/login", "/signup", "/forgot-password", "/auth/"],
    },
    sitemap: `${siteUrl}/sitemap.xml`,
    host: siteUrl,
  };
}
