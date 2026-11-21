import Link from "next/link";
import { getPublishedCatalogue } from "@/lib/courses/catalogue";
import { Brand } from "@/components/brand";

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
        <nav aria-label="Main navigation">
          <Link href="/">Home</Link>
          <Link href="/about">About</Link>
          <Link href="/learners">Learners</Link>
          <Link href="/institutes">Institutes</Link>
          <Link href="/organisations">Organisations</Link>
        </nav>
        <Link className="header-link" href="/learners">For learners <span>↗</span></Link>
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
            <p>The course catalogue is temporarily unavailable. You can still explore Kaizora and its public information pages while we restore the learning service.</p>
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
              <span>{catalogue.courses.length} published {catalogue.courses.length === 1 ? "course" : "courses"}</span>
            </div>
            {catalogue.categories.map((category) => {
              const courses = catalogue.courses.filter((course) => course.category_id === category.id);
              if (courses.length === 0) return null;
              return (
                <section className="catalogue-category" key={category.id}>
                  <div className="catalogue-category-heading">
                    <div><h3>{category.name}</h3><p>{category.description}</p></div>
                    <span>{courses.length} {courses.length === 1 ? "course" : "courses"}</span>
                  </div>
                  <div className="published-course-grid">
                    {courses.map((course) => (
                      <article className="published-course-card" key={course.id}>
                        <p className="course-card-category">{category.name}</p>
                        <h4>{course.title}</h4>
                        <p className="course-card-summary">{course.summary || course.description}</p>
                        <div className="course-card-meta">
                          <span>{formatDuration(course.estimated_minutes)}</span>
                          <span>{course.difficulty.replace("_", " ")}</span>
                        </div>
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

      <footer className="site-footer">
        <Brand className="footer-brand" />
        <p>Learn. Build. Apply.</p>
        <span>© {new Date().getFullYear()} Kaizora AI Academy</span>
      </footer>
    </main>
  );
}
