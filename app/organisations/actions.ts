"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export async function createOrganisationAction(formData: FormData) {
  const supabase = await createClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();

  if (authError || !auth.user) redirect("/login");

  const name = String(formData.get("name") ?? "").trim();
  const type = String(formData.get("organization_type") ?? "");

  if (name.length < 2 || name.length > 160 || !["school", "corporation"].includes(type)) {
    redirect("/organisations/new?error=invalid");
  }

  const { data, error } = await supabase.rpc("create_organization_account", {
    p_name: name,
    p_organization_type: type,
  });

  if (error || !data) {
    redirect("/organisations/new?error=create");
  }

  redirect("/organisations?created=1");
}
