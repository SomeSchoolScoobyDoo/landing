import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Brand } from "@/components/brand";
import { submitCourseFeedbackAction } from "./actions";
import styles from "./feedback.module.css";

type Props = { params: Promise<{ courseSlug: string }>; searchParams: Promise<{ submitted?: string }> };

export default async function CourseFeedbackPage({ params, searchParams }: Props) {
  const { courseSlug } = await params;
  const query = await searchParams;
  if (!/^[a-z0-9-]{1,120}$/.test(courseSlug)) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: course } = await supabase
    .from("courses")
    .select("id, title")
    .eq("slug", courseSlug)
    .eq("status", "published")
    .maybeSingle();
  if (!course) notFound();

  const { data: enrollment } = await supabase
    .from("course_enrollments")
    .select("id")
    .eq("user_id", user.id)
    .eq("course_id", course.id)
    .eq("status", "active")
    .maybeSingle();
  if (!enrollment) redirect("/dashboard");

  const { data: existingFeedback } = await supabase
    .from("course_feedback")
    .select("id")
    .eq("user_id", user.id)
    .eq("course_id", course.id)
    .maybeSingle();

  const { data: modules, error: modulesError } = await supabase
    .from("course_modules")
    .select("lessons!inner(id)")
    .eq("course_id", course.id)
    .eq("status", "published")
    .eq("lessons.status", "published");
  if (modulesError) throw new Error("Course progress could not be checked.");

  const lessonIds = (modules ?? []).flatMap((module) => (module.lessons ?? []).map((lesson) => lesson.id));
  const { data: progress, error: progressError } = lessonIds.length
    ? await supabase.from("lesson_progress").select("lesson_id")
        .eq("user_id", user.id).not("completed_at", "is", null).in("lesson_id", lessonIds)
    : { data: [], error: null };
  if (progressError) throw new Error("Course progress could not be checked.");

  const completedCount = new Set((progress ?? []).map((item) => item.lesson_id)).size;
  const complete = lessonIds.length > 0 && completedCount === lessonIds.length;
  const submitted = query.submitted === "1" || query.submitted === "already" || Boolean(existingFeedback);

  return (
    <main className={styles.page}>
      <header className="site-header"><Brand /><nav aria-label="Learner navigation"><Link href="/dashboard">Dashboard</Link><Link href="/courses">Explore courses</Link></nav></header>
      <section className={styles.shell}>
        <Link className="course-back-link" href="/dashboard">← Back to your learning space</Link>
        <p className={styles.eyebrow}>KAIZORA AI ACADEMY · LEARNER FEEDBACK</p>
        {submitted ? (
          <div className={styles.success}>
            <span className={styles.check}>✓</span>
            <h1>Thank you for helping us improve.</h1>
            <p>Your feedback for <strong>{course.title}</strong> has been saved. It helps us make the next learner&apos;s experience better.</p>
            <Link className="button button-primary" href="/dashboard">Return to dashboard <span>→</span></Link>
          </div>
        ) : !complete ? (
          <div className={styles.success}>
            <h1>You&apos;re nearly there.</h1>
            <p>Complete all published lessons in <strong>{course.title}</strong> before leaving course feedback. You have completed {completedCount} of {lessonIds.length} lessons.</p>
            <Link className="button button-primary" href="/dashboard">Continue learning <span>→</span></Link>
          </div>
        ) : (
          <>
            <h1>How was your learning experience?</h1>
            <p className={styles.intro}>You completed <strong>{course.title}</strong>. Give us a few honest answers. This should take about two minutes.</p>
            <form action={submitCourseFeedbackAction} className={styles.form}>
              <input type="hidden" name="courseSlug" value={courseSlug} />
              <fieldset>
                <legend>Overall, how would you rate this course?</legend>
                <div className={styles.rating}>{[1,2,3,4,5].map((n) => <label key={n}><input type="radio" name="overall_rating" value={n} required/><span>{n}</span></label>)}</div>
                <small>1 = Poor · 5 = Excellent</small>
              </fieldset>
              <fieldset>
                <legend>How smooth was the full platform journey: account creation, finding and enrolling in the course, opening lessons, watching videos, taking quizzes, and checking completion?</legend>
                <div className={styles.rating}>{[1,2,3,4,5].map((n) => <label key={n}><input type="radio" name="platform_experience_rating" value={n} required/><span>{n}</span></label>)}</div>
                <small>1 = Very difficult · 5 = Very smooth</small>
              </fieldset>
              <fieldset>
                <legend>How clear and easy to understand was the content?</legend>
                <div className={styles.rating}>{[1,2,3,4,5].map((n) => <label key={n}><input type="radio" name="content_clarity" value={n} required/><span>{n}</span></label>)}</div>
                <small>1 = Very unclear · 5 = Very clear</small>
              </fieldset>
              <fieldset>
                <legend>How was the pace of the course?</legend>
                <div className={styles.rating}>{[1,2,3,4,5].map((n) => <label key={n}><input type="radio" name="learning_pace" value={n} required/><span>{n}</span></label>)}</div>
                <small>1 = Poorly paced · 5 = Just right</small>
              </fieldset>
              <fieldset>
                <legend>How confident do you feel applying what you learned?</legend>
                <div className={styles.rating}>{[1,2,3,4,5].map((n) => <label key={n}><input type="radio" name="practical_confidence" value={n} required/><span>{n}</span></label>)}</div>
                <small>1 = Not confident · 5 = Very confident</small>
              </fieldset>
              <label className={styles.field}>What was the most useful part of the course?<textarea name="most_useful" rows={3} maxLength={2000} placeholder="Tell us what worked well for you."/></label>
              <label className={styles.field}>Did anything confuse you or prevent you from progressing?<textarea name="blockers" rows={3} maxLength={2000} placeholder="Mention unclear lessons, technical issues, broken links, or anything else."/></label>
              <label className={styles.field}>What should we improve?<textarea name="improvement_suggestion" rows={3} maxLength={2000} placeholder="Your honest suggestions are welcome."/></label>
              <fieldset>
                <legend>Would you recommend this course to someone else?</legend>
                <div className={styles.recommend}><label><input type="radio" name="would_recommend" value="yes" required/> Yes</label><label><input type="radio" name="would_recommend" value="no" required/> No</label></div>
              </fieldset>
              <button className="button button-primary" type="submit">Submit feedback <span>→</span></button>
              <p className={styles.privacy}>Your response is linked to your Kaizora account and this course so the team can review learning feedback. Please do not include passwords or sensitive personal information.</p>
            </form>
          </>
        )}
      </section>
    </main>
  );
}
