import Link from "next/link";
import { notFound } from "next/navigation";
import { getPublishedCourseBySlug, getPublicCoursePreview, type PublicCoursePreviewRow } from "@/lib/courses/catalogue";
import { createClient } from "@/lib/supabase/server";
import { enrollInCourseAction, withdrawFromCourseAction } from "@/app/learn/actions";
import { Brand } from "@/components/brand";
import { LearnerNavigation } from "@/components/learner-navigation";
import { UnenrollButton } from "@/components/unenroll-button";
import { CourseCompletionBadge } from "@/components/course-completion-badge";
import { CourseDetailAnalytics } from "@/components/course-detail-analytics";

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
  let completionBadge: { course_title: string; issued_at: string } | null = null;
  let learnerName = "";

  if (user) {
    const [enrollmentResult, profileResult, badgeResult] = await Promise.all([
      supabase
        .from("course_enrollments")
        .select("id")
        .eq("user_id", user.id)
        .eq("course_id", course.id)
        .eq("status", "active")
        .maybeSingle(),
      supabase
        .from("profiles")
        .select("full_name, certificate_display_name")
        .eq("id", user.id)
        .maybeSingle(),
      supabase
        .from("course_badges")
        .select("course_title, issued_at")
        .eq("user_id", user.id)
        .eq("course_id", course.id)
        .maybeSingle(),
    ]);

    if (enrollmentResult.error) {
      throw new Error("Your course enrolment could not be checked. Please refresh.");
    }
    if (badgeResult.error) {
      throw new Error("Your course completion status could not be checked. Please refresh.");
    }

    isEnrolled = Boolean(enrollmentResult.data);
    learnerName =
      profileResult.data?.certificate_display_name?.trim() ||
      profileResult.data?.full_name ||
      (typeof user.user_metadata?.full_name === "string" ? user.user_metadata.full_name : "") ||
      user.email?.split("@")[0] ||
      "Kaizora Learner";
    completionBadge = badgeResult.data;
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
    module_goal: row.module_goal,
  }])).values()].map((module) => ({
    ...module,
    lessons: previewRows.filter((row) => row.module_number === module.module_number),
  }));

  const category = course.course_categories?.[0]?.name ?? "Kaizora course";
  const duration = course.estimated_minutes > 0
    ? `${Math.round((course.estimated_minutes / 60) * 10) / 10} hours`
    : "Self-paced";
  const pricingLabel = course.access_type === "free"
    ? "Free course"
    : course.access_type === "paid"
      ? "Paid course · price to be confirmed"
      : "Pricing to be confirmed";

  return (
    <main>
      <CourseDetailAnalytics courseSlug={course.slug} courseTitle={course.title} category={category} />
      <header className="site-header">
        <Brand />
        {user ? <LearnerNavigation /> : <nav aria-label="Main navigation"><Link href="/courses">All courses</Link><Link href="/login">Log in</Link></nav>}
      </header>
      <section className="course-detail-hero">
        <Link className="course-back-link" href="/courses">← Back to all courses</Link>
        <p className="eyebrow">{category.toUpperCase()}</p>
        <h1>{course.title}</h1>
        <p className="course-detail-summary">{course.summary || course.description}</p>
        <div className="course-detail-meta"><span>{duration}</span><span>{course.difficulty.replace("_", " ")}</span><span>{pricingLabel}</span></div>
      </section>
      <section className="course-detail-body">
        <div><p className="eyebrow">ABOUT THIS COURSE</p><h2>Build knowledge you can <span>put to work.</span></h2><p>{course.description || course.summary}</p></div>
      </section>
      {completionBadge && user && (
        <section className="course-preview-section" aria-labelledby="course-badge-heading">
          <div className="course-preview-heading">
            <p className="eyebrow">COURSE COMPLETE</p>
            <h2 id="course-badge-heading">Your achievement.</h2>
            <p>You completed this course. Your personalised Badge of Completion is ready below.</p>
          </div>
          <CourseCompletionBadge
            learnerName={learnerName}
            courseTitle={completionBadge.course_title || course.title}
            issuedAt={completionBadge.issued_at}
          />
          <p><Link className="text-link" href="/badges">View all your badges →</Link></p>
        </section>
      )}
      <section className="course-preview-section">
        <div className="course-preview-heading">
          <p className="eyebrow">COURSE PREVIEW</p>
          <h2>See what you’ll <span>learn.</span></h2>
          <p>Review module and lesson titles, learning outcomes, and course access details before enrolling. Lesson content and assessments remain protected inside the learner experience.</p>
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
                  <p className="course-module-goal">{module.module_goal}</p>
                  {module.lessons.length > 0 && (
                    <ol className="course-module-lesson-titles">
                      {module.lessons.map((lesson) => (
                        <li key={lesson.lesson_number}>{lesson.lesson_number}. {lesson.lesson_title}</li>
                      ))}
                    </ol>
                  )}
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
      <section className="course-enrolment-footer" aria-labelledby="course-enrolment-heading">
        <aside>
          <div>
            <p className="eyebrow">YOUR NEXT STEP</p>
            <h2 id="course-enrolment-heading">{isEnrolled ? "Ready to continue?" : "Ready to begin?"}</h2>
            <p>{isEnrolled ? "Your learning progress is saved. Continue from your learner dashboard whenever you're ready." : "You've seen the course overview and curriculum. Enrol when you're ready to start learning."}</p>
          </div>
          {isEnrolled ? (
            <div className="course-enrolment-actions">
              <Link className="button button-primary" href="/dashboard">Continue learning <span>→</span></Link>
              <UnenrollButton courseTitle={course.title} courseSlug={course.slug} action={withdrawFromCourseAction} />
            </div>
          ) : (
            <div className="course-enrolment-actions">
              {course.access_type === "free" ? (
                <>
                  <form action={enrollInCourseAction}>
                    <input type="hidden" name="courseSlug" value={course.slug} />
                    <button className="button button-primary" type="submit">Enrol and start learning <span>→</span></button>
                  </form>
                  <p className="course-signup-note">New to Kaizora? <Link href="/signup">Create your learner account</Link>.</p>
                </>
              ) : (
                <p className="course-signup-note" role="status">
                  {course.access_type === "paid"
                    ? "This is a paid course. Enrolment will open after secure checkout is available."
                    : "Course pricing is still being confirmed. Enrolment is temporarily unavailable."}
                  {" "}New to Kaizora? <Link href="/signup">Create your learner account</Link>.
                </p>
              )}
            </div>
          )}
        </aside>
      </section>
      <footer className="site-footer"><Brand className="footer-brand" /><p>Learn. Build. Apply.</p><span>© {new Date().getFullYear()} Kaizora AI Academy</span></footer>
    </main>
  );
}
