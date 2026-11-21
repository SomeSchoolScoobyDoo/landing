import type { Metadata } from "next";
import { AudiencePage } from "@/components/marketing-shell";
export const metadata: Metadata = { title: "Learning for Institutes | Kaizora AI Academy", description: "Explore how Kaizora can support institutes with structured digital learning, programme organisation and learner progress visibility." };
export default function InstitutesPage() {
  return <AudiencePage
    eyebrow="FOR SCHOOLS, TRAINING CENTRES & INSTITUTES"
    title="Give structured learning a"
    accent="place."
    description="Kaizora's institute direction is designed for education providers that want a clearer way to organise digital learning, support instructors and keep track of learner participation."
    features={[
      { number: "01", title: "Programme organisation", description: "Bring learning programmes and participating learners into a more structured digital environment." },
      { number: "02", title: "Instructor support", description: "Create room for instructors and coordinators to guide learning and support learners through their programmes." },
      { number: "03", title: "Learner visibility", description: "Work towards a clearer picture of participation, progress and learning activity across a cohort." },
      { number: "04", title: "Practical curriculum", description: "Connect course material with exercises and assessments that encourage learners to apply what they study." },
    ]}
    steps={[
      { title: "Set up the learning programme", description: "Define the programme, its learners and the learning outcomes." },
      { title: "Guide participation", description: "Support learners as they work through course material and practical activities." },
      { title: "Review learning activity", description: "Use programme-level visibility to understand participation and areas that need support." },
    ]}
    cta="View institute workspace preview" href="/preview/institute"
    note="The institute workspace is currently a product preview. Organisation accounts and live institute onboarding are not yet open."
  />;
}
