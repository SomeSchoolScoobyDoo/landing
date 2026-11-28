import "server-only";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";

export type EagleEyeOverview = {
  registeredUsers: number;
  newUsersToday: number;
  activeEnrolments: number;
  publishedCourses: number;
  completedLessons: number;
  assessmentAttempts: number;
  betaTesters: {
    id: string;
    fullName: string;
    testerStatus: string;
    certificateStatus: string;
    createdAt: string;
  }[];
};

export async function getEagleEyeOverview(userId: string): Promise<{
  data: EagleEyeOverview | null;
  configured: boolean;
  authorized: boolean;
}> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceRoleKey) return { data: null, configured: false, authorized: false };

  const supabase = createSupabaseClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: adminRecord, error: adminError } = await supabase
    .schema("private")
    .from("academy_admins")
    .select("user_id")
    .eq("user_id", userId)
    .maybeSingle();
  if (adminError || !adminRecord) return { data: null, configured: true, authorized: false };
  const startOfDay = new Date();
  startOfDay.setUTCHours(0, 0, 0, 0);
  const since = startOfDay.toISOString();

  const [users, newUsers, enrolments, courses, lessons, assessments, testers] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase.from("profiles").select("id", { count: "exact", head: true }).gte("created_at", since),
    supabase.from("course_enrollments").select("id", { count: "exact", head: true }).eq("status", "active"),
    supabase.from("courses").select("id", { count: "exact", head: true }).eq("status", "published"),
    supabase.from("lesson_progress").select("id", { count: "exact", head: true }).not("completed_at", "is", null),
    supabase.from("assessment_attempts").select("id", { count: "exact", head: true }),
    supabase.from("beta_testers").select("id, full_name, tester_status, certificate_status, created_at").order("created_at", { ascending: false }),
  ]);

  if ([users, newUsers, enrolments, courses, lessons, assessments, testers].some((result) => result.error)) {
    return { data: null, configured: true, authorized: true };
  }

  return {
    configured: true,
    authorized: true,
    data: {
      registeredUsers: users.count ?? 0,
      newUsersToday: newUsers.count ?? 0,
      activeEnrolments: enrolments.count ?? 0,
      publishedCourses: courses.count ?? 0,
      completedLessons: lessons.count ?? 0,
      assessmentAttempts: assessments.count ?? 0,
      betaTesters: (testers.data ?? []).map((tester) => ({
        id: tester.id,
        fullName: tester.full_name,
        testerStatus: tester.tester_status,
        certificateStatus: tester.certificate_status,
        createdAt: tester.created_at,
      })),
    },
  };
}
