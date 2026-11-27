"use client";

import { useEffect } from "react";
import posthog from "posthog-js";

export function CourseDetailAnalytics({
  courseSlug,
  courseTitle,
  category,
}: {
  courseSlug: string;
  courseTitle: string;
  category: string;
}) {
  useEffect(() => {
    if (!posthog.__loaded) return;

    posthog.capture("course_preview_viewed", {
      course_slug: courseSlug,
      course_title: courseTitle,
      course_category: category,
      source_referrer: document.referrer || null,
    });
  }, [courseSlug, courseTitle, category]);

  return null;
}
