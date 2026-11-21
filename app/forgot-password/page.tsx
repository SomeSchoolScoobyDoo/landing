import Link from "next/link";
import { AuthForm, AuthShell, Field } from "@/app/auth/auth-form";
import { requestPasswordResetAction } from "@/app/auth/actions";
export default function ForgotPasswordPage() {
  const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  return <AuthShell title="Reset your password." description="Enter your account email. If it exists, we will send a reset link." footer={<Link href="/login">Back to sign in</Link>}>{configured ? <AuthForm action={requestPasswordResetAction} submitLabel="Send reset link"><Field label="Email address" name="email" type="email" autoComplete="email"/></AuthForm> : <p className="form-alert" role="status">Password recovery will be available when this development preview is connected to its database.</p>}</AuthShell>;
}
