import "server-only";

import { createClient } from "@/lib/supabase/server";

const RESOURCE_BUCKET = "kaizora-learning-resources";
const SIGNED_URL_SECONDS = 300;

export type LessonContent = {
  simple_explanation?: string;
  step_by_step_guide?: string[];
  key_terms?: { term: string; meaning: string }[];
  practical_exercise?: { task_title?: string; instructions?: string; expected_outcome?: string };
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
      .eq("user_id", auth.user.id)
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
        .eq("user_id", auth.user.id)
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


type CourseAssessmentType = "module_quiz" | "final_assessment";

export async function getCourseAssessmentForLearner(
  courseSlug: string,
  assessmentType: CourseAssessmentType,
  moduleNumber?: number,
) {
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) {
    return { user: null, enrolled: false, course: null, module: null, assessment: null, assessmentAttempts: [], lockedReason: null };
  }

  const { data: course, error: courseError } = await supabase
    .from("courses")
    .select("id, slug, title")
    .eq("slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();

  if (courseError || !course) {
    return { user: auth.user, enrolled: false, course: null, module: null, assessment: null, assessmentAttempts: [], lockedReason: null };
  }

  const { data: enrollment, error: enrollmentError } = await supabase
    .from("course_enrollments")
    .select("id")
    .eq("user_id", auth.user.id)
    .eq("course_id", course.id)
    .eq("status", "active")
    .maybeSingle();

  if (enrollmentError) throw new Error("Your course access could not be verified. Please refresh.");
  if (!enrollment) {
    return { user: auth.user, enrolled: false, course, module: null, assessment: null, assessmentAttempts: [], lockedReason: null };
  }

  let courseModule: { id: string; module_number: number; title: string } | null = null;
  let assessmentQuery = supabase
    .from("assessments")
    .select("id, title, instructions, passing_score_percentage, max_attempts, assessment_questions(id, question_number, prompt, options)")
    .eq("course_id", course.id)
    .eq("assessment_type", assessmentType)
    .eq("status", "published");

  if (assessmentType === "module_quiz") {
    if (!Number.isInteger(moduleNumber) || (moduleNumber ?? 0) < 1) {
      return { user: auth.user, enrolled: true, course, module: courseModule, assessment: null, assessmentAttempts: [], lockedReason: null };
    }

    const { data: moduleRow, error: moduleError } = await supabase
      .from("course_modules")
      .select("id, module_number, title")
      .eq("course_id", course.id)
      .eq("module_number", moduleNumber!)
      .eq("status", "published")
      .maybeSingle();

    if (moduleError || !moduleRow) {
      return { user: auth.user, enrolled: true, course, module: null, assessment: null, assessmentAttempts: [], lockedReason: null };
    }

    courseModule = moduleRow;
    assessmentQuery = assessmentQuery.eq("module_id", courseModule.id);
  } else {
    assessmentQuery = assessmentQuery.is("module_id", null);
  }

  const { data: assessmentData, error: assessmentError } = await assessmentQuery.maybeSingle();
  if (assessmentError) throw new Error("The assessment could not be loaded. Please refresh.");
  if (!assessmentData) {
    return { user: auth.user, enrolled: true, course, module: courseModule, assessment: null, assessmentAttempts: [], lockedReason: null };
  }

  let lockedReason: string | null = null;
  if (assessmentType === "module_quiz" && courseModule) {
    const { data: lessons, error: lessonsError } = await supabase
      .from("lessons")
      .select("id")
      .eq("module_id", courseModule.id)
      .eq("status", "published");

    if (lessonsError) throw new Error("Module progress could not be checked.");
    const lessonIds = (lessons ?? []).map((lesson) => lesson.id);
    const { data: progress, error: progressError } = lessonIds.length
      ? await supabase.from("lesson_progress").select("lesson_id").eq("user_id", auth.user.id).in("lesson_id", lessonIds).not("completed_at", "is", null)
      : { data: [], error: null };

    if (progressError) throw new Error("Module progress could not be checked.");
    if (lessonIds.length === 0 || (progress ?? []).length < lessonIds.length) {
      lockedReason = "Complete every published lesson in this module before taking its quiz.";
    }
  }

  if (assessmentType === "final_assessment") {
    const { data: modules, error: modulesError } = await supabase
      .from("course_modules")
      .select("id, lessons(id)")
      .eq("course_id", course.id)
      .eq("status", "published");

    if (modulesError) throw new Error("Course progress could not be checked.");
    const lessonIds = (modules ?? []).flatMap((item) => (item.lessons ?? []).map((lesson) => lesson.id));
    const { data: progress, error: progressError } = lessonIds.length
      ? await supabase.from("lesson_progress").select("lesson_id").eq("user_id", auth.user.id).in("lesson_id", lessonIds).not("completed_at", "is", null)
      : { data: [], error: null };

    if (progressError) throw new Error("Course progress could not be checked.");
    if (lessonIds.length === 0 || (progress ?? []).length < lessonIds.length) {
      lockedReason = "Complete every published lesson before taking the final assessment.";
    }

    const { data: moduleAssessments, error: moduleAssessmentError } = await supabase
      .from("assessments")
      .select("id")
      .eq("course_id", course.id)
      .eq("assessment_type", "module_quiz")
      .eq("status", "published")
      .eq("required_for_certificate", true);

    if (moduleAssessmentError) throw new Error("Module assessment status could not be checked.");
    const moduleAssessmentIds = (moduleAssessments ?? []).map((item) => item.id);
    if (moduleAssessmentIds.length > 0) {
      const { data: passedAttempts, error: attemptsError } = await supabase
        .from("assessment_attempts")
        .select("assessment_id")
        .eq("user_id", auth.user.id)
        .eq("passed", true)
        .in("assessment_id", moduleAssessmentIds);

      if (attemptsError) throw new Error("Module assessment status could not be checked.");
      const passedIds = new Set((passedAttempts ?? []).map((attempt) => attempt.assessment_id));
      if (moduleAssessmentIds.some((id) => !passedIds.has(id))) {
        lockedReason = "Pass every required module quiz before taking the final assessment.";
      }
    }
  }

  const { data: attemptRows, error: attemptError } = await supabase
    .from("assessment_attempts")
    .select("attempt_number, score_percentage, passed, submitted_at")
    .eq("assessment_id", assessmentData.id)
    .eq("user_id", auth.user.id)
    .order("attempt_number", { ascending: false });

  if (attemptError) throw new Error("Your assessment attempts could not be loaded.");

  const assessment = {
    ...assessmentData,
    assessment_questions: [...(assessmentData.assessment_questions ?? [])].sort(
      (a, b) => a.question_number - b.question_number,
    ),
  };

  return {
    user: auth.user,
    enrolled: true,
    course,
    module,
    assessment,
    assessmentAttempts: attemptRows ?? [],
    lockedReason,
  };
}
