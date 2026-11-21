"use client";

import { useMemo, useState } from "react";
import { submitAssessmentAction } from "@/app/learn/actions";

type Option = { key: string; text: string };
type Question = {
  id: string;
  question_number: number;
  prompt: string;
  options: Option[];
};
type Props = {
  assessmentId: string;
  lessonId: string;
  courseSlug: string;
  title: string;
  instructions: string;
  passingScore: number;
  maxAttempts: number;
  attemptsUsed: number;
  latestAttempt?: { score_percentage: number; passed: boolean } | null;
  questions: Question[];
};

export function AssessmentQuiz(props: Props) {
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const answerPayload = useMemo(
    () => JSON.stringify(
      props.questions.map((question) => ({
        question_id: question.id,
        selected_option_key: answers[question.id] ?? "",
      })),
    ),
    [answers, props.questions],
  );
  const remaining = Math.max(0, props.maxAttempts - props.attemptsUsed);
  const complete = props.questions.length > 0 &&
    props.questions.every((question) => Boolean(answers[question.id]));
  const exhausted = remaining === 0;

  return (
    <section className="assessment-card" aria-labelledby="assessment-title">
      <div className="assessment-heading">
        <p className="eyebrow">KNOWLEDGE CHECK</p>
        <h2 id="assessment-title">{props.title}</h2>
        <p>{props.instructions || "Choose one answer for each question."}</p>
        <p className="assessment-meta">
          Pass mark: {props.passingScore}% · Attempts remaining: {remaining}
        </p>
      </div>

      {props.latestAttempt && (
        <div className={props.latestAttempt.passed ? "assessment-result is-passed" : "assessment-result"}>
          <strong>{props.latestAttempt.passed ? "You passed" : "Previous result"}</strong>
          <span>{Number(props.latestAttempt.score_percentage).toFixed(0)}%</span>
        </div>
      )}

      {exhausted ? (
        <p className="assessment-locked">You have reached the attempt limit for this quiz.</p>
      ) : (
        <form action={submitAssessmentAction}>
          <input type="hidden" name="assessmentId" value={props.assessmentId} />
          <input type="hidden" name="lessonId" value={props.lessonId} />
          <input type="hidden" name="courseSlug" value={props.courseSlug} />
          <input type="hidden" name="answers" value={answerPayload} />
          {props.questions.map((question) => (
            <fieldset className="assessment-question" key={question.id}>
              <legend>
                <span>Question {question.question_number}</span>
                {question.prompt}
              </legend>
              <div className="assessment-options">
                {question.options.map((option) => (
                  <label className="assessment-option" key={option.key}>
                    <input
                      type="radio"
                      name={question.id}
                      value={option.key}
                      checked={answers[question.id] === option.key}
                      onChange={() => setAnswers((current) => ({
                        ...current,
                        [question.id]: option.key,
                      }))}
                    />
                    <span>{option.text}</span>
                  </label>
                ))}
              </div>
            </fieldset>
          ))}
          <button className="button button-primary" type="submit" disabled={!complete}>
            Submit quiz <span>→</span>
          </button>
          {!complete && <p className="assessment-hint">Answer every question to submit.</p>}
        </form>
      )}
    </section>
  );
}
