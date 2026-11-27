"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

function validateName(value: string, label: string) {
  const name = value.trim();
  if (name.length < 2 || name.length > 120) {
    throw new Error(label + " must be between 2 and 120 characters.");
  }
  return name;
}

export async function updateProfileNameAction(formData: FormData) {
  const fullName = validateName(String(formData.get("fullName") ?? ""), "Your profile name");
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { error } = await supabase
    .from("profiles")
    .update({ full_name: fullName, updated_at: new Date().toISOString() })
    .eq("id", auth.user.id);

  if (error) throw new Error("Your profile name could not be saved. Please try again.");
  revalidatePath("/settings");
  revalidatePath("/dashboard");
  revalidatePath("/badges");
  revalidatePath("/certificates");
  revalidatePath("/courses", "layout");
  redirect("/settings?profile=saved");
}

export async function updateCertificateDisplayNameAction(formData: FormData) {
  const rawName = String(formData.get("certificateDisplayName") ?? "").trim();
  const certificateDisplayName = rawName.length === 0
    ? null
    : validateName(rawName, "Your certificate display name");

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) redirect("/login");

  const { error } = await supabase
    .from("profiles")
    .update({
      certificate_display_name: certificateDisplayName,
      updated_at: new Date().toISOString(),
    })
    .eq("id", auth.user.id);

  if (error) throw new Error("Your certificate display name could not be saved. Please try again.");
  revalidatePath("/settings");
  revalidatePath("/badges");
  revalidatePath("/certificates");
  revalidatePath("/courses", "layout");
  redirect("/settings?certificateName=saved");
}
