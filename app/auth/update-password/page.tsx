import Link from "next/link";
import { AuthForm, AuthShell, Field } from "@/app/auth/auth-form";
import { updatePasswordAction } from "@/app/auth/actions";
export default function UpdatePasswordPage() {
  const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  return <AuthShell title="Choose a new password." description="Use a strong password you do not use on another site." footer={<Link href="/login">Back to sign in</Link>}>{configured ? <AuthForm action={updatePasswordAction} submitLabel="Update password"><Field label="New password (at least 12 characters)" name="password" type="password" autoComplete="new-password"/><Field label="Confirm new password" name="confirmation" type="password" autoComplete="new-password"/></AuthForm> : <p className="form-alert" role="status">Password recovery will be available when this development preview is connected to its database.</p>}</AuthShell>;
}
