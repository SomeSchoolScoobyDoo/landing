import Link from "next/link";
import { AuthForm, AuthShell, Field } from "@/app/auth/auth-form";
import { signInAction } from "@/app/auth/actions";
export default async function LoginPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const params = await searchParams;
  const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  return <AuthShell title="Welcome back." description="Sign in to continue learning and building." footer={<>New to Kaizora? <Link href="/signup">Create an account</Link></>}>
    {params.error === "confirmation" && <p className="form-alert form-error" role="alert">That confirmation link could not be verified. Request a fresh link or try signing in.</p>}
    {configured ? <AuthForm action={signInAction} submitLabel="Sign in"><Field label="Email address" name="email" type="email" autoComplete="email"/><Field label="Password" name="password" type="password" autoComplete="current-password"/><div className="auth-inline-link"><Link href="/forgot-password">Forgot password?</Link></div></AuthForm> : <p className="form-alert" role="status">Account access will be available when this development preview is connected to its database. You can explore the course catalogue in the meantime.</p>}
  </AuthShell>;
}
