import Image from "next/image";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { completeLessonAndContinueAction } from "@/app/learn/actions";
import { LessonNextButton } from "@/components/lesson-next-button";
import { getLessonForLearner } from "@/lib/courses/lessons";
import { AssessmentQuiz } from "./assessment-quiz";

type Props = { params: Promise<{ courseSlug: string; lessonNumber: string }> };

function getYouTubeEmbedUrl(value: string) {
  try {
    const url = new URL(value);
    if (!["www.youtube.com", "youtube.com", "youtu.be", "m.youtube.com"].includes(url.hostname)) return null;
    const id = url.hostname === "youtu.be"
      ? url.pathname.split("/").filter(Boolean)[0]
      : url.pathname === "/watch"
        ? url.searchParams.get("v")
        : url.pathname.split("/").filter(Boolean).at(-1);
    if (!id || !/^[a-zA-Z0-9_-]{11}$/.test(id)) return null;
    return `https://www.youtube-nocookie.com/embed/${id}`;
  } catch {
    return null;
  }
}

export default async function LessonPage({ params }: Props) {
  const { courseSlug, lessonNumber: lessonId } = await params;
  const result = await getLessonForLearner(courseSlug, lessonId);
  if (!result.user) redirect("/login");
  if (!result.enrolled) redirect(`/courses/${courseSlug}`);
  if (!result.lesson) notFound();

  const lesson = result.lesson;
  const content = lesson.content ?? {};
  const videoEmbedUrl = lesson.youtube_url ? getYouTubeEmbedUrl(lesson.youtube_url) : null;

  return (
    <main className="lesson-page">
      <header className="site-header">
        <Link className="brand" href="/" aria-label="Kaizora AI Academy home"><Image src="/kaizora-logo.svg" alt="" width={30} height={36} priority /><span>kaizora<span className="brand-light"> AI Academy</span></span></Link>
        <nav aria-label="Lesson navigation"><Link href="/courses">All courses</Link><Link href="/dashboard">Dashboard</Link></nav>
      </header>
      <article className="lesson-content">
        <Link className="course-back-link" href={`/courses/${courseSlug}`}>← Back to course</Link>
        <p className="eyebrow">MODULE {lesson.course_modules.module_number}: {lesson.course_modules.title}</p>
        <h1>{lesson.lesson_number}. {lesson.title}</h1>
        <p className="lesson-meta">{lesson.estimated_minutes} minutes · {result.completed ? "✓ Lesson completed" : "In progress"}</p>
        {content.simple_explanation && <section><h2>What you&apos;ll learn</h2><p>{content.simple_explanation}</p></section>}
        {videoEmbedUrl && (
          <section>
            <h2>Watch inside Kaizora</h2>
            <div style={{ position: "relative", width: "100%", maxWidth: "420px", aspectRatio: "9 / 16", marginInline: "auto", overflow: "hidden", borderRadius: "16px", background: "#090909" }}>
              <iframe
                src={videoEmbedUrl}
                title={`Video lesson: ${lesson.title}`}
                loading="lazy"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                referrerPolicy="strict-origin-when-cross-origin"
                allowFullScreen
                style={{ position: "absolute", inset: 0, width: "100%", height: "100%", border: 0 }}
              />
            </div>
            <p>Keep the video here in the lesson, then continue to the questions below.</p>
          </section>
        )}
        {lesson.youtube_url && !videoEmbedUrl && <section><h2>Video unavailable</h2><p>This video link could not be embedded. Please report it to the Kaizora team.</p></section>}
        {Array.isArray(content.poem_stanzas) && content.poem_stanzas.length > 0 && <section><h2>The poem</h2><div className="lesson-reading-poem">{content.poem_stanzas.map((stanza, index) => <p key={index} style={{ whiteSpace: "pre-line" }}>{stanza}</p>)}</div></section>}
        {Array.isArray(content.story_paragraphs) && content.story_paragraphs.length > 0 && <section><h2>The story</h2><div className="lesson-reading-story">{content.story_paragraphs.map((paragraph, index) => <p key={index}>{paragraph}</p>)}</div></section>}
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
        <nav className="lesson-navigation" aria-label="Lesson navigation">
          {result.previousLesson ? (
            <Link className="lesson-nav-button lesson-nav-previous" href={`/learn/${courseSlug}/${result.previousLesson.id}`}>
              ← Previous
            </Link>
          ) : (
            <button className="lesson-nav-button lesson-nav-previous" type="button" disabled>
              ← Previous
            </button>
          )}
          <form action={completeLessonAndContinueAction}>
            <input type="hidden" name="lessonId" value={lesson.id} />
            <input type="hidden" name="courseSlug" value={courseSlug} />
            {result.nextLesson && <input type="hidden" name="nextLessonId" value={result.nextLesson.id} />}
            <LessonNextButton />
          </form>
        </nav>
      </article>
    </main>
  );
}
