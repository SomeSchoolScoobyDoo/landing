import type { Metadata } from "next";
import { AudiencePage } from "@/components/marketing-shell";
export const metadata: Metadata = { title: "Workforce Learning for Organisations | Kaizora AI Academy", description: "Discover Kaizora's approach to practical workforce learning, team development and technology upskilling for organisations." };
export default function OrganisationsPage() {
  return <AudiencePage
    eyebrow="FOR BUSINESSES & ORGANISATIONS"
    title="Make learning part of how your team"
    accent="grows."
    description="Technology changes quickly. Kaizora's organisational learning direction is designed to help teams develop practical skills, coordinate learning and connect development with the work they do."
    features={[
      { number: "01", title: "Team learning", description: "Give teams a more organised route into relevant technology learning and professional development." },
      { number: "02", title: "Practical upskilling", description: "Focus on useful skills in AI, automation, software, cybersecurity and emerging technology." },
      { number: "03", title: "Learning visibility", description: "Build towards clearer oversight of participation and progress across teams and departments." },
      { number: "04", title: "Skills with context", description: "Connect learning to practical work, responsible use of technology and real organisational needs." },
    ]}
    steps={[
      { title: "Identify the skills", description: "Start with the capabilities your people and teams need to develop." },
      { title: "Create a learning route", description: "Match learning opportunities to roles, goals and current experience." },
      { title: "Support development", description: "Encourage practical application and review progress as skills grow." },
    ]}
    cta="View organisation workspace preview" href="/preview/organisation"
    note="The organisation workspace is currently a product preview. Live organisation onboarding is not yet open."
  />;
}
