import Link from "next/link";
import { redirect } from "next/navigation";
import { LearnerNavigation } from "@/components/learner-navigation";
import { signOutAction } from "@/app/auth/actions";
import { createClient } from "@/lib/supabase/server";
import { emailCertificateAction, issueCertificateAction } from "./actions";
import styles from "./certificates.module.css";

type Certificate = {
  id: string;
  course_id: string;
  certificate_number: string;
  course_title_snapshot: string;
  certificate_title: string;
  recognition_text: string;
  issued_at: string;
  status: "valid" | "revoked";
  revocation_reason: string | null;
};

type Enrollment = {
  id: string;
  courses: {
    id: string;
    slug: string;
    title: string;
    certificate_enabled: boolean;
  };
};

type Eligibility = { eligible: boolean; reason: string | null };

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

export default async function CertificatesPage({
  searchParams,
}: {
  searchParams: Promise<{ issued?: string; email?: string }>;
}) {
  const params = await searchParams;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();

  if (authError || !authData.user) redirect("/login");

  const [certificateResult, enrollmentResult, deliveryResult] = await Promise.all([
    supabase
      .from("course_certificates")
      .select("id, course_id, certificate_number, course_title_snapshot, certificate_title, recognition_text, issued_at, status, revocation_reason")
      .eq("user_id", authData.user.id)
      .order("issued_at", { ascending: false }),
    supabase
      .from("course_enrollments")
      .select("id, courses!inner(id, slug, title, certificate_enabled)")
      .eq("user_id", authData.user.id)
      .eq("status", "active")
      .order("enrolled_at", { ascending: false }),
    supabase
      .from("certificate_email_deliveries")
      .select("certificate_id, status, attempt_count, last_error")
      .eq("user_id", authData.user.id),
  ]);

  if (certificateResult.error || enrollmentResult.error || deliveryResult.error) {
    throw new Error("Your certificates could not be loaded. Please refresh.");
  }

  const certificates = (certificateResult.data ?? []) as Certificate[];
  const enrollments = (enrollmentResult.data ?? []) as unknown as Enrollment[];
  const deliveries = new Map(
    (deliveryResult.data ?? []).map((delivery) => [delivery.certificate_id, delivery]),
  );

  const configuredEnrollments = enrollments.filter((item) => item.courses.certificate_enabled);
  const eligibilityResults = await Promise.all(
    configuredEnrollments.map(async (item) => {
      const { data, error } = await supabase.rpc("get_certificate_eligibility", {
        p_course_id: item.courses.id,
      });
      const result = (data?.[0] ?? null) as Eligibility | null;
      return {
        course: item.courses,
        eligible: !error && result?.eligible === true,
        reason: error ? "Eligibility could not be checked. Refresh and try again." : result?.reason ?? null,
      };
    }),
  );

  return (
    <main className={styles.page}>
      <div className={styles.topNav}>
        <LearnerNavigation />
        <form action={signOutAction}><button className="signout-button" type="submit">Sign out</button></form>
      </div>
      <header className={styles.header}>
        <Link href="/dashboard" className={styles.backLink}>← Learner dashboard</Link>
        <p className={styles.eyebrow}>KAIZORA AI ACADEMY</p>
        <h1>My certificates</h1>
        <p className={styles.intro}>
          Formal certificates are issued only for courses configured to offer them.
          They are separate from your course-completion badges.
        </p>
      </header>

      {params.issued === "1" && (
        <p className={styles.notice} role="status">
          Your certificate record has been issued. The signed PDF becomes available once the approved certificate artwork is active.
        </p>
      )}
      {params.email === "sent" && <p className={styles.notice} role="status">The certificate email was sent successfully.</p>}
      {params.email === "failed" && <p className={styles.warning} role="status">Email delivery failed. You can retry after checking the provider settings.</p>}
      {params.email === "not_configured" && <p className={styles.warning} role="status">Email delivery is not configured yet. The certificate record remains valid.</p>}
      {params.email === "template_missing" && <p className={styles.warning} role="status">The approved certificate artwork is not installed yet. No email was sent.</p>}
      {params.email === "no-address" && <p className={styles.warning} role="status">Your account does not have an email address on file.</p>}
      {params.email === "unverified" && <p className={styles.warning} role="status">Confirm your account email before sending a certificate.</p>}
      {params.email === "pending" && <p className={styles.warning} role="status">The email provider has not confirmed the outcome yet. Retry safely; duplicate sends are protected.</p>}

      <section className={styles.section} aria-labelledby="issued-heading">
        <div className={styles.sectionHeading}>
          <div><p className={styles.eyebrow}>YOUR RECORDS</p><h2 id="issued-heading">Issued certificates</h2></div>
          <span>{certificates.length} issued</span>
        </div>

        {certificates.length === 0 ? (
          <div className={styles.empty}>
            <h3>No certificates issued yet.</h3>
            <p>When you complete an eligible course and meet its configured requirements, your certificate will appear here.</p>
          </div>
        ) : (
          <div className={styles.grid}>
            {certificates.map((certificate) => {
              const delivery = deliveries.get(certificate.id);
              const linkedInParams = new URLSearchParams({
                startTask: "CERTIFICATION_NAME",
                name: certificate.certificate_title + " | " + certificate.course_title_snapshot + " | Kaizora AI Academy",
                organizationName: "Kaizora AI Academy",
                issueYear: String(new Date(certificate.issued_at).getFullYear()),
                issueMonth: String(new Date(certificate.issued_at).getMonth() + 1),
                certId: certificate.certificate_number,
              });
              const configuredAppUrl = process.env.NEXT_PUBLIC_APP_URL;
              const appUrl = configuredAppUrl?.endsWith("/") ? configuredAppUrl.slice(0, -1) : configuredAppUrl;
              if (appUrl) {
                linkedInParams.set("certUrl", `${appUrl}/verify/${encodeURIComponent(certificate.certificate_number)}`);
              }
              const linkedInUrl = `https://www.linkedin.com/profile/add?${linkedInParams.toString()}`;
              return (
                <article className={styles.card} key={certificate.id}>
                  <div className={styles.cardTop}>
                    <span className={certificate.status === "valid" ? styles.valid : styles.revoked}>
                      {certificate.status === "valid" ? "Valid" : "Revoked"}
                    </span>
                    <time>{formatDate(certificate.issued_at)}</time>
                  </div>
                  <h3>{certificate.certificate_title}</h3>
                  <p className={styles.courseTitle}>{certificate.course_title_snapshot}</p>
                  <p className={styles.recognition}>{certificate.recognition_text}</p>
                  <p className={styles.number}>{certificate.certificate_number}</p>
                  {certificate.status === "revoked" ? (
                    <p className={styles.reason}>This certificate has been revoked. {certificate.revocation_reason ?? ""}</p>
                  ) : (
                    <div className={styles.actions}>
                      <Link href={`/certificates/${certificate.certificate_number}/download?preview=1`} className={styles.secondaryAction}>
                        Preview
                      </Link>
                      <Link href={`/certificates/${certificate.certificate_number}/download`} className={styles.primaryAction}>
                        Download PDF
                      </Link>
                      <Link href={`/verify/${certificate.certificate_number}`} className={styles.secondaryAction}>
                        Public verification
                      </Link>
                      <a href={linkedInUrl} className={styles.secondaryAction} target="_blank" rel="noopener noreferrer">
                        Add to LinkedIn ↗
                      </a>
                      <form action={emailCertificateAction}>
                        <input type="hidden" name="certificateNumber" value={certificate.certificate_number} />
                        <button className={styles.secondaryAction} type="submit">
                          {delivery?.status === "sent" ? "Email again" : delivery?.status === "failed" || delivery?.status === "pending" ? "Retry email" : "Email certificate"}
                        </button>
                      </form>
                    </div>
                  )}
                  {delivery && (
                    <p className={styles.delivery}>
                      Email: {delivery.status} · {delivery.attempt_count} attempt(s)
                      {delivery.last_error ? ` · ${delivery.last_error}` : ""}
                    </p>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </section>

      <section className={styles.section} aria-labelledby="eligible-heading">
        <div className={styles.sectionHeading}>
          <div><p className={styles.eyebrow}>COURSE ELIGIBILITY</p><h2 id="eligible-heading">Available certificates</h2></div>
        </div>
        {eligibilityResults.length === 0 ? (
          <div className={styles.empty}>
            <h3>No enrolled courses currently offer formal certificates.</h3>
            <p>Course-completion badges remain available separately where configured.</p>
          </div>
        ) : (
          <div className={styles.grid}>
            {eligibilityResults.map(({ course, eligible, reason }) => {
              const previousCertificate = certificates.find((certificate) => certificate.course_id === course.id);
              return (
              <article className={styles.card} key={course.id}>
                <h3>{course.title}</h3>
                {previousCertificate ? (
                  <p className={previousCertificate.status === "valid" ? styles.eligibleText : styles.reason}>
                    {previousCertificate.status === "valid"
                      ? "A certificate has already been issued for this course. See your issued certificates above."
                      : "A previous certificate for this course was revoked. An academy administrator must authorise any reissue."}
                  </p>
                ) : eligible ? (
                  <>
                    <p className={styles.eligibleText}>Your recorded progress meets this course&apos;s current certificate requirements.</p>
                    <form action={issueCertificateAction}>
                      <input type="hidden" name="courseId" value={course.id} />
                      <button className={styles.primaryAction} type="submit">Issue my certificate</button>
                    </form>
                  </>
                ) : (
                  <p className={styles.reason}>{reason ?? "This course is not currently eligible for certificate issuance."}</p>
                )}
              </article>
              );
            })}
          </div>
        )}
      </section>
    </main>
  );
}
