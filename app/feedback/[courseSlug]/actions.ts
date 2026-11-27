"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const SLUG_PATTERN = /^[a-z0-9-]{1,120}$/;

export async function submitCourseFeedbackAction(data: FormData) {
  const courseSlug = String(data.get("courseSlug") ?? "");
  const ratings = {
    overall_rating: Number(data.get("overall_rating")),
    platform_experience_rating: Number(data.get("platform_experience_rating")),
    content_clarity: Number(data.get("content_clarity")),
    learning_pace: Number(data.get("learning_pace")),
    practical_confidence: Number(data.get("practical_confidence")),
  };
  const mostUseful = String(data.get("most_useful") ?? "").trim();
  const improvementSuggestion = String(data.get("improvement_suggestion") ?? "").trim();
  const blockers = String(data.get("blockers") ?? "").trim();
  const recommendValue = String(data.get("would_recommend") ?? "");

  if (!SLUG_PATTERN.test(courseSlug)) throw new Error("Invalid course feedback request.");
  if (Object.values(ratings).some((rating) => !Number.isInteger(rating) || rating < 1 || rating > 5)) {
    throw new Error("Please provide all four ratings.");
  }
  if ([mostUseful, improvementSuggestion, blockers].some((value) => value.length > 2000)) {
    throw new Error("Your written feedback is too long. Please keep each response under 2,000 characters.");
  }
  if (!["yes", "no"].includes(recommendValue)) throw new Error("Please tell us whether you would recommend this course.");

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: course, error: courseError } = await supabase
    .from("courses")
    .select("id")
    .eq("slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();
  if (courseError || !course) throw new Error("This course could not be verified.");

  const { data: enrollment } = await supabase
    .from("course_enrollments")
    .select("id")
    .eq("user_id", auth.user.id)
    .eq("course_id", course.id)
    .eq("status", "active")
    .maybeSingle();
  if (!enrollment) throw new Error("You need an active enrolment to submit course feedback.");

  const { data: modules, error: modulesError } = await supabase
    .from("course_modules")
    .select("lessons!inner(id)")
    .eq("course_id", course.id)
    .eq("status", "published")
    .eq("lessons.status", "published");
  if (modulesError) throw new Error("Course completion could not be verified.");

  const lessonIds = (modules ?? []).flatMap((module) =>
    (module.lessons ?? []).map((lesson) => lesson.id),
  );
  if (lessonIds.length === 0) throw new Error("This course has no published lessons yet.");

  const { data: progress, error: progressError } = await supabase
    .from("lesson_progress")
    .select("lesson_id")
    .eq("user_id", auth.user.id)
    .not("completed_at", "is", null)
    .in("lesson_id", lessonIds);
  if (progressError || new Set((progress ?? []).map((item) => item.lesson_id)).size !== lessonIds.length) {
    throw new Error("Finish every published lesson before submitting course feedback.");
  }

  const { error } = await supabase.from("course_feedback").insert({
    user_id: auth.user.id,
    course_id: course.id,
    ...ratings,
    most_useful: mostUseful,
    improvement_suggestion: improvementSuggestion,
    blockers,
    would_recommend: recommendValue === "yes",
  });

  if (error) {
    if (error.code === "23505") redirect("/feedback/" + courseSlug + "?submitted=already");
    throw new Error("Your feedback could not be saved. Please try again.");
  }

  revalidatePath("/dashboard");
  revalidatePath("/feedback/" + courseSlug);
  redirect("/feedback/" + courseSlug + "?submitted=1");
}
