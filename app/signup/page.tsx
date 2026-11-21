import Link from "next/link";
import { AuthForm, AuthShell, Field } from "@/app/auth/auth-form";
import { signUpAction } from "@/app/auth/actions";
export default function SignupPage() {
  const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  return <AuthShell title="Start learning." description="Create your free learner account. Choose any course and learn independently." footer={<>Already registered? <Link href="/login">Sign in</Link></>}>
    {configured ? <>
      <AuthForm action={signUpAction} submitLabel="Create account"><Field label="Full name" name="fullName" autoComplete="name"/><Field label="Email address" name="email" type="email" autoComplete="email"/><Field label="Password (at least 12 characters)" name="password" type="password" autoComplete="new-password"/></AuthForm>
      <p className="auth-legal">By creating an account, you agree to use Kaizora respectfully and keep your sign-in details secure. Terms and privacy information will be published before public launch.</p>
    </> : <p className="form-alert" role="status">New accounts will be available when this development preview is connected to its database. You can explore the course catalogue in the meantime.</p>}
  </AuthShell>;
}
