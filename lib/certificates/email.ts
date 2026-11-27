import "server-only";

import { createAdminClient } from "@/lib/supabase/admin";
import { CertificateTemplateNotReadyError, renderCertificatePdf } from "@/lib/certificates/pdf";
import { getCertificateEmailAttemptCount, sendCertificateEmailRequest } from "@/lib/certificates/email-delivery";

type EmailCertificateInput = {
  certificate: {
    id: string;
    certificate_number: string;
    learner_name_snapshot: string;
    course_title_snapshot: string;
    certificate_title: string;
    recognition_text: string;
    signatory_name: string;
    signatory_title: string;
    institution_name: string;
    issued_at: string;
    status: string;
  };
  userId: string;
  recipientEmail: string;
};

function escapeHtml(value: string) {
  return value.replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[char] ?? char);
}

export async function emailCertificate(input: EmailCertificateInput) {
  if (input.certificate.status !== "valid") {
    throw new Error("A revoked certificate cannot be emailed.");
  }

  const apiKey = process.env.RESEND_API_KEY;
  const from = process.env.CERTIFICATE_FROM_EMAIL;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "");

  let pdf: Buffer;
  try {
    pdf = await renderCertificatePdf(input.certificate);
  } catch (error) {
    if (error instanceof CertificateTemplateNotReadyError) {
      return "template_missing" as const;
    }
    throw error;
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return "not_configured" as const;
  }
  const admin = createAdminClient();
  if (!admin) return "not_configured" as const;

  const { data: existing, error: existingError } = await admin
    .from("certificate_email_deliveries")
    .select("id, attempt_count, status")
    .eq("certificate_id", input.certificate.id)
    .maybeSingle();

  if (existingError) {
    throw new Error("Certificate email delivery status could not be checked.");
  }

  // Reuse an in-flight attempt's key so concurrent clicks and network retries
  // cannot accidentally send the same certificate email twice.
  const attemptCount = getCertificateEmailAttemptCount(existing?.status, existing?.attempt_count);
  const baseRecord = {
    certificate_id: input.certificate.id,
    user_id: input.userId,
    recipient_email: input.recipientEmail,
    attempt_count: attemptCount,
    updated_at: new Date().toISOString(),
  };

  if (!apiKey || !from || !appUrl) {
    const { error: saveError } = await admin.from("certificate_email_deliveries").upsert({
      ...baseRecord,
      status: "not_configured",
      last_error: "RESEND_API_KEY, CERTIFICATE_FROM_EMAIL and NEXT_PUBLIC_APP_URL must be configured.",
    }, { onConflict: "certificate_id" });
    if (saveError) throw new Error("Email configuration status could not be recorded.");
    return "not_configured" as const;
  }

  const { error: pendingError } = await admin.from("certificate_email_deliveries").upsert({
    ...baseRecord,
    status: "pending",
    last_error: null,
    sent_at: null,
  }, { onConflict: "certificate_id" });
  if (pendingError) {
    throw new Error("Email delivery could not be recorded. No email was sent.");
  }

  const verifyUrl = `${appUrl}/verify/${encodeURIComponent(input.certificate.certificate_number)}`;
  const learner = escapeHtml(input.certificate.learner_name_snapshot);
  const course = escapeHtml(input.certificate.course_title_snapshot);

  const subject = `Your Kaizora AI Academy ${input.certificate.certificate_title}: ${input.certificate.course_title_snapshot}`;
  const certificateTitle = escapeHtml(input.certificate.certificate_title);
  const recognition = escapeHtml(input.certificate.recognition_text);
  const html = `<p>Hello ${learner},</p><p>Your <strong>${certificateTitle}</strong> for <strong>${course}</strong> is attached.</p><p>${recognition}</p><p>You can independently verify the credential here: <a href="${verifyUrl}">${verifyUrl}</a></p><p>Kaizora AI Academy</p>`;
  const result = await sendCertificateEmailRequest({
    apiKey,
    from,
    recipientEmail: input.recipientEmail,
    subject,
    html,
    certificateId: input.certificate.id,
    attemptCount,
    filename: `${input.certificate.certificate_number}.pdf`,
    pdfBase64: pdf.toString("base64"),
  });

  if (result.status === "sent") {
    const { error: sentError } = await admin.from("certificate_email_deliveries").upsert({
      ...baseRecord,
      status: "sent",
      last_error: null,
      sent_at: new Date().toISOString(),
    }, { onConflict: "certificate_id" });
    if (sentError) {
      // Resend accepted the message. Leave the pending attempt intact so a retry
      // reuses the same idempotency key instead of sending a duplicate.
      return "pending" as const;
    }
    return "sent" as const;
  }

  const { error: saveError } = await admin.from("certificate_email_deliveries").upsert({
    ...baseRecord,
    status: result.status,
    last_error: result.detail,
  }, { onConflict: "certificate_id" });
  if (saveError) {
    throw new Error("Email failure status could not be recorded.");
  }
  return result.status;
}
