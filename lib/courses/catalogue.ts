import "server-only";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { getSupabasePublicEnv } from "@/lib/supabase/env";

export type PublishedCourseCategory = {
  id: string;
  slug: string;
  name: string;
  description: string;
  display_order: number;
};

export type PublishedCourse = {
  id: string;
  category_id: string;
  slug: string;
  title: string;
  summary: string;
  description: string;
  difficulty: "beginner" | "intermediate" | "advanced" | "all_levels";
  estimated_minutes: number;
  display_order: number;
  published_at: string | null;
  course_categories: PublishedCourseCategory[] | null;
};

function createPublicCatalogueClient() {
  const { url, key } = getSupabasePublicEnv();
  return createSupabaseClient(url, key, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

export async function getPublishedCatalogue() {
  const supabase = createPublicCatalogueClient();
  const [categoriesResult, coursesResult] = await Promise.all([
    supabase
      .from("course_categories")
      .select("id, slug, name, description, display_order")
      .order("display_order", { ascending: true })
      .order("name", { ascending: true }),
    supabase
      .from("courses")
      .select(
        "id, category_id, slug, title, summary, description, difficulty, estimated_minutes, display_order, published_at, course_categories(id, slug, name, description, display_order)",
      )
      .eq("status", "published")
      .order("display_order", { ascending: true })
      .order("title", { ascending: true }),
  ]);

  if (categoriesResult.error || coursesResult.error) {
    throw new Error("The course catalogue is temporarily unavailable.");
  }

  return {
    categories: (categoriesResult.data ?? []) as PublishedCourseCategory[],
    courses: (coursesResult.data ?? []) as PublishedCourse[],
  };
}

export async function getPublishedCourseBySlug(slug: string) {
  const supabase = createPublicCatalogueClient();
  const { data, error } = await supabase
    .from("courses")
    .select(
      "id, category_id, slug, title, summary, description, difficulty, estimated_minutes, display_order, published_at, course_categories(id, slug, name, description, display_order)",
    )
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (error) {
    throw new Error("The course could not be loaded.");
  }

  return (data as PublishedCourse | null) ?? null;
}

export type PublicCoursePreviewRow = {
  course_title: string;
  course_summary: string;
  course_description: string;
  difficulty: PublishedCourse["difficulty"];
  estimated_minutes: number;
  module_number: number;
  module_title: string;
  lesson_number: string | null;
  lesson_title: string | null;
};

export async function getPublicCoursePreview(slug: string) {
  const supabase = createPublicCatalogueClient();
  const { data, error } = await supabase.rpc("get_public_course_preview", {
    p_course_slug: slug,
  });

  if (error) {
    throw new Error("The course preview is temporarily unavailable.");
  }

  return (data ?? []) as PublicCoursePreviewRow[];
}
