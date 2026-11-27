import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { CertificateTemplateNotReadyError, renderCertificatePdf } from "@/lib/certificates/pdf";

export const runtime = "nodejs";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ certificateNumber: string }> },
) {
  const { certificateNumber } = await params;
  if (!/^KZA-[A-F0-9]{20}$/i.test(certificateNumber)) {
    return NextResponse.json({ error: "Certificate not found." }, { status: 404 });
  }

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) {
    return NextResponse.json({ error: "Authentication required." }, { status: 401 });
  }

  const { data: certificate, error } = await supabase
    .from("course_certificates")
    .select("certificate_number, learner_name_snapshot, course_title_snapshot, certificate_title, recognition_text, signatory_name, signatory_title, institution_name, issued_at, status")
    .eq("certificate_number", certificateNumber.toUpperCase())
    .eq("user_id", authData.user.id)
    .maybeSingle();

  if (error || !certificate) {
    return NextResponse.json({ error: "Certificate not found." }, { status: 404 });
  }
  if (certificate.status !== "valid") {
    return NextResponse.json({ error: "This certificate has been revoked." }, { status: 410 });
  }

  const disposition = new URL(request.url).searchParams.get("preview") === "1" ? "inline" : "attachment";

  try {
    const pdf = await renderCertificatePdf(certificate);
    return new Response(new Uint8Array(pdf), {
      status: 200,
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `${disposition}; filename="${certificate.certificate_number}.pdf"`,
        "Cache-Control": "private, no-store, max-age=0",
      },
    });
  } catch (renderError) {
    if (renderError instanceof CertificateTemplateNotReadyError) {
      return NextResponse.json({ error: "The approved certificate artwork is not installed yet." }, { status: 503 });
    }
    return NextResponse.json({ error: "The certificate PDF could not be generated." }, { status: 500 });
  }
}
