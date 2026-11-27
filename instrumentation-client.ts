import posthog from "posthog-js";

const projectToken = process.env.NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN;
const host = process.env.NEXT_PUBLIC_POSTHOG_HOST;

if (projectToken && host) {
  posthog.init(projectToken, {
    api_host: host,
    defaults: "2026-08-30",
    capture_pageview: true,
    capture_pageleave: true,
    autocapture: false,
    disable_session_recording: true,
  });
} else if (process.env.NODE_ENV !== "production") {
  console.error(
    "NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN and NEXT_PUBLIC_POSTHOG_HOST are required by PostHog; course analytics events will be missed until both are configured.",
  );
}
