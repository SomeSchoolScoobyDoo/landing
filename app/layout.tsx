import type { Metadata } from "next";
import { ThemeToggle } from "@/components/theme-toggle";
import "./globals.css";
import "./dark-theme.css";
import "./marketing.css";
import "./dark-mode-overrides.css";
import "./preview/preview.css";
import "./preview/dark-preview.css";
const siteUrl = "https://www.kaizoraaiacademy.com";
export const metadata: Metadata = { metadataBase: new URL(siteUrl), title: "Kaizora AI Academy | Practical Technology Learning", description: "Practical courses in AI, automation, software and cybersecurity. Build useful skills through independent, hands-on learning with Kaizora.", robots: { index: true, follow: true }, openGraph: { title: "Kaizora AI Academy | Practical Technology Learning", description: "Practical learning for individuals, institutes and organisations.", url: siteUrl, siteName: "Kaizora AI Academy", type: "website", locale: "en_NG" }, twitter: { card: "summary", title: "Kaizora AI Academy | Practical Technology Learning", description: "Practical learning for individuals, institutes and organisations." } };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en" suppressHydrationWarning><body>{children}<ThemeToggle /></body></html>; }
