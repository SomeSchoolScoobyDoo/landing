"use client";

import type { FormEvent } from "react";

type UnenrollButtonProps = {
  courseTitle: string;
  action: (data: FormData) => void | Promise<void>;
  courseSlug: string;
};

export function UnenrollButton({ courseTitle, action, courseSlug }: UnenrollButtonProps) {
  function confirmWithdrawal(event: FormEvent<HTMLFormElement>) {
    if (!window.confirm(`Unenrol from "${courseTitle}"? Your saved learning progress will be kept, and you can enrol again later.`)) {
      event.preventDefault();
    }
  }

  return (
    <form className="unenroll-form" action={action} onSubmit={confirmWithdrawal}>
      <input type="hidden" name="courseSlug" value={courseSlug} />
      <button className="unenroll-button" type="submit">Unenrol</button>
    </form>
  );
}
