"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function markLessonCompleteAction(data: FormData) {
  const lessonId = String(data.get("lessonId") ?? "").trim();
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
  revalidatePath("/dashboard");
  revalidatePath("/badges");
  redirect("/learn/" + courseSlug + "/" + lessonId + "?completed=1");
}


export async function submitAssessmentAction(data: FormData) {
  const assessmentId = String(data.get("assessmentId") ?? "");
  const lessonId = String(data.get("lessonId") ?? "");
  const courseSlug = String(data.get("courseSlug") ?? "");
  const rawAnswers = String(data.get("answers") ?? "");

  if (!/^[a-z0-9-]{1,120}$/.test(courseSlug) || (lessonId.length > 0 && !UUID_PATTERN.test(lessonId))) {
    throw new Error("Invalid assessment submission.");
  }
  const returnTo = lessonId
    ? `/learn/${courseSlug}/${lessonId}`
    : `/courses/${courseSlug}`;
  const fail = (status: string): never => redirect(`${returnTo}?quiz=${status}`);

  if (!UUID_PATTERN.test(assessmentId) || rawAnswers.length > 50000) fail("invalid");

  let answers: unknown;
  try {
    answers = JSON.parse(rawAnswers);
  } catch {
    fail("invalid");
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
    fail("invalid");
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: assessment, error: assessmentError } = await supabase
    .from("assessments")
    .select("id, lesson_id, module_id, assessment_type, courses!inner(slug)")
    .eq("id", assessmentId)
    .eq("courses.slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();

  if (assessmentError || !assessment) {
    fail("unavailable");
  }

  if (lessonId) {
    if (assessment.assessment_type !== "lesson_quiz" || assessment.lesson_id !== lessonId) {
      fail("unavailable");
    }
  } else if (!["module_quiz", "final_assessment"].includes(assessment.assessment_type)) {
    fail("unavailable");
  }

  const { error } = await supabase.rpc("submit_assessment", {
    p_assessment_id: assessmentId,
    p_answers: answers,
  });

  if (error) {
    if (error.message.includes("Maximum assessment attempts reached")) {
      fail("attempts-exhausted");
    }
    fail("failed");
  }

  revalidatePath("/courses/" + courseSlug);
  revalidatePath("/dashboard");
  if (lessonId) {
    revalidatePath("/learn/" + courseSlug + "/" + lessonId);
    redirect("/learn/" + courseSlug + "/" + lessonId + "?quiz=submitted");
  }
  redirect("/courses/" + courseSlug + "?assessment=submitted");
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
