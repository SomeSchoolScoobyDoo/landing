"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { UnenrollButton } from "@/components/unenroll-button";

type Course = {
  id: string;
  enrolled_at: string;
  courses: { id: string; slug: string; title: string; summary: string; estimated_minutes: number };
  completed: number;
  total: number;
  percentage: number;
  nextLesson: { id: string } | null;
};

type Props = {
  courses: Course[];
  withdrawAction: (data: FormData) => void | Promise<void>;
};

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" });
}

function formatDuration(minutes: number) {
  if (!minutes) return "Self-paced";
  const hours = Math.round((minutes / 60) * 10) / 10;
  return hours === 1 ? "1 hour" : `${hours} hours`;
}

export function LearnerCourseList({ courses, withdrawAction }: Props) {
  const [sort, setSort] = useState("recent");
  const sortedCourses = useMemo(() => {
    return [...courses].sort((a, b) => {
      if (sort === "name") return a.courses.title.localeCompare(b.courses.title);
      if (sort === "progress-asc") return a.percentage - b.percentage;
      if (sort === "progress-desc") return b.percentage - a.percentage;
      return new Date(b.enrolled_at).getTime() - new Date(a.enrolled_at).getTime();
    });
  }, [courses, sort]);

  return (
    <div className="learner-course-list">
      <div className="learner-course-toolbar">
        <label htmlFor="course-sort">Sort courses</label>
        <select id="course-sort" value={sort} onChange={(event) => setSort(event.target.value)}>
          <option value="recent">Recently enrolled</option>
          <option value="name">Course name</option>
          <option value="progress-desc">Highest progress</option>
          <option value="progress-asc">Lowest progress</option>
        </select>
      </div>
      <div className="learner-course-grid">
        {sortedCourses.map((course) => (
          <article className="learner-course-card" key={course.id}>
            <div className="learner-course-top"><span>ENROLLED {formatDate(course.enrolled_at)}</span><strong>{course.percentage}%</strong></div>
            <h3>{course.courses.title}</h3>
            <p>{course.courses.summary || "Continue building your skills with this course."}</p>
            <div className="progress-track"><span style={{ width: `${course.percentage}%` }} /></div>
            <div className="learner-course-meta"><span>{course.completed} of {course.total} lessons completed</span><span>{formatDuration(course.courses.estimated_minutes)}</span></div>
            {course.nextLesson ? (
              <Link className="learner-continue-link" href={`/learn/${course.courses.slug}/${course.nextLesson.id}`}>{course.completed === course.total ? "Review course" : "Continue learning"} <span>→</span></Link>
            ) : (
              <Link className="learner-continue-link" href={`/courses/${course.courses.slug}`}>View course details <span>→</span></Link>
            )}
            <UnenrollButton courseTitle={course.courses.title} courseSlug={course.courses.slug} action={withdrawAction} />
          </article>
        ))}
      </div>
    </div>
  );
}
