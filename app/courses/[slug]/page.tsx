import Link from "next/link";
import { notFound } from "next/navigation";
import { getPublishedCourseBySlug, getPublicCoursePreview, type PublicCoursePreviewRow } from "@/lib/courses/catalogue";
import { createClient } from "@/lib/supabase/server";
import { enrollInCourseAction, withdrawFromCourseAction } from "@/app/learn/actions";
import { Brand } from "@/components/brand";
import { UnenrollButton } from "@/components/unenroll-button";

type CoursePageProps = { params: Promise<{ slug: string }> };

export default async function CourseDetailPage({ params }: CoursePageProps) {
  const { slug } = await params;
  let course;
  try {
    course = await getPublishedCourseBySlug(slug);
  } catch {
    course = null;
  }
  if (!course) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  let isEnrolled = false;
  if (user) {
    const { data: enrollment, error: enrollmentError } = await supabase
      .from("course_enrollments")
      .select("id")
      .eq("user_id", user.id)
      .eq("course_id", course.id)
      .eq("status", "active")
      .maybeSingle();
    if (enrollmentError) {
      throw new Error("Your course enrolment could not be checked. Please refresh.");
    }
    isEnrolled = Boolean(enrollment);
  }

  let previewRows: PublicCoursePreviewRow[] = [];
  try {
    previewRows = await getPublicCoursePreview(slug);
  } catch {
    // The public course description remains available if the preview RPC is not
    // yet present in a development database awaiting its migration.
  }
  const previewModules = [...new Map(previewRows.map((row) => [row.module_number, {
    module_number: row.module_number,
    module_title: row.module_title,
    lessons: previewRows.filter((lesson) => lesson.module_number === row.module_number && lesson.lesson_title),
  }])).values()];

  const category = course.course_categories?.[0]?.name ?? "Kaizora course";
  const duration = course.estimated_minutes > 0
    ? `${Math.round((course.estimated_minutes / 60) * 10) / 10} hours`
    : "Self-paced";

  return (
    <main>
      <header className="site-header">
        <Brand />
        <nav aria-label="Main navigation"><Link href="/courses">All courses</Link><Link href="/login">Log in</Link></nav>
        <Link className="header-link" href="/signup">Create account <span>↗</span></Link>
      </header>
      <section className="course-detail-hero">
        <Link className="course-back-link" href="/courses">← Back to all courses</Link>
        <p className="eyebrow">{category.toUpperCase()}</p>
        <h1>{course.title}</h1>
        <p className="course-detail-summary">{course.summary || course.description}</p>
        <div className="course-detail-meta"><span>{duration}</span><span>{course.difficulty.replace("_", " ")}</span><span>Independent course</span></div>
      </section>
      <section className="course-detail-body">
        <div><p className="eyebrow">ABOUT THIS COURSE</p><h2>Build knowledge you can <span>put to work.</span></h2><p>{course.description || course.summary}</p></div>
        <aside><h3>{isEnrolled ? "You’re enrolled" : "Ready to get started?"}</h3>{isEnrolled ? <><p>Your learning progress is available from your learner dashboard.</p><Link className="button button-primary" href="/dashboard">Continue learning <span>→</span></Link><UnenrollButton courseTitle={course.title} courseSlug={course.slug} action={withdrawFromCourseAction} /></> : <><p>Enrol in this course and track your progress from your learner dashboard.</p><form action={enrollInCourseAction}><input type="hidden" name="courseSlug" value={course.slug} /><button className="button button-primary" type="submit">Enrol and start learning <span>→</span></button></form><p className="course-signup-note">New to Kaizora? <Link href="/signup">Create your learner account</Link>.</p></>}</aside>
      </section>
      <section className="course-preview-section">
        <div className="course-preview-heading">
          <p className="eyebrow">COURSE PREVIEW</p>
          <h2>See what you’ll <span>learn.</span></h2>
          <p>Explore the published modules and lesson titles before enrolling. No payment is required to preview the course.</p>
        </div>
        {previewModules.length > 0 ? (
          <div className="course-preview-grid">
            <div className="course-curriculum">
              {previewModules.map((module) => (
                <article className="course-module-preview" key={module.module_number}>
                  <div className="course-module-preview-heading">
                    <span>MODULE {module.module_number}</span>
                    <h3>{module.module_title}</h3>
                  </div>
                  {module.lessons.length > 0 ? (
                    <ol>{module.lessons.map((lesson) => (
                      <li key={lesson.lesson_number}>
                        <span>{lesson.lesson_number}. {lesson.lesson_title}</span>
                      </li>
                    ))}</ol>
                  ) : <p className="course-preview-muted">Lessons will be published here soon.</p>}
                </article>
              ))}
            </div>
          </div>
        ) : (
          <div className="course-preview-empty">
            <h3>Curriculum coming soon</h3>
            <p>The course description is ready. Published modules and lesson previews will appear here as the learning content is added.</p>
          </div>
        )}
      </section>
      <footer className="site-footer"><Brand className="footer-brand" /><p>Learn. Build. Apply.</p><span>© {new Date().getFullYear()} Kaizora AI Academy</span></footer>
    </main>
  );
}
