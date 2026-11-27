import Link from "next/link";
import { getPublishedCatalogue } from "@/lib/courses/catalogue";
import { Brand } from "@/components/brand";
import { LearnerNavigation } from "@/components/learner-navigation";
import { createClient } from "@/lib/supabase/server";
import { TrackedCourseLink } from "@/components/tracked-course-link";

export const metadata = {
  title: "Explore Courses | Kaizora AI Academy",
  description:
    "Explore independent, practical courses in AI, automation, software, cybersecurity and emerging technology.",
};

function formatDuration(minutes: number) {
  if (minutes <= 0) return "Self-paced";
  const hours = Math.round((minutes / 60) * 10) / 10;
  return hours === 1 ? "1 hour" : `${hours} hours`;
}

export default async function CoursesPage() {
  const user = process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    ? (await (async () => {
        const supabase = await createClient();
        const { data: auth } = await supabase.auth.getUser();
        return auth.user;
      })())
    : null;
  let catalogue;
  try {
    catalogue = await getPublishedCatalogue();
  } catch {
    catalogue = null;
  }

  return (
    <main>
      <header className="site-header">
        <Brand />
        {user ? <LearnerNavigation /> : <nav aria-label="Main navigation"><Link href="/">Home</Link><Link href="/login">Log in</Link></nav>}
      </header>

      <section className="catalogue-hero">
        <p className="eyebrow">KAIZORA AI ACADEMY · COURSE CATALOGUE</p>
        <h1>Choose what you want to <span>learn next.</span></h1>
        <p>Independent, practical courses designed to help you build skills and apply them in the real world. There is no compulsory course order.</p>
      </section>

      <section className="catalogue-live section-wrap" aria-live="polite">
        {!catalogue ? (
          <div className="catalogue-empty">
            <h2>Catalogue setup in progress</h2>
            <p>The course content is ready. This development preview still needs its database connection before it can load the published catalogue.</p>
          </div>
        ) : catalogue.courses.length === 0 ? (
          <div className="catalogue-empty">
            <h2>Courses are being prepared.</h2>
            <p>There are no published courses yet. New courses will appear here after they have been imported, reviewed and published.</p>
          </div>
        ) : (
          <div className="catalogue-results">
            <div className="catalogue-results-heading">
              <div><p className="eyebrow">READY WHEN YOU ARE</p><h2>Explore the courses.</h2></div>
              <span>{catalogue.availableCount} available · {catalogue.courses.length - catalogue.availableCount} coming soon · {catalogue.courses.length} total</span>
            </div>
            {catalogue.categories.map((category) => {
              const courses = catalogue.courses.filter((course) => course.category === category.name);
              if (courses.length === 0) return null;
              return (
                <section className="catalogue-category" key={category.id}>
                  <div className="catalogue-category-heading">
                    <div><h3>{category.name}</h3><p>{category.description}</p></div>
                    <span>{courses.length} {courses.length === 1 ? "course" : "courses"}</span>
                  </div>
                  <div className="published-course-grid">
                    {courses.map((course) => (
                      <article className="published-course-card" key={course.course_id}>
                        <div className="course-card-topline">
                          <p className="course-card-category">{category.name}</p>
                          {course.status === "coming_soon" ? (
                            <span className="course-status-badge coming-soon">Coming soon</span>
                          ) : (
                            <span className="course-status-badge available">Available</span>
                          )}
                        </div>
                        <h4>{course.title}</h4>
                        <p className="course-card-summary">{course.course?.summary || course.course?.description || course.summary}</p>
                        <div className="course-card-meta">
                          {course.course ? <span>{formatDuration(course.course.estimated_minutes)}</span> : <span>Course in preparation</span>}
                          <span>{course.level}</span>
                          {course.course ? (
                            <span>{course.course.access_type === "free" ? "Free" : course.course.access_type === "paid" ? "Paid · Price to be confirmed" : "Pricing to be confirmed"}</span>
                          ) : (
                            <span>Details to be announced</span>
                          )}
                        </div>
                        {course.status === "available" && course.course ? (
                          <TrackedCourseLink
                            href={`/courses/${course.slug}`}
                            courseSlug={course.slug}
                            courseTitle={course.title}
                            sourceComponent="published_course_card"
                            placement={category.name}
                          >
                            View course <span aria-hidden="true">→</span>
                          </TrackedCourseLink>
                        ) : (
                          <span className="course-coming-soon-note">We’re preparing this learning path.</span>
                        )}
                      </article>
                    ))}
                  </div>
                </section>
              );
            })}
          </div>
        )}
      </section>

      <footer className="site-footer">
        <Brand className="footer-brand" />
        <p>Learn. Build. Apply.</p>
        <span>© {new Date().getFullYear()} Kaizora AI Academy</span>
      </footer>
    </main>
  );
}
