import type { MetadataRoute } from "next";

const siteUrl = "https://www.kaizoraaiacademy.com";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: siteUrl, changeFrequency: "weekly", priority: 1 },
    { url: `${siteUrl}/courses`, changeFrequency: "daily", priority: 0.9 },
  ];
}
