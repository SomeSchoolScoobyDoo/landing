"use client";

import { useFormStatus } from "react-dom";

export function LessonNextButton() {
  const { pending } = useFormStatus();

  return (
    <button
      className="lesson-nav-button lesson-nav-next"
      type="submit"
      disabled={pending}
      aria-live="polite"
    >
      {pending ? "Saving…" : "Next →"}
    </button>
  );
}
