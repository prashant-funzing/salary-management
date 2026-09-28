import React, { useState } from "react";
import { Building2, ArrowUpRight } from "lucide-react";
import { api } from "./api";
export function Login({ onLogin }) {
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false);
  return (
    <div className="login">
      <div className="login-card">
        <div className="brand">
          <Building2 />
          acme<span>people</span>
        </div>
        <div className="eyebrow">YOUR PEOPLE. THEIR POSSIBILITIES.</div>
        <h1>
          Welcome to your
          <br />
          HR workspace.
        </h1>
        <p className="muted">
          A clearer view of compensation, across your entire team.
        </p>
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            setBusy(true);
            setError("");
            try {
              const values = Object.fromEntries(new FormData(e.currentTarget));
              const d = await api("/session", {
                method: "POST",
                body: JSON.stringify(values),
              });
              onLogin(d.user);
            } catch (e) {
              setError(e.message);
            } finally {
              setBusy(false);
            }
          }}
        >
          <label>
            Work email
            <input
              name="email"
              type="email"
              required
              autoComplete="username"
              placeholder="you@acme.com"
            />
          </label>
          <label>
            Password
            <input
              name="password"
              type="password"
              required
              autoComplete="current-password"
            />
          </label>
          {error && (
            <div role="alert" className="alert">
              {error}
            </div>
          )}
          <button className="primary" disabled={busy}>
            {busy ? "Signing in…" : "Sign in to workspace"}
            <ArrowUpRight size={18} />
          </button>
        </form>
        <small>ACME · Employee compensation management</small>
      </div>
    </div>
  );
}
