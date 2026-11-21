"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function markLessonCompleteAction(data: FormData) {
  const lessonId = String(data.get("lessonId") ?? "");
  const courseSlug = String(data.get("courseSlug") ?? "");

  if (!UUID_PATTERN.test(lessonId) || !/^[a-z0-9-]{1,120}$/.test(courseSlug)) {
    throw new Error("Invalid lesson progress request.");
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  // Verify that the supplied lesson ID belongs to this published course.
  const { data: lesson, error: lessonError } = await supabase
    .from("lessons")
    .select("id, course_modules!inner(courses!inner(slug))")
    .eq("id", lessonId)
    .eq("course_modules.courses.slug", courseSlug)
    .maybeSingle();

  if (lessonError || !lesson) {
    throw new Error("This lesson could not be verified. Refresh the page and try again.");
  }

  const { error } = await supabase.from("lesson_progress").upsert(
    { user_id: auth.user.id, lesson_id: lesson.id, completed_at: new Date().toISOString() },
    { onConflict: "user_id,lesson_id" },
  );

  if (error) throw new Error("Your lesson progress could not be saved. Please try again.");

  revalidatePath("/learn/" + courseSlug + "/" + lessonId);
}


export async function submitAssessmentAction(data: FormData) {
  const assessmentId = String(data.get("assessmentId") ?? "");
  const lessonId = String(data.get("lessonId") ?? "");
  const courseSlug = String(data.get("courseSlug") ?? "");
  const rawAnswers = String(data.get("answers") ?? "");

  if (
    !UUID_PATTERN.test(assessmentId) ||
    !UUID_PATTERN.test(lessonId) ||
    !/^[a-z0-9-]{1,120}$/.test(courseSlug) ||
    rawAnswers.length > 50000
  ) {
    throw new Error("Invalid assessment submission.");
  }

  let answers: unknown;
  try {
    answers = JSON.parse(rawAnswers);
  } catch {
    throw new Error("Your answers could not be read. Please try again.");
  }

  if (
    !Array.isArray(answers) ||
    answers.length < 1 ||
    answers.length > 100 ||
    answers.some((answer) =>
      !answer ||
      typeof answer !== "object" ||
      !UUID_PATTERN.test(String(answer.question_id ?? "")) ||
      typeof answer.selected_option_key !== "string" ||
      answer.selected_option_key.length < 1 ||
      answer.selected_option_key.length > 20
    )
  ) {
    throw new Error("Please answer every question using a valid option.");
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: lesson, error: lessonError } = await supabase
    .from("lessons")
    .select("id, course_modules!inner(courses!inner(slug))")
    .eq("id", lessonId)
    .eq("course_modules.courses.slug", courseSlug)
    .maybeSingle();

  if (lessonError || !lesson) {
    throw new Error("This lesson could not be verified.");
  }

  const { error } = await supabase.rpc("submit_assessment", {
    p_assessment_id: assessmentId,
    p_answers: answers,
  });

  if (error) {
    if (error.message.includes("Maximum assessment attempts reached")) {
      throw new Error("You have used all available attempts for this quiz.");
    }
    throw new Error("Your quiz could not be submitted. Check your answers and try again.");
  }

  revalidatePath("/learn/" + courseSlug + "/" + lessonId);
  redirect("/learn/" + courseSlug + "/" + lessonId + "?quiz=submitted");
}


export async function enrollInCourseAction(data: FormData) {
  const courseSlug = String(data.get("courseSlug") ?? "");
  if (!/^[a-z0-9-]{1,120}$/.test(courseSlug)) {
    throw new Error("Invalid course enrolment request.");
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: course, error: courseError } = await supabase
    .from("courses")
    .select("id, slug")
    .eq("slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();

  if (courseError || !course) {
    throw new Error("This course is not currently available for enrolment.");
  }

  const { error } = await supabase.rpc("manage_course_enrollment", {
    p_course_slug: courseSlug,
    p_action: "enrol",
  });

  if (error) throw new Error("Your course enrolment could not be saved. Please try again.");

  revalidatePath("/dashboard");
  redirect("/dashboard?enrolment=enrolled");
}

export async function withdrawFromCourseAction(data: FormData) {
  const courseSlug = String(data.get("courseSlug") ?? "");
  if (!/^[a-z0-9-]{1,120}$/.test(courseSlug)) {
    throw new Error("Invalid course withdrawal request.");
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { error } = await supabase.rpc("manage_course_enrollment", {
    p_course_slug: courseSlug,
    p_action: "withdraw",
  });

  if (error) throw new Error("Your enrolment could not be withdrawn. Please refresh and try again.");

  revalidatePath("/dashboard");
  revalidatePath("/courses/" + courseSlug);
  redirect("/dashboard?enrolment=withdrawn");
}
