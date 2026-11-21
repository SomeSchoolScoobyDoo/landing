import type { Metadata } from "next";
import Link from "next/link";
import { MarketingShell } from "@/components/marketing-shell";
export const metadata: Metadata = { title: "About Kaizora AI Academy | Practical Technology Education", description: "Learn about Kaizora AI Academy's practical approach to technology education, independent learning and applied skills." };
const principles = [
  ["01", "Understand before you automate", "Tools are useful, but understanding the problem and the system behind it is what makes the work dependable."],
  ["02", "Practice is part of learning", "Exercises, experiments and assessments help turn information into something a learner can actually use."],
  ["03", "Question the output", "Verification, security, responsible AI use and human judgement belong in modern technology education."],
  ["04", "Build beyond the lesson", "Learning should give people a foundation they can extend into projects, work and further study."],
];
export default function AboutPage() {
  return <MarketingShell><main className="about-page">
    <section className="about-hero"><p className="marketing-eyebrow">ABOUT KAIZORA AI ACADEMY</p><h1>Technology education should create <em>capability.</em></h1><p>Kaizora AI Academy is built around a simple idea: learning should help people understand technology, work with it thoughtfully and build things they can explain.</p><Link className="marketing-button" href="/courses">Explore courses <span aria-hidden="true">→</span></Link></section>
    <section className="about-statement"><p className="marketing-eyebrow">OUR POINT OF VIEW</p><h2>Not just more information. <em>More ability.</em></h2><p>There is no shortage of tutorials, tools or content. The harder part is knowing what matters, testing what you learn and applying it to a real problem. That is the experience Kaizora is being shaped to support.</p></section>
    <section className="about-principles"><div><p className="marketing-eyebrow">THE PRINCIPLES</p><h2>How we think about <em>learning.</em></h2></div><div className="about-principle-list">{principles.map(([number,title,copy])=><article key={number}><span>{number}</span><div><h3>{title}</h3><p>{copy}</p></div></article>)}</div></section>
    <section className="about-bottom"><div><p className="marketing-eyebrow">MAKE YOUR NEXT MOVE</p><h2>Find a subject worth <em>getting good at.</em></h2><p>Explore the catalogue and choose a practical place to begin.</p></div><Link className="marketing-button" href="/courses">Browse courses <span aria-hidden="true">→</span></Link></section>
  </main></MarketingShell>;
}
