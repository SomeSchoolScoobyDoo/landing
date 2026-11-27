import "server-only";

import { readFile } from "node:fs/promises";
import path from "node:path";
import { deflateSync, inflateSync } from "node:zlib";

type CertificateRecord = {
  certificate_number: string;
  learner_name_snapshot: string;
  course_title_snapshot: string;
  certificate_title: string;
  recognition_text: string;
  signatory_name: string;
  signatory_title: string;
  institution_name: string;
  issued_at: string;
};

const PAGE_WIDTH = 841.89;
const PAGE_HEIGHT = 595.28;
const NAVY = "#133460";
const ORANGE = "#F27118";
const TEXT = "#2D2D2D";

export class CertificateTemplateNotReadyError extends Error {
  constructor() {
    super("The approved certificate artwork has not been installed.");
    this.name = "CertificateTemplateNotReadyError";
  }
}

function hexColor(hex: string) {
  const value = hex.replace("#", "");
  const r = parseInt(value.slice(0, 2), 16) / 255;
  const g = parseInt(value.slice(2, 4), 16) / 255;
  const b = parseInt(value.slice(4, 6), 16) / 255;
  return `${r.toFixed(4)} ${g.toFixed(4)} ${b.toFixed(4)}`;
}

const CP1252: Record<string, number> = {
  "€": 0x80, "‚": 0x82, "ƒ": 0x83, "„": 0x84, "…": 0x85,
  "†": 0x86, "‡": 0x87, "ˆ": 0x88, "‰": 0x89, "Š": 0x8a,
  "‹": 0x8b, "Œ": 0x8c, "Ž": 0x8e, "‘": 0x91, "’": 0x92,
  "“": 0x93, "”": 0x94, "•": 0x95, "–": 0x96, "—": 0x97,
  "˜": 0x98, "™": 0x99, "š": 0x9a, "›": 0x9b, "œ": 0x9c,
  "ž": 0x9e, "Ÿ": 0x9f,
};

function pdfHex(value: string) {
  const bytes: number[] = [];
  for (const char of value) {
    const code = char.codePointAt(0) ?? 63;
    if (code <= 0x7f || (code >= 0xa0 && code <= 0xff)) bytes.push(code);
    else if (CP1252[char] !== undefined) bytes.push(CP1252[char]);
    else if (char === "’" || char === "‘") bytes.push(0x27);
    else if (char === "“" || char === "”") bytes.push(0x22);
    else if (char === "–" || char === "—") bytes.push(0x2d);
    else bytes.push(0x3f);
  }
  return `<${bytes.map((byte) => byte.toString(16).padStart(2, "0")).join("").toUpperCase()}>`;
}

function estimatedTextWidth(value: string, size: number) {
  let units = 0;
  for (const char of value) {
    if (char === " ") units += 0.28;
    else if ("ilI.,:;'!|".includes(char)) units += 0.26;
    else if ("MW@%&".includes(char)) units += 0.82;
    else if (/[A-Z0-9]/.test(char)) units += 0.62;
    else units += 0.51;
  }
  return units * size;
}

function textCommand(value: string, font: "F1" | "F2" | "F3", size: number, x: number, y: number, color: string, maxWidth?: number) {
  const estimated = Math.max(1, estimatedTextWidth(value, size));
  const scale = maxWidth ? Math.min(100, (maxWidth / estimated) * 100) : 100;
  return `${hexColor(color)} rg BT /${font} ${size} Tf ${scale.toFixed(2)} Tz 1 0 0 1 ${x.toFixed(2)} ${y.toFixed(2)} Tm ${pdfHex(value)} Tj ET\n`;
}

function centeredText(value: string, font: "F1" | "F2" | "F3", size: number, y: number, color: string, maxWidth = 700) {
  const estimated = Math.min(maxWidth, estimatedTextWidth(value, size));
  const x = (PAGE_WIDTH - estimated) / 2;
  return textCommand(value, font, size, x, y, color, maxWidth);
}

function wrappedText(value: string, size: number, y: number, maxWidth: number, lineHeight: number, color: string) {
  const words = value.trim().split(/\s+/);
  const lines: string[] = [];
  let line = "";
  for (const word of words) {
    const candidate = line ? `${line} ${word}` : word;
    if (line && estimatedTextWidth(candidate, size) > maxWidth) {
      lines.push(line);
      line = word;
    } else {
      line = candidate;
    }
  }
  if (line) lines.push(line);
  let commands = "";
  lines.slice(0, 4).forEach((item, index) => {
    commands += centeredText(item, "F1", size, y - index * lineHeight, color, maxWidth);
  });
  return { commands, lines: lines.length };
}

