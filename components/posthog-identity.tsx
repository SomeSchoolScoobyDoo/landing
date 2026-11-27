"use client";

import { useEffect } from "react";
import { createBrowserClient } from "@supabase/ssr";
import posthog from "posthog-js";

export function PostHogIdentity() {
  useEffect(() => {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!url || !key || !posthog.__loaded) return;

    const supabase = createBrowserClient(url, key);
    let identifiedUserId: string | null = null;

    const identify = (userId: string) => {
      if (identifiedUserId === userId) return;
      identifiedUserId = userId;
      posthog.identify(userId);
    };

    void supabase.auth.getUser().then(({ data }) => {
      if (data.user?.id) identify(data.user.id);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (session?.user.id) {
        identify(session.user.id);
      } else if (event === "SIGNED_OUT") {
        identifiedUserId = null;
        posthog.reset();
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  return null;
}
