import "server-only";

import { createClient } from "@/lib/supabase/server";

const RESOURCE_BUCKET = "kaizora-learning-resources";
const SIGNED_URL_SECONDS = 300;

export type LessonContent = {
  simple_explanation?: string;
  step_by_step_guide?: string[];
  key_terms?: { term: string; meaning: string }[];
  practical_exercise?: { task_title?: string; instructions?: string; expected_outcome?: string };
  poem_stanzas?: string[];
  story_paragraphs?: string[];
};

type LessonNavigationItem = {
  id: string;
  lesson_number: string;
  title: string;
  estimated_minutes: number;
  module_number: number;
  module_title: string;
  module_order: number;
  lesson_order: number;
};

export async function getLessonForLearner(courseSlug: string, lessonId: string) {
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) {
    return { user: null, enrolled: false, lesson: null, completed: false, resources: [], previousLesson: null, nextLesson: null };
  }

  const { data: enrollment, error: enrollmentError } = await supabase
    .from("course_enrollments")
    .select("id, courses!inner(slug)")
    .eq("user_id", auth.user.id)
    .eq("status", "active")
    .eq("courses.slug", courseSlug)
    .maybeSingle();

  if (enrollmentError) {
    throw new Error("Your course access could not be verified. Please refresh.");
  }
  if (!enrollment) {
    return { user: auth.user, enrolled: false, lesson: null, completed: false, resources: [], previousLesson: null, nextLesson: null };
  }

  const { data: lesson, error } = await supabase
    .from("lessons")
    .select("id, lesson_number, title, estimated_minutes, youtube_url, content, course_modules!inner(id, module_number, title, courses!inner(id, slug, title))")
    .eq("id", lessonId)
    .eq("course_modules.courses.slug", courseSlug)
    .maybeSingle();

  if (error || !lesson) {
    return { user: auth.user, enrolled: true, lesson: null, completed: false, resources: [], previousLesson: null, nextLesson: null };
  }

  const courseId = (lesson.course_modules as unknown as { courses: { id: string } }).courses.id;
  const [progressResult, resourcesResult, modulesResult] = await Promise.all([
    supabase
      .from("lesson_progress")
      .select("completed_at")
      .eq("lesson_id", lesson.id)
      .maybeSingle(),
    supabase
      .from("lesson_resources")
      .select("id, title, description, storage_path")
      .eq("lesson_id", lesson.id)
      .order("display_order", { ascending: true }),
    supabase
      .from("course_modules")
      .select("module_number, title, display_order, lessons(id, lesson_number, title, estimated_minutes, display_order)")
      .eq("course_id", courseId)
      .eq("status", "published")
      .order("display_order", { ascending: true })
      .order("module_number", { ascending: true }),
  ]);

  const { data: assessmentData } = await supabase
    .from("assessments")
    .select("id, title, instructions, passing_score_percentage, max_attempts, assessment_questions(id, question_number, prompt, options)")
    .eq("lesson_id", lesson.id)
    .eq("assessment_type", "lesson_quiz")
    .eq("status", "published")
    .maybeSingle();

  const assessment = assessmentData
    ? {
        ...assessmentData,
        assessment_questions: [...(assessmentData.assessment_questions ?? [])].sort(
          (a, b) => a.question_number - b.question_number,
        ),
      }
    : null;

  const { data: attemptRows } = assessment
    ? await supabase
        .from("assessment_attempts")
        .select("attempt_number, score_percentage, passed, submitted_at")
        .eq("assessment_id", assessment.id)
        .order("attempt_number", { ascending: false })
    : { data: [] };

  const resources = await Promise.all((resourcesResult.data ?? []).map(async (resource) => {
    const { data } = await supabase.storage
      .from(RESOURCE_BUCKET)
      .createSignedUrl(resource.storage_path, SIGNED_URL_SECONDS);
    return data?.signedUrl
      ? { id: resource.id, title: resource.title, description: resource.description, url: data.signedUrl }
      : null;
  }));

  const navigation: LessonNavigationItem[] = (modulesResult.data ?? [])
    .flatMap((module) => (module.lessons ?? []).map((item) => ({
      id: item.id,
      lesson_number: item.lesson_number,
      title: item.title,
      estimated_minutes: item.estimated_minutes,
      module_number: module.module_number,
      module_title: module.title,
      module_order: module.display_order,
      lesson_order: item.display_order,
    })))
    .sort((a, b) =>
      a.module_order - b.module_order ||
      a.module_number - b.module_number ||
      a.lesson_order - b.lesson_order ||
      a.lesson_number.localeCompare(b.lesson_number, undefined, { numeric: true }),
    );

  const currentIndex = navigation.findIndex((item) => item.id === lesson.id);

  return {
    user: auth.user,
    enrolled: true,
    lesson: lesson as unknown as {
      id: string;
      lesson_number: string;
      title: string;
      estimated_minutes: number;
      youtube_url: string | null;
      content: LessonContent;
      course_modules: { id: string; module_number: number; title: string; courses: { id: string; slug: string; title: string } };
    },
    completed: Boolean(progressResult.data?.completed_at),
    assessment,
    assessmentAttempts: attemptRows ?? [],
    resources: resources.filter((resource): resource is NonNullable<typeof resource> => resource !== null),
    previousLesson: currentIndex > 0 ? navigation[currentIndex - 1] : null,
    nextLesson: currentIndex >= 0 && currentIndex < navigation.length - 1 ? navigation[currentIndex + 1] : null,
  };
}
