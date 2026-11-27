import Link from "next/link";
import { AuthForm, AuthShell, Field } from "@/app/auth/auth-form";
import { signUpAction } from "@/app/auth/actions";

export default function SignupPage() {
  const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  return (
    <AuthShell
      title="Start learning."
      description="Create your Kaizora learner account and keep your courses, progress and achievements together."
      footer={<>Already have an account? <Link href="/login">Sign in</Link>.</>}
    >
      {configured ? (
        <AuthForm action={signUpAction} submitLabel="Create account">
          <Field label="Full name" name="fullName" autoComplete="name" />
          <Field label="Email address" name="email" type="email" autoComplete="email" />
          <Field label="Password (at least 12 characters)" name="password" type="password" autoComplete="new-password" />
          <p className="auth-help">We’ll send a confirmation link to your email before you can sign in.</p>
        </AuthForm>
      ) : (
        <p className="form-alert" role="status">Account registration is temporarily unavailable while the database connection is being configured.</p>
      )}
    </AuthShell>
  );
}
