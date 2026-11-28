"use client";
import Image from "next/image";
import { Brand } from "@/components/brand";
import { useActionState, useState, type ReactNode } from "react";
type State = { error?: string; message?: string };
type Action = (state: State, data: FormData) => Promise<State>;
export function AuthForm({ action, children, submitLabel }: { action: Action; children: ReactNode; submitLabel: string }) {
  const [state, formAction, pending] = useActionState(action, {});
  return <form action={formAction} className="auth-form">{children}{state.error && <p className="form-alert form-error" role="alert">{state.error}</p>}{state.message && <p className="form-alert form-success" role="status">{state.message}</p>}<button className="auth-submit" type="submit" disabled={pending}>{pending ? "Please wait…" : submitLabel}</button></form>;
}
export function Field({ label, name, type = "text", autoComplete }: { label: string; name: string; type?: string; autoComplete?: string }) {
  const [passwordVisible, setPasswordVisible] = useState(false);
  const isPassword = type === "password";
  const input = <input id={name} name={name} type={isPassword && passwordVisible ? "text" : type} autoComplete={autoComplete} required maxLength={type === "email" ? 254 : 128} />;
  return (
    <label className="auth-field">
      <span>{label}</span>
      {isPassword ? (
        <span className="auth-password-wrap">
          {input}
          <button
            className="auth-password-toggle"
            type="button"
            aria-controls={name}
            aria-label={passwordVisible ? "Hide password" : "Show password"}
            aria-pressed={passwordVisible}
            onClick={() => setPasswordVisible((visible) => !visible)}
          >
            {passwordVisible ? "Hide" : "Show"}
          </button>
        </span>
      ) : input}
    </label>
  );
}
export function AuthShell({ title, description, children, footer }: { title: string; description: string; children: ReactNode; footer: ReactNode }) {
  return <main className="auth-page"><section className="auth-panel"><Brand className="auth-brand" /><p className="eyebrow">KAIZORA AI ACADEMY</p><h1>{title}</h1><p className="auth-description">{description}</p>{children}<div className="auth-footer">{footer}</div></section><aside className="auth-aside"><Image className="auth-aside-mark" src="/kaizora-logo.svg" alt="" width={112} height={134} priority /><p>Learn boldly.<br/><strong>Build what&apos;s next.</strong></p><span className="auth-aside-caption">LEARN. BUILD. APPLY.</span></aside></main>;
}
