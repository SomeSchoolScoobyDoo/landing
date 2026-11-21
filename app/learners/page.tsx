import type { Metadata } from "next";
import { AudiencePage } from "@/components/marketing-shell";
export const metadata: Metadata = { title: "Learn with Kaizora | Courses for Independent Learners", description: "Learn at your own pace with practical technology courses, structured lessons, exercises and progress tracking at Kaizora AI Academy." , alternates: { canonical: "/learners" } };
export default function LearnersPage() {
  return <AudiencePage
    eyebrow="FOR INDEPENDENT LEARNERS"
    title="Build skills that move with"
    accent="you."
    description="Take ownership of what you learn. Explore practical technology courses, work through structured lessons and use exercises to turn new ideas into skills you can explain."
    features={[
      { number: "01", title: "Choose your direction", description: "Explore courses across AI, automation, software, cybersecurity and emerging technology as the catalogue grows." },
      { number: "02", title: "Learn with structure", description: "Follow organised lessons and course material designed to make complex ideas easier to work through." },
      { number: "03", title: "Put ideas to work", description: "Use practical exercises and assessments to check your understanding, not just your ability to watch a lesson." },
      { number: "04", title: "Keep your progress visible", description: "Return to your learner space to follow enrolments, completed work and what comes next." },
    ]}
    steps={[
      { title: "Find a course", description: "Start with a subject or skill you want to develop." },
      { title: "Work through the material", description: "Learn the concepts, practise and check your understanding." },
      { title: "Build from what you know", description: "Use your growing knowledge as a foundation for projects and further learning." },
    ]}
    cta="Explore available courses" href="/courses"
    note="Course availability depends on what has been reviewed and published in the catalogue."
  />;
}
