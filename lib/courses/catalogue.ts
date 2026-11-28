import "server-only";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { getSupabasePublicEnv } from "@/lib/supabase/env";

export type PublishedCourseCategory = {
  id: string;
  slug: string;
  name: string;
  description: string;
  display_order: number;
};

export type PublishedCourse = {
  id: string;
  category_id: string;
  slug: string;
  title: string;
  summary: string;
  description: string;
  difficulty: "beginner" | "intermediate" | "advanced" | "all_levels";
  estimated_minutes: number;
  access_type: "free" | "paid" | "unconfigured";
  display_order: number;
  published_at: string | null;
  course_categories: PublishedCourseCategory[] | null;
};

export type CatalogueEntry = {
  course_id: string;
  slug: string;
  title: string;
  category: string;
  level: "Beginner" | "Intermediate" | "Advanced";
  summary: string;
  plannedAccess: "free" | "paid";
  award: "Digital Badge" | "Certificate";
  status: "available" | "coming_soon";
  course: PublishedCourse | null;
};

const catalogueDefinition: Array<Omit<CatalogueEntry, "status" | "course">> = [
  { course_id: "S1", slug: "computer-and-internet-readiness", title: "Computer and Internet Readiness", category: "Setup Courses", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Build the basic computer, internet and digital skills needed to learn confidently online." },
  { course_id: "S2", slug: "ai-toolkit-setup", title: "AI Toolkit Setup", category: "Setup Courses", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Set up and get comfortable with the essential tools used throughout the academy." },
  { course_id: "S3", slug: "developer-environment-setup", title: "Developer Environment Setup", category: "Setup Courses", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Prepare a reliable development environment for practical software and technical learning." },
  { course_id: "S4", slug: "automation-lab-setup", title: "Automation Lab Setup", category: "Setup Courses", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Prepare the accounts, tools and workspace needed for hands-on automation projects." },

  { course_id: "C01", slug: "introduction-to-artificial-intelligence", title: "Introduction to Artificial Intelligence", category: "AI Foundations", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Understand what AI is, where it is used and how modern AI systems work." },
  { course_id: "C02", slug: "prompt-engineering-and-ai-interaction", title: "Prompt Engineering and AI Interaction", category: "AI Foundations", level: "Intermediate", plannedAccess: "free", award: "Certificate", summary: "Learn to communicate with AI systems and design useful, reliable prompts." },
  { course_id: "C03", slug: "ai-research-and-productivity", title: "AI Research and Productivity", category: "AI Foundations", level: "Intermediate", plannedAccess: "free", award: "Certificate", summary: "Use AI tools to research, organise information and improve everyday productivity." },
  { course_id: "C04", slug: "responsible-ai-and-ai-safety", title: "Responsible AI and AI Safety", category: "AI Foundations", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Explore responsible AI use, limitations, safety, privacy and evaluation." },

  { course_id: "C05", slug: "ai-marketing-and-creative-production", title: "AI Marketing and Creative Production", category: "AI Content and Creativity", level: "Intermediate", plannedAccess: "free", award: "Certificate", summary: "Apply AI tools to marketing workflows and creative production." },
  { course_id: "C06", slug: "ai-branding-and-design", title: "AI Branding and Design", category: "AI Content and Creativity", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Develop brand concepts and visual assets with AI-assisted design workflows." },
  { course_id: "C07", slug: "ai-powered-content-creation-and-video-production", title: "AI-Powered Content Creation and Video Production", category: "AI Content and Creativity", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Plan, create and refine digital content and video with AI tools." },

  { course_id: "C08", slug: "workflow-and-business-process-automation", title: "Workflow and Business Process Automation", category: "Automation and Business Applications", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Map repetitive work and build workflows that reduce manual operations." },
  { course_id: "C09", slug: "apis-and-webhooks-for-automation", title: "APIs and Webhooks for Automation", category: "Automation and Business Applications", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Connect software services using APIs, webhooks and practical integrations." },
  { course_id: "C10", slug: "ai-automation-for-business", title: "AI Automation for Business", category: "Automation and Business Applications", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Design useful AI-powered workflows for real business operations." },
  { course_id: "C11", slug: "ai-for-business-management", title: "AI for Business Management", category: "Automation and Business Applications", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Use AI to support planning, operations, reporting and business decisions." },
  { course_id: "C12", slug: "building-ai-agents", title: "Building AI Agents", category: "Automation and Business Applications", level: "Advanced", plannedAccess: "paid", award: "Certificate", summary: "Design agent workflows that can reason through tasks and use approved tools." },
  { course_id: "C13", slug: "rag-and-vector-databases", title: "RAG and Vector Databases", category: "Automation and Business Applications", level: "Advanced", plannedAccess: "paid", award: "Certificate", summary: "Build retrieval-augmented systems using embeddings and vector search." },
  { course_id: "C14", slug: "chatbots-and-customer-support-bots", title: "Chatbots and Customer Support Bots", category: "Automation and Business Applications", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Create conversational support experiences for common customer needs." },
  { course_id: "C15", slug: "ai-for-spreadsheets-and-finance", title: "AI for Spreadsheets and Finance", category: "Automation and Business Applications", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Use AI and spreadsheet automation to support financial and operational work." },

  { course_id: "C16", slug: "web-development-fundamentals", title: "Web Development Fundamentals", category: "Software and Development", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Learn the core concepts behind building and publishing modern websites." },
  { course_id: "C17", slug: "ai-assisted-application-development", title: "AI-Assisted Application Development", category: "Software and Development", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Use AI coding tools responsibly to plan, build and test applications." },
  { course_id: "C18", slug: "database-fundamentals", title: "Database Fundamentals", category: "Software and Development", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Understand data modelling, SQL and the foundations of database-backed apps." },
  { course_id: "C19", slug: "vibe-coding", title: "Vibe Coding", category: "Software and Development", level: "Intermediate", plannedAccess: "free", award: "Digital Badge", summary: "Turn ideas into working software through structured AI-assisted building." },

  { course_id: "C20", slug: "data-literacy", title: "Data Literacy", category: "Data and Programming", level: "Beginner", plannedAccess: "free", award: "Digital Badge", summary: "Learn to read, question, interpret and communicate data." },
  { course_id: "C21", slug: "python-programming", title: "Python Programming", category: "Data and Programming", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Build programming foundations with Python through practical exercises." },
  { course_id: "C22", slug: "data-analysis-with-ai", title: "Data Analysis with AI", category: "Data and Programming", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Explore datasets and communicate findings with AI-assisted analysis." },

  { course_id: "C23", slug: "cybersecurity-fundamentals", title: "Cybersecurity Fundamentals", category: "Cybersecurity and Secure Development", level: "Beginner", plannedAccess: "paid", award: "Certificate", summary: "Understand core security concepts, common threats and defensive practices." },
  { course_id: "C24", slug: "introduction-to-devsecops", title: "Introduction to DevSecOps", category: "Cybersecurity and Secure Development", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Integrate security checks and secure practices into software delivery." },
  { course_id: "C25", slug: "ai-security", title: "AI Security", category: "Cybersecurity and Secure Development", level: "Advanced", plannedAccess: "paid", award: "Certificate", summary: "Study the security risks and defensive controls of AI-powered systems." },

  { course_id: "C26", slug: "robotics-and-intelligent-systems", title: "Robotics and Intelligent Systems", category: "Emerging Technology", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Explore robotics, sensing, control and intelligent system design." },
  { course_id: "C27", slug: "voice-ai", title: "Voice AI", category: "Emerging Technology", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Understand speech interfaces and build voice-enabled AI experiences." },

  { course_id: "C28", slug: "freelancing-and-careers-with-ai", title: "Freelancing and Careers with AI", category: "Career and Specialised Tracks", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Explore practical career paths, freelance services and AI-enabled work." },
  { course_id: "C29", slug: "ai-for-teachers-and-trainers", title: "AI for Teachers and Trainers", category: "Career and Specialised Tracks", level: "Intermediate", plannedAccess: "paid", award: "Certificate", summary: "Apply AI tools to lesson planning, teaching materials and learning support." },

  { course_id: "C30", slug: "machine-learning-with-python", title: "Machine Learning with Python", category: "Advanced AI Engineering", level: "Advanced", plannedAccess: "paid", award: "Certificate", summary: "Build an applied foundation in machine learning with Python." },
  { course_id: "C31", slug: "deep-learning-and-neural-networks", title: "Deep Learning and Neural Networks", category: "Advanced AI Engineering", level: "Advanced", plannedAccess: "paid", award: "Certificate", summary: "Explore neural networks and the foundations of deep learning." },
  { course_id: "C32", slug: "llm-engineering", title: "LLM Engineering", category: "Advanced AI Engineering", level: "Advanced", plannedAccess: "paid", award: "Certificate", summary: "Explore the architecture, evaluation and practical engineering of large language models." },
];

function createPublicCatalogueClient() {
  const { url, key } = getSupabasePublicEnv();
  return createSupabaseClient(url, key, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

export async function getPublishedCatalogue() {
  let published: PublishedCourse[] = [];
  try {
    const supabase = createPublicCatalogueClient();
    const { data, error } = await supabase
      .from("courses")
      .select("id, category_id, slug, title, summary, description, difficulty, estimated_minutes, access_type, display_order, published_at, course_categories(id, slug, name, description, display_order)")
      .eq("status", "published")
      .order("display_order", { ascending: true })
      .order("title", { ascending: true });

    if (!error) published = (data ?? []) as PublishedCourse[];
  } catch {
    // Keep the planned catalogue visible during a temporary database/configuration outage.
    // Without a confirmed published database record, a course remains marked Coming soon.
  }
  const bySlug = new Map(published.map((course) => [course.slug, course]));
  const entries: CatalogueEntry[] = catalogueDefinition.map((entry) => {
    const course = bySlug.get(entry.slug) ?? null;
    return {
      ...entry,
      course,
      status: course ? "available" : "coming_soon",
    };
  });

  const categories: PublishedCourseCategory[] = [...new Set(catalogueDefinition.map((entry) => entry.category))]
    .map((name, index) => ({
      id: name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""),
      slug: name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""),
      name,
      description: name === "Setup Courses"
        ? "Get your learning environment ready before diving into the main tracks."
        : `Practical learning paths in ${name.toLowerCase()}.`,
      display_order: index + 1,
    }));

  return { categories, courses: entries, availableCount: entries.filter((entry) => entry.status === "available").length };
}

export async function getPublishedCourseBySlug(slug: string) {
  const supabase = createPublicCatalogueClient();
  const { data, error } = await supabase
    .from("courses")
    .select("id, category_id, slug, title, summary, description, difficulty, estimated_minutes, access_type, display_order, published_at, course_categories(id, slug, name, description, display_order)")
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (error) throw new Error("The course could not be loaded.");
  return (data as PublishedCourse | null) ?? null;
}

export type PublicCoursePreviewRow = {
  course_title: string;
  course_summary: string;
  course_description: string;
  difficulty: PublishedCourse["difficulty"];
  estimated_minutes: number;
  access_type: PublishedCourse["access_type"];
  module_number: number;
  module_title: string;
  module_goal: string;
  lesson_number: string;
  lesson_title: string;
};

export async function getPublicCoursePreview(slug: string) {
  const supabase = createPublicCatalogueClient();
  const { data, error } = await supabase.rpc("get_public_course_lesson_title_preview", {
    p_course_slug: slug,
  });

  if (error) throw new Error("The course preview is temporarily unavailable.");
  return (data ?? []) as PublicCoursePreviewRow[];
}
