import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { renderCertificatePdf } from "../lib/certificates/pdf.ts";

const cases = [
  {
    title: "CERTIFICATE OF COMPLETION",
    course_title_snapshot: "Introduction to Practical AI",
    learner_name_snapshot: "Test Learner",
    recognition_text: "in recognition of successful completion of the required course activities.",
    background: "completion-background.jpg.b64",
  },
  {
    title: "CERTIFICATE OF APPRECIATION",
    course_title_snapshot: "Founding Tester",
    learner_name_snapshot: "Test Learner",
    recognition_text: "In recognition of valuable feedback, testing, and contributions to Kaizora.",
    background: "appreciation-background.jpg.b64",
  },
];

for (const item of cases) {
  const certificate = {
    certificate_number: item.title.includes("APPRECIATION") ? "KZA-AAAAAAAAAAAAAAAAAAAA" : "KZA-BBBBBBBBBBBBBBBBBBBB",
    learner_name_snapshot: item.learner_name_snapshot,
    course_title_snapshot: item.course_title_snapshot,
    certificate_title: item.title,
    recognition_text: item.recognition_text,
    signatory_name: "Chisom Okafor",
    signatory_title: "Founder & CEO",
    institution_name: "Kaizora AI Academy",
    issued_at: "2026-11-27T00:00:00.000Z",
  };

  const pdf = await renderCertificatePdf(certificate);
  assert.equal(pdf.subarray(0, 8).toString("ascii"), "%PDF-1.4");
  assert.ok(pdf.subarray(-32).includes(Buffer.from("%%EOF")), "PDF must contain an EOF marker");

  const encoded = await readFile(path.join(process.cwd(), "assets", "certificates", item.background), "utf8");
  const imageBytes = Buffer.from(encoded.replace(/\s/g, ""), "base64");
  assert.ok(pdf.includes(imageBytes), "PDF must embed the matching approved artwork");
  assert.ok(pdf.includes(Buffer.from("/DCTDecode")), "PDF must embed artwork as a JPEG image object");

  console.log(`Rendered ${item.title}: ${pdf.length.toLocaleString()} bytes`);
}

console.log("Certificate artwork rendering checks passed.");
