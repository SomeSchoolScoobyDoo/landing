"use client";

import Image from "next/image";
import Link from "next/link";

type BrandProps = { className?: string };

export function Brand({ className = "" }: BrandProps) {
  return (
    <Link className={`brand ${className}`.trim()} href="/" aria-label="Kaizora AI Academy home">
      <Image src="/kaizora-logo.svg" alt="" width={30} height={36} priority />
      <span>kaizora<span className="brand-light"> AI Academy</span></span>
    </Link>
  );
}
