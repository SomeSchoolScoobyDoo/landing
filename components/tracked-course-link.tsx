"use client";

import Link from "next/link";
import posthog from "posthog-js";
import type { ComponentProps, ReactNode } from "react";

type Props = {
  href: ComponentProps<typeof Link>["href"];
  courseSlug: string;
  courseTitle: string;
  sourceComponent: string;
  placement?: string;
  className?: string;
  children: ReactNode;
};

export function TrackedCourseLink({
  href,
  courseSlug,
  courseTitle,
  sourceComponent,
  placement,
  className,
  children,
}: Props) {
  function trackClick() {
    if (!posthog.__loaded) return;

    const destinationPath = typeof href === "string" ? href : href.pathname;
    posthog.capture("course_clicked", {
      course_slug: courseSlug,
      course_title: courseTitle,
      source_page: window.location.pathname,
      source_component: sourceComponent,
      placement: placement ?? null,
      destination_path: destinationPath,
      source_referrer: document.referrer || null,
    });
  }

  return (
    <Link href={href} className={className} onClick={trackClick} data-attr="course-link">
      {children}
    </Link>
  );
}
