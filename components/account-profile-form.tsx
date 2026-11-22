"use client";

import { useActionState } from "react";

type State = { error?: string; message?: string };
type Action = (state: State, data: FormData) => Promise<State>;

export function AccountProfileForm({ fullName, action }: { fullName: string; action: Action }) {
  const [state, formAction, pending] = useActionState(action, {});
  return (
    <form action={formAction} className="account-profile-form">
      <label htmlFor="account-full-name">Full name</label>
      <input id="account-full-name" name="fullName" type="text" defaultValue={fullName} minLength={2} maxLength={80} autoComplete="name" required />
      {state.error && <p className="form-alert form-error" role="alert">{state.error}</p>}
      {state.message && <p className="form-alert form-success" role="status">{state.message}</p>}
      <button className="auth-submit" type="submit" disabled={pending}>{pending ? "Saving…" : "Save profile"}</button>
    </form>
  );
}
