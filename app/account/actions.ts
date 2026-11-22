"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

type State = { error?: string; message?: string };

export async function updateProfileAction(_state: State, data: FormData): Promise<State> {
  const fullName = String(data.get("fullName") ?? "").trim();
  if (fullName.length < 2 || fullName.length > 80) {
    return { error: "Enter a name between 2 and 80 characters." };
  }

  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) return { error: "Your session has expired. Please sign in again." };

  const { data: profile, error } = await supabase
    .from("profiles")
    .update({ full_name: fullName })
    .eq("id", auth.user.id)
    .select("id")
    .maybeSingle();

  if (error || !profile) {
    return { error: "Your profile could not be updated. Please refresh and try again." };
  }

  const { error: metadataError } = await supabase.auth.updateUser({
    data: { full_name: fullName },
  });
  if (metadataError) {
    return { error: "Your profile name was saved, but account details could not be synchronised. Refresh and try again." };
  }

  revalidatePath("/account");
  revalidatePath("/dashboard");
  return { message: "Your profile has been updated." };
}
