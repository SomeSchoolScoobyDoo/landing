import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Brand } from "@/components/brand";
import { LearnerNavigation } from "@/components/learner-navigation";
import { getCourseAssessmentForLearner } from "@/lib/courses/lessons";
import { AssessmentQuiz } from "../../[lessonNumber]/assessment-quiz";

type Props = { params: Promise<{ courseSlug: string; moduleNumber: string }> };

export default async function ModuleQuizPage({ params }: Props) {
  const { courseSlug, moduleNumber: rawModuleNumber } = await params;
  const moduleNumber = Number(rawModuleNumber);
  if (!Number.isInteger(moduleNumber) || moduleNumber < 1) notFound();

  const result = await getCourseAssessmentForLearner(courseSlug, "module_quiz", moduleNumber);
  if (!result.user) redirect("/login");
  if (!result.enrolled) redirect(`/courses/${courseSlug}`);
  if (!result.course || !result.module || !result.assessment) notFound();

  return (
    <main className="lesson-page">
      <header className="site-header">
        <Brand />
        <LearnerNavigation />
      </header>
      <article className="lesson-content">
        <Link className="course-back-link" href={`/courses/${courseSlug}`}>← Back to course</Link>
        <p className="eyebrow">MODULE {result.module.module_number}: {result.module.title}</p>
        <h1>{result.assessment.title}</h1>
        {result.lockedReason ? (
          <section className="assessment-card" aria-live="polite">
            <h2>Quiz locked</h2>
            <p>{result.lockedReason}</p>
            <Link className="button button-secondary" href={`/courses/${courseSlug}`}>Return to course</Link>
          </section>
        ) : (
          <AssessmentQuiz
            assessmentId={result.assessment.id}
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
      </article>
    </main>
  );
}