function paeth(a: number, b: number, c: number) {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
}

function pngToRgb(input: Buffer) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (input.length < 33 || !input.subarray(0, 8).equals(signature)) {
    throw new Error("The signatory asset must be a valid PNG image.");
  }

  let offset = 8;
  let width = 0;
  let height = 0;
  let bitDepth = 0;
  let colorType = 0;
  let interlace = 0;
  const idat: Buffer[] = [];

  while (offset + 12 <= input.length) {
    const length = input.readUInt32BE(offset);
    const type = input.toString("ascii", offset + 4, offset + 8);
    const data = input.subarray(offset + 8, offset + 8 + length);
    if (type === "IHDR") {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
      interlace = data[12];
    } else if (type === "IDAT") {
      idat.push(data);
    } else if (type === "IEND") {
      break;
    }
    offset += length + 12;
  }

  if (!width || !height || bitDepth !== 8 || (colorType !== 2 && colorType !== 6) || interlace !== 0) {
    throw new Error("The signature PNG must be 8-bit RGB or RGBA without interlacing.");
  }

  const channels = colorType === 6 ? 4 : 3;
  const stride = width * channels;
  let decoded: Buffer;
  try {
    decoded = inflateSync(Buffer.concat(idat));
  } catch (error) {
    const compressed = Buffer.concat(idat);
    const detail = error instanceof Error ? error.message : "unknown zlib error";
    throw new Error(`The committed signature PNG IDAT stream could not be decoded (${detail}; chunks=${idat.length}; bytes=${compressed.length}; header=${compressed.subarray(0, 16).toString("hex")}).`);
  }
  const rgb = Buffer.alloc(width * height * 3);
  let sourceOffset = 0;
  let targetOffset = 0;
  let previous = Buffer.alloc(stride);

  for (let row = 0; row < height; row++) {
    const filter = decoded[sourceOffset++];
    const current = Buffer.alloc(stride);
    for (let i = 0; i < stride; i++) {
      const raw = decoded[sourceOffset++];
      const left = i >= channels ? current[i - channels] : 0;
      const up = previous[i] ?? 0;
      const upperLeft = i >= channels ? previous[i - channels] : 0;
      let value = raw;
      if (filter === 1) value += left;
      else if (filter === 2) value += up;
      else if (filter === 3) value += Math.floor((left + up) / 2);
      else if (filter === 4) value += paeth(left, up, upperLeft);
      else if (filter !== 0) throw new Error("Unsupported PNG filter in signatory asset.");
      current[i] = value & 255;
    }

    for (let col = 0; col < width; col++) {
      const src = col * channels;
      const alpha = channels === 4 ? current[src + 3] / 255 : 1;
      rgb[targetOffset++] = Math.round(current[src] * alpha + 255 * (1 - alpha));
      rgb[targetOffset++] = Math.round(current[src + 1] * alpha + 255 * (1 - alpha));
      rgb[targetOffset++] = Math.round(current[src + 2] * alpha + 255 * (1 - alpha));
    }
    previous = current;
  }

  return { width, height, compressed: deflateSync(rgb) };
}

type JpegBackground = { width: number; height: number; bytes: Buffer };

function jpegDimensions(input: Buffer) {
  if (input.length < 4 || input[0] !== 0xff || input[1] !== 0xd8) {
    throw new Error("The certificate artwork must be a valid JPEG image.");
  }
  const frameMarkers = new Set([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]);
  let offset = 2;
  while (offset + 4 < input.length) {
    if (input[offset] !== 0xff) {
      offset += 1;
      continue;
    }
    while (input[offset] === 0xff) offset += 1;
    const marker = input[offset++];
    if (marker === 0xd9 || marker === 0xda) break;
    if (offset + 2 > input.length) break;
    const segmentLength = input.readUInt16BE(offset);
    if (segmentLength < 2 || offset + segmentLength > input.length) break;
    if (frameMarkers.has(marker)) {
      const height = input.readUInt16BE(offset + 3);
      const width = input.readUInt16BE(offset + 5);
      const components = input[offset + 7];
      if (!width || !height || components !== 3) {
        throw new Error("The certificate artwork must be an RGB JPEG image.");
      }
      return { width, height, bytes: input };
    }
    offset += segmentLength;
  }
  throw new Error("The certificate artwork dimensions could not be read.");
}

