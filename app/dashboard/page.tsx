import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { signOutAction } from "@/app/auth/actions";
import { withdrawFromCourseAction } from "@/app/learn/actions";
import { LearnerCourseList } from "@/components/learner-course-list";
import { Brand } from "@/components/brand";

type Course = {
  id: string;
  slug: string;
  title: string;
  summary: string;
  estimated_minutes: number;
};
type Enrollment = { id: string; enrolled_at: string; courses: Course };
type Lesson = {
  id: string;
  lesson_number: string;
  title: string;
  estimated_minutes: number;
  display_order: number;
};
type Module = { id: string; course_id: string; display_order: number; module_number: number; lessons: Lesson[] };
type Progress = { lesson_id: string; completed_at: string | null; updated_at: string };
function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" });
}

type Attempt = {
  id: string;
  score_percentage: number;
  passed: boolean;
  submitted_at: string;
  assessments: { course_id: string; title: string; assessment_type: string };
};

export default async function DashboardPage({ searchParams }: { searchParams: Promise<{ enrolment?: string }> }) {
  const params = await searchParams;
  const enrolmentNotice = params.enrolment === "withdrawn" ? "You have unenrolled from the course. Your saved progress is kept, and you can enrol again at any time." : params.enrolment === "enrolled" ? "You are enrolled. Your course is ready in My courses below." : null;
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return (
      <main className="dashboard-page">
        <header className="site-header">
          <Brand />
          <nav aria-label="Learner navigation"><Link href="/courses">Explore courses</Link></nav>
        </header>
        <section className="learner-dashboard">
          <div className="dashboard-empty">
            <p className="eyebrow">YOUR LEARNING SPACE</p>
            <h2>Your learner space is being connected.</h2>
            <p>The course catalogue is available to explore. Sign-in, enrolment and saved progress will become available when this development preview is connected to its database.</p>
            <Link className="button button-primary" href="/courses">Explore courses <span>→</span></Link>
          </div>
        </section>
      </main>
    );
  }
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const [profileResult, enrollmentResult] = await Promise.all([
    supabase.from("profiles").select("full_name").eq("id", user.id).maybeSingle(),
    supabase
      .from("course_enrollments")
      .select("id, enrolled_at, courses!inner(id, slug, title, summary, estimated_minutes)")
      .eq("user_id", user.id)
      .eq("status", "active")
      .order("enrolled_at", { ascending: false }),
  ]);

  if (enrollmentResult.error) {
    throw new Error("Your learning dashboard is temporarily unavailable. Please refresh.");
  }

  const enrollments = (enrollmentResult.data ?? []) as unknown as Enrollment[];
  const courseIds = enrollments.map((item) => item.courses.id);
  const [moduleResult, progressResult, attemptResult] = courseIds.length > 0
    ? await Promise.all([
        supabase
          .from("course_modules")
          .select("id, course_id, module_number, display_order, lessons!inner(id, lesson_number, title, estimated_minutes, display_order)")
          .in("course_id", courseIds)
          .eq("status", "published")
          .eq("lessons.status", "published"),
        supabase
          .from("lesson_progress")
          .select("lesson_id, completed_at, updated_at")
          .eq("user_id", user.id)
          .order("updated_at", { ascending: false }),
        supabase
          .from("assessment_attempts")
          .select("id, score_percentage, passed, submitted_at, assessments!inner(course_id, title, assessment_type)")
          .eq("user_id", user.id)
          .in("assessments.course_id", courseIds)
          .order("submitted_at", { ascending: false })
          .limit(8),
      ])
    : [{ data: [], error: null }, { data: [], error: null }, { data: [], error: null }];

  if (moduleResult.error || progressResult.error || attemptResult.error) {
    throw new Error("Your learning activity could not be loaded. Please refresh.");
  }

  const modules = (moduleResult.data ?? []) as unknown as Module[];
  const progress = (progressResult.data ?? []) as unknown as Progress[];
  const attempts = (attemptResult.data ?? []) as unknown as Attempt[];
  const completedLessonIds = new Set(
    progress.filter((item) => item.completed_at).map((item) => item.lesson_id),
  );

  const courses = enrollments.map((enrollment) => {
    const courseModules = modules
      .filter((module) => module.course_id === enrollment.courses.id)
      .sort((a, b) => a.display_order - b.display_order || a.module_number - b.module_number);
    const lessons = courseModules
      .flatMap((module) => module.lessons ?? [])
      .sort((a, b) => a.display_order - b.display_order || a.lesson_number.localeCompare(b.lesson_number, undefined, { numeric: true }));
    const completed = lessons.filter((lesson) => completedLessonIds.has(lesson.id)).length;
    const nextLesson = lessons.find((lesson) => !completedLessonIds.has(lesson.id)) ?? lessons[lessons.length - 1] ?? null;
    return {
      ...enrollment,
      lessons,
      completed,
      total: lessons.length,
      percentage: lessons.length ? Math.round((completed / lessons.length) * 100) : 0,
      nextLesson,
    };
  });

  const totalLessons = courses.reduce((sum, course) => sum + course.total, 0);
  const totalCompleted = courses.reduce((sum, course) => sum + course.completed, 0);
  const overallProgress = totalLessons ? Math.round((totalCompleted / totalLessons) * 100) : 0;
  const name = profileResult.data?.full_name ||
    (typeof user.user_metadata.full_name === "string" ? user.user_metadata.full_name : "Learner");

  const visibleLessonIds = new Set(courses.flatMap((course) => course.lessons.map((lesson) => lesson.id)));
  const recentActivity = [
    ...progress.filter((item) => item.completed_at && visibleLessonIds.has(item.lesson_id)).map((item) => ({
      key: `lesson-${item.lesson_id}`,
      label: "Lesson completed",
      detail: courses.flatMap((course) => course.lessons).find((lesson) => lesson.id === item.lesson_id)?.title ?? "Learning activity",
      date: item.updated_at,
      score: null as number | null,
      passed: null as boolean | null,
    })),
    ...attempts.map((attempt) => ({
      key: `attempt-${attempt.id}`,
      label: attempt.assessments.assessment_type === "final_assessment" ? "Final assessment" : "Quiz submitted",
      detail: attempt.assessments.title,
      date: attempt.submitted_at,
      score: Number(attempt.score_percentage),
      passed: attempt.passed,
    })),
  ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()).slice(0, 6);

  return (
    <main className="dashboard-page">
      <header className="site-header">
        <Brand />
        <nav aria-label="Learner navigation"><Link href="/courses">Explore courses</Link></nav>
        <form action={signOutAction}><button className="signout-button" type="submit">Sign out</button></form>
      </header>

      <section className="learner-dashboard">
        {enrolmentNotice && <p className="dashboard-notice" role="status">{enrolmentNotice}</p>}
        <div className="learner-dashboard-heading">
          <div><p className="eyebrow">YOUR LEARNING SPACE</p><h1>Welcome back, <span>{name}</span>.</h1><p>Pick up where you left off. Every lesson completed moves you forward.</p></div>
          <Link className="button button-primary" href="/courses">Explore courses <span>→</span></Link>
        </div>

        <div className="learner-stat-grid">
          <article className="learner-stat"><span>Enrolled courses</span><strong>{courses.length}</strong><small>Your active learning paths</small></article>
          <article className="learner-stat"><span>Lessons completed</span><strong>{totalCompleted}<small className="stat-total"> / {totalLessons}</small></strong><small>Across your enrolled courses</small></article>
          <article className="learner-stat"><span>Overall progress</span><strong>{overallProgress}%</strong><div className="progress-track"><span style={{ width: `${overallProgress}%` }} /></div></article>
          <article className="learner-stat"><span>Recent results</span><strong>{attempts.length}</strong><small>Recent quiz and final results</small></article>
        </div>

        <section className="dashboard-section">
          <div className="dashboard-section-heading"><div><p className="eyebrow">KEEP MOVING</p><h2>My courses</h2></div><span>{courses.length} enrolled</span></div>
          {courses.length === 0 ? (
            <div className="dashboard-empty"><span className="dashboard-placeholder-mark">K</span><h3>Your learning journey starts here.</h3><p>Enrol in a published course and it will appear here with your progress, lessons and next step.</p><Link className="button button-primary" href="/courses">Browse courses <span>→</span></Link></div>
          ) : (
            <LearnerCourseList courses={courses} withdrawAction={withdrawFromCourseAction} />
          )}
        </section>

        <div className="dashboard-lower-grid">
          <section className="dashboard-section dashboard-activity">
            <div className="dashboard-section-heading"><div><p className="eyebrow">YOUR LATEST STEPS</p><h2>Recent activity</h2></div></div>
            {recentActivity.length === 0 ? <p className="dashboard-muted">Your completed lessons and submitted quizzes will appear here.</p> : (
              <ul>{recentActivity.map((item) => (
                <li key={item.key}><div><strong>{item.label}</strong><span>{item.detail}</span></div><time>{formatDate(item.date)}</time>{item.score !== null && <b className={item.passed ? "activity-passed" : "activity-score"}>{item.score}%</b>}</li>
              ))}</ul>
            )}
          </section>
          <section className="dashboard-section dashboard-results">
            <div className="dashboard-section-heading"><div><p className="eyebrow">CHECK YOUR RESULTS</p><h2>Assessment results</h2></div></div>
            {attempts.length === 0 ? <p className="dashboard-muted">Your quiz scores and final assessment results will appear here after submission.</p> : (
              <ul>{attempts.slice(0, 5).map((attempt) => (
                <li key={attempt.id}><div><strong>{attempt.assessments.title}</strong><span>{formatDate(attempt.submitted_at)}</span></div><b className={attempt.passed ? "activity-passed" : "activity-score"}>{Number(attempt.score_percentage).toFixed(0)}% · {attempt.passed ? "Passed" : "Not passed"}</b></li>
              ))}</ul>
            )}
          </section>
        </div>
      </section>
    </main>
  );
}
