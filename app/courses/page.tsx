import Link from "next/link";
import { getPublishedCatalogue } from "@/lib/courses/catalogue";
import { MarketingShell } from "@/components/marketing-shell";

export const metadata = {
  title: "Explore Technology Courses | Kaizora AI Academy",
  description: "Explore practical courses in AI, automation, software, cybersecurity and emerging technology at Kaizora AI Academy.",
};

function formatDuration(minutes: number) {
  if (minutes <= 0) return "Self-paced";
  const hours = Math.round((minutes / 60) * 10) / 10;
  return hours === 1 ? "1 hour" : `${hours} hours`;
}

export default async function CoursesPage() {
  let catalogue;
  try {
    catalogue = await getPublishedCatalogue();
  } catch {
    catalogue = null;
  }

  return (
    <MarketingShell>
      <main className="catalogue-page">
        <section className="catalogue-hero">
          <p className="marketing-eyebrow">KAIZORA AI ACADEMY · COURSE CATALOGUE</p>
          <h1>Choose what you want to <em>learn next.</em></h1>
          <p>Independent, practical courses designed to help you build skills and apply them in the real world. Start with the subject that matters to you.</p>
          <div className="catalogue-topics"><span>Artificial intelligence</span><span>Automation</span><span>Software</span><span>Cybersecurity</span><span>Emerging technology</span></div>
        </section>

        <section className="catalogue-live" aria-live="polite">
          {!catalogue ? (
            <div className="catalogue-empty">
              <span className="catalogue-status">LEARNING SERVICE</span>
              <h2>The course catalogue is taking a breather.</h2>
              <p>The public Kaizora website is still available. The learning service is temporarily unavailable, so published courses cannot be loaded right now. Please check back shortly.</p>
              <Link className="marketing-text-link" href="/about">Learn about Kaizora in the meantime →</Link>
            </div>
          ) : catalogue.courses.length === 0 ? (
            <div className="catalogue-empty">
              <span className="catalogue-status">NEW COURSES IN PREPARATION</span>
              <h2>A fresh catalogue is on the way.</h2>
              <p>There are no published courses yet. New courses will appear here after they have been imported, reviewed and published.</p>
              <p className="catalogue-muted">The catalogue will grow as new learning material is prepared.</p>
            </div>
          ) : (
            <div className="catalogue-results">
              <div className="catalogue-results-heading">
                <div><p className="marketing-eyebrow">READY WHEN YOU ARE</p><h2>Explore the courses.</h2></div>
                <span>{catalogue.courses.length} published {catalogue.courses.length === 1 ? "course" : "courses"}</span>
              </div>
              {catalogue.categories.map((category) => {
                const courses = catalogue.courses.filter((course) => course.category_id === category.id);
                if (courses.length === 0) return null;
                return (
                  <section className="catalogue-category" key={category.id}>
                    <div className="catalogue-category-heading"><div><h3>{category.name}</h3><p>{category.description}</p></div><span>{courses.length} {courses.length === 1 ? "course" : "courses"}</span></div>
                    <div className="published-course-grid">
                      {courses.map((course) => (
                        <article className="published-course-card" key={course.id}>
                          <p className="course-card-category">{category.name}</p>
                          <h4>{course.title}</h4>
                          <p className="course-card-summary">{course.summary || course.description}</p>
                          <div className="course-card-meta"><span>{formatDuration(course.estimated_minutes)}</span><span>{course.difficulty.replace("_", " ")}</span></div>
                          <Link href={`/courses/${course.slug}`}>View course <span aria-hidden="true">→</span></Link>
                        </article>
                      ))}
                    </div>
                  </section>
                );
              })}
            </div>
          )}
        </section>
        <section className="catalogue-bottom"><p>Learning is a process, not a race.</p><Link className="marketing-text-link" href="/learners">See how the learner experience works →</Link></section>
      </main>
    </MarketingShell>
  );
}
