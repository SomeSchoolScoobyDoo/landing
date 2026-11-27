import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import styles from "@/app/certificates/certificates.module.css";

type VerifiedCertificate = {
  certificate_number: string;
  learner_name: string;
  course_title: string;
  issued_at: string;
  status: "valid" | "revoked";
  signatory_name: string;
  signatory_title: string;
  institution_name: string;
};

export default async function VerifyCertificatePage({
  params,
}: {
  params: Promise<{ certificateNumber: string }>;
}) {
  const { certificateNumber } = await params;
  if (!/^KZA-[A-F0-9]{20}$/i.test(certificateNumber)) notFound();

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("verify_course_certificate", {
    p_certificate_number: certificateNumber,
  });
  const certificate = (data?.[0] ?? null) as VerifiedCertificate | null;
  if (error || !certificate) notFound();

  return (
    <main className={styles.page}>
      <header className={styles.header}>
        <Link href="/" className={styles.backLink}>← Kaizora AI Academy</Link>
        <p className={styles.eyebrow}>CREDENTIAL VERIFICATION</p>
        <h1>Certificate verification</h1>
      </header>
      <section className={styles.verificationCard}>
        <span className={certificate.status === "valid" ? styles.valid : styles.revoked}>
          {certificate.status === "valid" ? "Verified · Valid" : "Revoked"}
        </span>
        <h2>{certificate.institution_name}</h2>
        <p className={styles.number}>{certificate.certificate_number}</p>
        <dl>
          <div><dt>Learner</dt><dd>{certificate.learner_name}</dd></div>
          <div><dt>Course</dt><dd>{certificate.course_title}</dd></div>
          <div><dt>Issued</dt><dd>{new Date(certificate.issued_at).toLocaleDateString(undefined, { day: "numeric", month: "long", year: "numeric" })}</dd></div>
          <div><dt>Authorised signatory</dt><dd>{certificate.signatory_name}, {certificate.signatory_title}</dd></div>
        </dl>
        <p className={styles.verifyNote}>
          {certificate.status === "valid"
            ? "This certificate record matches the Kaizora AI Academy issuance database."
            : "This certificate was previously issued but is no longer valid."}
        </p>
      </section>
    </main>
  );
}
