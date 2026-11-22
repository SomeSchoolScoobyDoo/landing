import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Brand } from "@/components/brand";
import { submitCourseFeedbackAction } from "../actions";

type Props = { params: Promise<{ courseSlug: string }>; searchParams: Promise<{ submitted?: string }> };

export default async function CourseFeedbackPage({ params, searchParams }: Props) {
  const { courseSlug } = await params;
  const query = await searchParams;
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { data: course, error: courseError } = await supabase
    .from("courses")
    .select("id, title")
    .eq("slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();
  if (courseError || !course) redirect("/courses");

  const { data: enrollment } = await supabase
    .from("course_enrollments")
    .select("id")
    .eq("user_id", auth.user.id)
    .eq("course_id", course.id)
    .eq("status", "active")
    .maybeSingle();
  if (!enrollment) redirect("/courses/" + courseSlug);

  const { data: existingFeedback } = await supabase
    .from("course_feedback")
    .select("id")
    .eq("user_id", auth.user.id)
    .eq("course_id", course.id)
    .maybeSingle();

  const { data: modules, error: modulesError } = await supabase
    .from("course_modules")
    .select("id, lessons!inner(id)")
    .eq("course_id", course.id)
    .eq("status", "published")
    .eq("lessons.status", "published");

  const lessonIds = (modules ?? []).flatMap((module) =>
    ((module.lessons ?? []) as unknown as { id: string }[]).map((lesson) => lesson.id)
  );
  const { data: progress, error: progressError } = lessonIds.length
    ? await supabase.from("lesson_progress").select("lesson_id, completed_at").eq("user_id", auth.user.id).in("lesson_id", lessonIds)
    : { data: [], error: null };
  const completedIds = new Set((progress ?? []).filter((item) => item.completed_at).map((item) => item.lesson_id));
  const complete = !modulesError && !progressError && lessonIds.length > 0 && completedIds.size === lessonIds.length;

  return (
    <main className="feedback-page">
      <header className="site-header">
        <Brand />
        <nav aria-label="Feedback navigation"><Link href="/dashboard">Dashboard</Link><Link href="/account">My account</Link></nav>
      </header>
      <section className="feedback-content">
        <p className="eyebrow">HELP US IMPROVE</p>
        <h1>Course feedback</h1>
        <h2>{course.title}</h2>
        {query.submitted === "1" || existingFeedback ? (
          <div className="feedback-success" role="status">
            <h3>Thank you for your feedback.</h3>
            <p>Your response has been saved. It helps us improve the learning experience for everyone.</p>
          </div>
        ) : !complete ? (
          <div className="feedback-success">
            <h3>One more step.</h3>
            <p>Complete every published lesson in this course before submitting your feedback.</p>
            <Link className="button button-primary" href="/dashboard">Return to dashboard <span>→</span></Link>
          </div>
        ) : (
          <form action={submitCourseFeedbackAction} className="course-feedback-form">
            <input type="hidden" name="courseSlug" value={courseSlug} />
            <p className="feedback-instructions">Please be honest. Your feedback is for improving both the course and the platform.</p>
            <div className="feedback-rating-grid">
              <label>Overall course experience
                <select name="overallRating" required defaultValue=""><option value="" disabled>Select 1–5</option>{[1,2,3,4,5].map((n)=><option key={n} value={n}>{n} · {["","Poor","Fair","Good","Very good","Excellent"][n]}</option>)}</select>
              </label>
              <label>How clear was the content?
                <select name="contentClarity" required defaultValue=""><option value="" disabled>Select 1–5</option>{[1,2,3,4,5].map((n)=><option key={n} value={n}>{n}</option>)}</select>
              </label>
              <label>How was the learning pace?
                <select name="learningPace" required defaultValue=""><option value="" disabled>Select 1–5</option>{[1,2,3,4,5].map((n)=><option key={n} value={n}>{n}</option>)}</select>
              </label>
              <label>How confident do you feel applying what you learned?
                <select name="practicalConfidence" required defaultValue=""><option value="" disabled>Select 1–5</option>{[1,2,3,4,5].map((n)=><option key={n} value={n}>{n}</option>)}</select>
              </label>
              <label>How was the platform experience?
                <select name="platformExperience" required defaultValue=""><option value="" disabled>Select 1–5</option>{[1,2,3,4,5].map((n)=><option key={n} value={n}>{n}</option>)}</select>
              </label>
            </div>
            <label>What was most useful?
              <textarea name="mostUseful" maxLength={2000} rows={4} required />
            </label>
            <label>What should we improve?
              <textarea name="improvementSuggestion" maxLength={2000} rows={4} required />
            </label>
            <label>What blocked you or made learning harder? (Write “None” if nothing did.)
              <textarea name="blockers" maxLength={2000} rows={3} required />
            </label>
            <label>Would you recommend this course?
              <select name="wouldRecommend" defaultValue=""><option value="">Not sure</option><option value="yes">Yes</option><option value="no">No</option></select>
            </label>
            <button className="auth-submit" type="submit">Submit feedback</button>
          </form>
        )}
        <Link className="account-back-link" href="/dashboard">← Back to dashboard</Link>
      </section>
    </main>
  );
}
