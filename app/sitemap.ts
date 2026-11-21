import type { MetadataRoute } from "next";
const siteUrl = "https://www.kaizoraaiacademy.com";
export default function sitemap(): MetadataRoute.Sitemap { return [
 {url:siteUrl,changeFrequency:"weekly",priority:1},
 {url:`${siteUrl}/about`,changeFrequency:"monthly",priority:0.7},
 {url:`${siteUrl}/courses`,changeFrequency:"daily",priority:0.9},
 {url:`${siteUrl}/learners`,changeFrequency:"monthly",priority:0.8},
 {url:`${siteUrl}/institutes`,changeFrequency:"monthly",priority:0.8},
 {url:`${siteUrl}/organisations`,changeFrequency:"monthly",priority:0.8}
]; }
