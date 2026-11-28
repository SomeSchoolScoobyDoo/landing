import Image from "next/image";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { markLessonCompleteAction } from "@/app/learn/actions";
import { getLessonForLearner } from "@/lib/courses/lessons";
import { AssessmentQuiz } from "./assessment-quiz";
import { LearnerNavigation } from "@/components/learner-navigation";

type Props = {
  params: Promise<{ courseSlug: string; lessonNumber: string }>;
  searchParams?: Promise<{ quiz?: string }>;
};

function getYouTubeEmbedUrl(value: string | null) {
  if (!value) return null;
  try {
    const url = new URL(value);
    const host = url.hostname.replace(/^www\\./, "").toLowerCase();
    let videoId = "";
    if (host === "youtu.be") videoId = url.pathname.split("/").filter(Boolean)[0] ?? "";
    else if (host === "youtube.com" || host === "m.youtube.com" || host === "youtube-nocookie.com") {
      videoId = url.searchParams.get("v") ?? url.pathname.match(/^\\/(?:embed|shorts|live)\\/([^/?]+)/)?.[1] ?? "";
    }
    return /^[a-zA-Z0-9_-]{11}$/.test(videoId)
      ? `https://www.youtube-nocookie.com/embed/${videoId}`
      : null;
  } catch {
    return null;
  }
}

export default async function LessonPage({ params, searchParams }: Props) {
  const { courseSlug, lessonNumber: lessonId } = await params;
  const { quiz: quizStatus } = (await searchParams) ?? {};
  const result = await getLessonForLearner(courseSlug, lessonId);
  if (!result.user) redirect("/login");
  if (!result.enrolled) redirect(`/courses/${courseSlug}`);
  if (!result.lesson) notFound();

  const lesson = result.lesson;
  const content = lesson.content ?? {};

  return (
    <main className="lesson-page">
      <header className="site-header">
        <Link className="brand" href="/" aria-label="Kaizora AI Academy home"><Image src="/kaizora-logo.svg" alt="" width={30} height={36} priority /><span>kaizora<span className="brand-light"> AI Academy</span></span></Link>
        <LearnerNavigation />
      </header>
      <article className="lesson-content">
        <Link className="course-back-link" href={`/courses/${courseSlug}`}>← Back to course</Link>
        <p className="eyebrow">MODULE {lesson.course_modules.module_number}: {lesson.course_modules.title}</p>
        <h1>{lesson.lesson_number}. {lesson.title}</h1>
        <p className="lesson-meta">{lesson.estimated_minutes} minutes · {result.completed ? "Completed" : "In progress"}</p>
        {content.simple_explanation && <section><h2>What you&apos;ll learn</h2><p>{content.simple_explanation}</p></section>}
        {lesson.youtube_url && (
          <section className="lesson-video-section">
            <h2>Video lesson</h2>
            {getYouTubeEmbedUrl(lesson.youtube_url) ? (
              <div style={{ width: "100%", aspectRatio: "16 / 9", overflow: "hidden", borderRadius: 8, background: "#101827" }}>
                <iframe
                  src={getYouTubeEmbedUrl(lesson.youtube_url)!}
                  title={`Video lesson: ${lesson.title}`}
                  loading="lazy"
                  referrerPolicy="strict-origin-when-cross-origin"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                  allowFullScreen
                  style={{ width: "100%", height: "100%", border: 0 }}
                />
              </div>
            ) : (
              <p>This video cannot be embedded. <a href={lesson.youtube_url} target="_blank" rel="noreferrer">Watch it on YouTube ↗</a></p>
            )}
            <p><a href={lesson.youtube_url} target="_blank" rel="noreferrer">Open on YouTube ↗</a></p>
          </section>
        )}
        {Array.isArray(content.step_by_step_guide) && content.step_by_step_guide.length > 0 && <section><h2>Step-by-step guide</h2><ol>{content.step_by_step_guide.map((step, index) => <li key={index}>{step}</li>)}</ol></section>}
        {Array.isArray(content.key_terms) && content.key_terms.length > 0 && <section><h2>Key terms</h2><dl>{content.key_terms.map((item, index) => <div key={index}><dt>{item.term}</dt><dd>{item.meaning}</dd></div>)}</dl></section>}
        {content.practical_exercise && <section><h2>{content.practical_exercise.task_title || "Practical exercise"}</h2><p>{content.practical_exercise.instructions}</p>{content.practical_exercise.expected_outcome && <p><strong>Expected outcome:</strong> {content.practical_exercise.expected_outcome}</p>}</section>}
        {result.resources.length > 0 && (
          <section>
            <h2>Lesson resources</h2>
            <ul>
              {result.resources.map((resource) => (
                <li key={resource.id}>
                  <strong>{resource.title}</strong>
                  {resource.description && <p>{resource.description}</p>}
                  <a href={resource.url} target="_blank" rel="noreferrer">Open resource ↗</a>
                </li>
              ))}
            </ul>
            <p>Secure resource links expire after five minutes.</p>
          </section>
        )}
        {quizStatus && (
          <p className="dashboard-notice" role="status">
            {quizStatus === "submitted" && "Your quiz was submitted successfully. Your result is shown below."}
            {quizStatus === "attempts-exhausted" && "You have used all available attempts for this quiz. Your previous result is saved."}
            {quizStatus === "failed" && "Your quiz could not be submitted. Your answers have not been marked as submitted. Please refresh and try again."}
            {quizStatus === "unavailable" && "This quiz is currently unavailable or does not match this lesson."}
            {quizStatus === "invalid" && "The quiz submission could not be read. Please answer every question and try again."}
          </p>
        )}
        {result.assessment && result.assessment.assessment_questions.length > 0 && (
          <AssessmentQuiz
            assessmentId={result.assessment.id}
            lessonId={lesson.id}
            courseSlug={courseSlug}
            title={result.assessment.title}
            instructions={result.assessment.instructions}
            passingScore={result.assessment.passing_score_percentage}
            maxAttempts={result.assessment.max_attempts}
            attemptsUsed={result.assessmentAttempts.length}
            latestAttempt={result.assessmentAttempts[0] ?? null}
            questions={result.assessment.assessment_questions}
          />
        )}
        <div className="lesson-completion-area">
          {result.completed ? (
            <p className="lesson-completed-status" role="status">✓ Lesson completed</p>
          ) : (
            <form action={markLessonCompleteAction}>
              <input type="hidden" name="lessonId" value={lesson.id}/>
              <input type="hidden" name="courseSlug" value={courseSlug}/>
              <button className="button button-primary" type="submit">Mark lesson complete <span>→</span></button>
            </form>
          )}
        </div>
        <nav className="lesson-navigation" aria-label="Move between lessons">
          {result.previousLesson && (
            <Link href={`/learn/${courseSlug}/${result.previousLesson.id}`}>
              ← Previous
            </Link>
          )}
          {result.nextLesson && (
            <Link href={`/learn/${courseSlug}/${result.nextLesson.id}`}>
              Next →
            </Link>
          )}
        </nav>
      </article>
    </main>
  );
}
