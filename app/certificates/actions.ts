"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { emailCertificate } from "@/lib/certificates/email";

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const CERTIFICATE_PATTERN = /^KZA-[A-F0-9]{20}$/i;

export async function issueCertificateAction(formData: FormData) {
  const courseId = String(formData.get("courseId") ?? "");
  if (!UUID_PATTERN.test(courseId)) {
    throw new Error("A valid course is required.");
  }

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/login");

  const { error } = await supabase.rpc("issue_course_certificate", {
    p_course_id: courseId,
  });

  if (error) {
    throw new Error(error.message || "Certificate eligibility could not be verified.");
  }

  revalidatePath("/certificates");
  revalidatePath("/dashboard");
  redirect("/certificates?issued=1");
}

export async function emailCertificateAction(formData: FormData) {
  const certificateNumber = String(formData.get("certificateNumber") ?? "").toUpperCase();
  if (!CERTIFICATE_PATTERN.test(certificateNumber)) {
    throw new Error("A valid certificate number is required.");
  }

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/login");
  if (!authData.user.email) {
    redirect("/certificates?email=no-address");
  }
  if (!authData.user.email_confirmed_at) {
    redirect("/certificates?email=unverified");
  }

  const { data: certificate, error } = await supabase
    .from("course_certificates")
    .select("id, certificate_number, learner_name_snapshot, course_title_snapshot, certificate_title, recognition_text, signatory_name, signatory_title, institution_name, issued_at, status")
    .eq("certificate_number", certificateNumber)
    .eq("user_id", authData.user.id)
    .maybeSingle();

  if (error || !certificate) {
    throw new Error("This certificate could not be found in your account.");
  }

  const status = await emailCertificate({
    certificate,
    userId: authData.user.id,
    recipientEmail: authData.user.email,
  });

  revalidatePath("/certificates");
  redirect(`/certificates?email=${status}`);
}
