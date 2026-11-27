import "server-only";

export type CertificateEmailRequestInput = {
  apiKey: string;
  from: string;
  recipientEmail: string;
  subject: string;
  html: string;
  certificateId: string;
  attemptCount: number;
  filename: string;
  pdfBase64: string;
};

export type CertificateEmailRequestResult = {
  status: "sent" | "pending" | "failed";
  detail: string | null;
};

export function getCertificateEmailAttemptCount(
  existingStatus: string | null | undefined,
  existingAttemptCount: number | null | undefined,
) {
  if (existingStatus === "pending") {
    return Math.max(1, existingAttemptCount ?? 1);
  }
  return Math.max(1, (existingAttemptCount ?? 0) + 1);
}

export function getCertificateEmailIdempotencyKey(certificateId: string, attemptCount: number) {
  return `certificate-email/${certificateId}/${attemptCount}`;
}

export async function sendCertificateEmailRequest(
  input: CertificateEmailRequestInput,
  fetcher: typeof fetch = fetch,
): Promise<CertificateEmailRequestResult> {
  try {
    const response = await fetcher("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${input.apiKey}`,
        "Content-Type": "application/json",
        "Idempotency-Key": getCertificateEmailIdempotencyKey(input.certificateId, input.attemptCount),
      },
      body: JSON.stringify({
        from: input.from,
        to: [input.recipientEmail],
        subject: input.subject,
        html: input.html,
        attachments: [{ filename: input.filename, content: input.pdfBase64 }],
      }),
      cache: "no-store",
    });

    if (!response.ok) {
      const detail = (await response.text()).slice(0, 1800);
      const retryable = response.status >= 500 || response.status === 429;
      return {
        status: retryable ? "pending" : "failed",
        detail: detail || `Email provider returned HTTP ${response.status}`,
      };
    }

    return { status: "sent", detail: null };
  } catch (error) {
    return {
      status: "pending",
      detail: error instanceof Error ? error.message.slice(0, 1800) : "Email delivery outcome is unknown.",
    };
  }
}
