"use server";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
type State = { error?: string; message?: string };
const validEmail = (email: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
const origin = () => process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
export async function signUpAction(_state: State, data: FormData): Promise<State> {
  const name = String(data.get("fullName") || "").trim();
  const email = String(data.get("email") || "").trim().toLowerCase();
  const password = String(data.get("password") || "");
  if (name.length < 2 || name.length > 80) return { error: "Enter your name (2 to 80 characters)." };
  if (!validEmail(email)) return { error: "Enter a valid email address." };
  if (password.length < 12 || password.length > 128) return { error: "Use a password between 12 and 128 characters." };
  const supabase = await createClient();
  const { error } = await supabase.auth.signUp({ email, password, options: { data: { full_name: name }, emailRedirectTo: origin() + "/auth/callback?next=/dashboard" } });
  if (error) return { error: "We couldn't create your account with those details. Check them or try signing in." };
  return { message: "Check your email for a confirmation link. Your account will be ready after you confirm it." };
}
export async function signInAction(_state: State, data: FormData): Promise<State> {
  const email = String(data.get("email") || "").trim().toLowerCase();
  const password = String(data.get("password") || "");
  if (!validEmail(email) || !password) return { error: "Enter your email address and password." };
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: "We couldn't sign you in. Check your details, confirm your email, or reset your password." };
  redirect("/dashboard");
}
export async function requestPasswordResetAction(_state: State, data: FormData): Promise<State> {
  const email = String(data.get("email") || "").trim().toLowerCase();
  if (!validEmail(email)) return { error: "Enter a valid email address." };
  const supabase = await createClient();
  const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo: origin() + "/auth/callback?next=/auth/update-password" });
  if (error) return { error: "We couldn't process that request right now. Please try again later." };
  return { message: "If an account exists for that address, a password reset link will arrive shortly." };
}
export async function updatePasswordAction(_state: State, data: FormData): Promise<State> {
  const password = String(data.get("password") || "");
  const confirm = String(data.get("confirmation") || "");
  if (password.length < 12 || password.length > 128) return { error: "Use a password between 12 and 128 characters." };
  if (password !== confirm) return { error: "The passwords do not match." };
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return { error: "Your reset session expired. Request a new reset link." };
  const { error } = await supabase.auth.updateUser({ password });
  if (error) return { error: "We couldn't update your password. Request a new reset link and try again." };
  redirect("/dashboard?password=updated");
}
export async function signOutAction() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
