import { redirect } from "next/navigation";

export default function SignupTemporarilyUnavailable() {
  redirect("/preview");
}
