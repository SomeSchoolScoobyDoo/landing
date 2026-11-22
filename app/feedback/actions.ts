"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const validRating = (value: string) => /^[1-5]$/.test(value);

export async function submitCourseFeedbackAction(data: FormData) {
  const courseSlug = String(data.get("courseSlug") ?? "");
  const ratings = {
    overall_rating: String(data.get("overallRating") ?? ""),
    content_clarity: String(data.get("contentClarity") ?? ""),
    learning_pace: String(data.get("learningPace") ?? ""),
    practical_confidence: String(data.get("practicalConfidence") ?? ""),
    platform_experience_rating: String(data.get("platformExperience") ?? ""),
  };
  const mostUseful = String(data.get("mostUseful") ?? "").trim();
  const improvementSuggestion = String(data.get("improvementSuggestion") ?? "").trim();
  const blockers = String(data.get("blockers") ?? "").trim();
  const recommendation = String(data.get("wouldRecommend") ?? "");

  if (!/^[a-z0-9-]{1,120}$/.test(courseSlug)) throw new Error("Invalid course feedback request.");
  if (Object.values(ratings).some((rating) => !validRating(rating))) {
    throw new Error("Please select a rating for every rating question.");
  }
  if (!mostUseful || mostUseful.length > 2000 || improvementSuggestion.length > 2000 || blockers.length > 2000) {
    throw new Error("Please complete the feedback fields. Each response must be 2,000 characters or fewer.");
  }
  if (recommendation && recommendation !== "yes" && recommendation !== "no") {
    throw new Error("Choose a valid recommendation response.");
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: course, error: courseError } = await supabase
    .from("courses")
    .select("id")
    .eq("slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();
  if (courseError || !course) throw new Error("This course is not available for feedback.");

  const { data: enrollment, error: enrollmentError } = await supabase
    .from("course_enrollments")
    .select("id")
    .eq("user_id", auth.user.id)
    .eq("course_id", course.id)
    .eq("status", "active")
    .maybeSingle();
  if (enrollmentError || !enrollment) throw new Error("You must be actively enrolled to submit course feedback.");

  const { data: modules, error: modulesError } = await supabase
    .from("course_modules")
    .select("id, lessons!inner(id)")
    .eq("course_id", course.id)
    .eq("status", "published")
    .eq("lessons.status", "published");
  if (modulesError) throw new Error("Course completion could not be verified.");

  const lessonIds = (modules ?? []).flatMap((module) =>
    ((module.lessons ?? []) as unknown as { id: string }[]).map((lesson) => lesson.id)
  );
  if (lessonIds.length === 0) throw new Error("This course has no published lessons to review.");

  const { data: progress, error: progressError } = await supabase
    .from("lesson_progress")
    .select("lesson_id, completed_at")
    .eq("user_id", auth.user.id)
    .in("lesson_id", lessonIds);
  if (progressError) throw new Error("Course completion could not be verified.");

  const completedIds = new Set((progress ?? []).filter((item) => item.completed_at).map((item) => item.lesson_id));
  if (completedIds.size !== lessonIds.length) {
    throw new Error("Complete all published lessons before submitting feedback.");
  }

  const { error: insertError } = await supabase.from("course_feedback").insert({
    user_id: auth.user.id,
    course_id: course.id,
    overall_rating: Number(ratings.overall_rating),
    content_clarity: Number(ratings.content_clarity),
    learning_pace: Number(ratings.learning_pace),
    practical_confidence: Number(ratings.practical_confidence),
    platform_experience_rating: Number(ratings.platform_experience_rating),
    most_useful: mostUseful,
    improvement_suggestion: improvementSuggestion,
    blockers,
    would_recommend: recommendation === "" ? null : recommendation === "yes",
  });

  if (insertError) {
    if (insertError.code === "23505") redirect("/feedback/" + courseSlug + "?submitted=1");
    throw new Error("Your feedback could not be saved. Please refresh and try again.");
  }

  revalidatePath("/dashboard");
  redirect("/feedback/" + courseSlug + "?submitted=1");
}