async function loadCertificateBackground(certificate: CertificateRecord): Promise<JpegBackground> {
  const assetDir = path.join(process.cwd(), "assets", "certificates");
  const appreciation = certificate.certificate_title.toLowerCase().includes("appreciation");
  const assetPath = appreciation
    ? path.join(assetDir, "appreciation-background.jpg.b64")
    : path.join(assetDir, "completion-background.jpg.b64");
  try {
    const encoded = await readFile(assetPath, "utf8");
    return jpegDimensions(Buffer.from(encoded.replace(/\\s/g, ""), "base64"));
  } catch {
    throw new CertificateTemplateNotReadyError();
  }
}

function buildPdf(content: string, background: JpegBackground) {
  const stream = Buffer.from(content, "ascii");
  const imageHeader = Buffer.from(
    `<< /Type /XObject /Subtype /Image /Width ${background.width} /Height ${background.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${background.bytes.length} >>\\nstream\\n`,
    "ascii",
  );
  const imageBody = Buffer.concat([imageHeader, background.bytes, Buffer.from("\\nendstream", "ascii")]);
  const streamBody = Buffer.concat([
    Buffer.from(`<< /Length ${stream.length} >>\\nstream\\n`, "ascii"),
    stream,
    Buffer.from("\\nendstream", "ascii"),
  ]);

  const objects: Buffer[] = [
    Buffer.from("<< /Type /Catalog /Pages 2 0 R >>", "ascii"),
    Buffer.from("<< /Type /Pages /Kids [3 0 R] /Count 1 >>", "ascii"),
    Buffer.from("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 841.89 595.28] /Resources << /Font << /F1 4 0 R /F2 5 0 R /F3 6 0 R >> /XObject << /Bg 7 0 R >> >> /Contents 8 0 R >>", "ascii"),
    Buffer.from("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>", "ascii"),
    Buffer.from("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>", "ascii"),
    Buffer.from("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique /Encoding /WinAnsiEncoding >>", "ascii"),
    imageBody,
    streamBody,
  ];

  const parts: Buffer[] = [Buffer.from("%PDF-1.4\\n%Kaizora\\n", "ascii")];
  const offsets: number[] = [0];
  let byteLength = parts[0].length;

  objects.forEach((object, index) => {
    offsets.push(byteLength);
    const start = Buffer.from(`${index + 1} 0 obj\\n`, "ascii");
    const end = Buffer.from("\\nendobj\\n", "ascii");
    parts.push(start, object, end);
    byteLength += start.length + object.length + end.length;
  });

  const xrefOffset = byteLength;
  let xref = `xref\\n0 ${objects.length + 1}\\n0000000000 65535 f \\n`;
  for (let i = 1; i < offsets.length; i++) {
    xref += `${String(offsets[i]).padStart(10, "0")} 00000 n \\n`;
  }
  const trailer = `trailer\\n<< /Size ${objects.length + 1} /Root 1 0 R >>\\nstartxref\\n${xrefOffset}\\n%%EOF`;
  parts.push(Buffer.from(xref + trailer, "ascii"));
  return Buffer.concat(parts);
}

export function validateCertificateSignaturePng(input: Buffer) {
  pngToRgb(input);
}

export async function renderCertificatePdf(certificate: CertificateRecord) {
  const background = await loadCertificateBackground(certificate);
  const isAppreciation = certificate.certificate_title.toLowerCase().includes("appreciation");
  const issuedDate = new Date(certificate.issued_at).toLocaleDateString("en-GB", {
    day: "numeric", month: "long", year: "numeric", timeZone: "UTC",
  });

  let content = `q ${PAGE_WIDTH} 0 0 ${PAGE_HEIGHT} 0 0 cm /Bg Do Q\\n`;

  if (isAppreciation) {
    // The appreciation artwork contains a sample recognition message. Replace only
    // that text area so each award can carry its own verified recognition wording.
    content += `1 1 1 rg 155 232 531 48 re f\\n`;
    content += centeredText(certificate.learner_name_snapshot, "F2", 22, 307, NAVY, 650);
    content += wrappedText(certificate.recognition_text, 11.5, 265, 650, 14, TEXT).commands;
    content += textCommand(issuedDate, "F1", 9.5, 122, 154, TEXT, 210);
    content += textCommand(certificate.certificate_number, "F1", 8.5, 640, 154, TEXT, 155);
  } else {
    content += centeredText(certificate.learner_name_snapshot, "F2", 23, 365, NAVY, 690);
    content += centeredText(certificate.course_title_snapshot, "F2", 15, 300, ORANGE, 690);
    content += textCommand(issuedDate, "F1", 9.5, 92, 119, TEXT, 210);
    content += textCommand(certificate.certificate_number, "F1", 8.5, 655, 119, TEXT, 155);
  }

  return buildPdf(content, background);
}
