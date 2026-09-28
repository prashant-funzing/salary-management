import React, { useEffect, useRef, useState } from "react";
import { Building2, ArrowUpRight, X } from "lucide-react";
import { api, money, today } from "./api";

export function Stat({ label, value, icon, detail }) {
  return (
    <div className="stat">
      <div>
        <span>{label}</span>
        <h2>{value}</h2>
        <p>{detail}</p>
      </div>
      <div className="stat-icon">{icon}</div>
    </div>
  );
}
export function Modal({ title, close, children, wide }) {
  const ref = useRef(null);
  const closeRef = useRef(close);
  closeRef.current = close;
  useEffect(() => {
    const previous = document.activeElement;
    const dialog = ref.current;
    const focusable = () => [
      ...dialog.querySelectorAll(
        "button:not(:disabled), input, select, a[href]",
      ),
    ];
    focusable()[0]?.focus();
    function onKey(event) {
      const dialogs = document.querySelectorAll('[role="dialog"]');
      if (dialogs[dialogs.length - 1] !== dialog) return;
      if (event.key === "Escape") {
        event.preventDefault();
        closeRef.current();
      }
      if (event.key === "Tab") {
        const elements = focusable(),
          first = elements[0],
          last = elements[elements.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last?.focus();
        }
        if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first?.focus();
        }
      }
    }
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      previous?.focus();
    };
  }, []);
  return (
    <div
      className="overlay"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) close();
      }}
    >
      <section
        ref={ref}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className={`modal ${wide ? "wide" : ""}`}
      >
        <div className="modal-heading">
          <h2>{title}</h2>
          <button aria-label="Close dialog" onClick={close}>
            <X size={20} />
          </button>
        </div>
        {children}
      </section>
    </div>
  );
}
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
export function EmployeeForm({ employee, close, saved }) {
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false);
  return (
    <Modal title={employee.id ? "Edit employee" : "Add employee"} close={close}>
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          try {
            const values = Object.fromEntries(new FormData(e.currentTarget));
            const result = await api(
              `/employees${employee.id ? `/${employee.id}` : ""}`,
              {
                method: employee.id ? "PATCH" : "POST",
                body: JSON.stringify({
                  employee: { ...values, lock_version: employee.lock_version },
                }),
              },
            );
            saved(result);
          } catch (e) {
            setError(e.message);
          } finally {
            setBusy(false);
          }
        }}
      >
        <div className="form-grid">
          {[
            ["name", "Full name"],
            ["employee_code", "Employee ID"],
            ["email", "Email"],
            ["country", "Country"],
            ["department", "Department"],
            ["level", "Level"],
          ].map(([key, label]) => (
            <label key={key}>
              {label}
              <input
                required
                maxLength={120}
                type={key === "email" ? "email" : "text"}
                name={key}
                defaultValue={employee[key] || ""}
              />
            </label>
          ))}
          <label>
            Status
            <select name="status" defaultValue={employee.status || "active"}>
              <option>active</option>
              <option>inactive</option>
            </select>
          </label>
        </div>
        {error && (
          <div role="alert" className="alert">
            {error}
          </div>
        )}
        <button className="primary" disabled={busy}>
          {busy ? "Saving…" : "Save employee"}
        </button>
      </form>
    </Modal>
  );
}
export function SalaryForm({ employee, currencies, close, saved }) {
  const current = employee.history.find((s) => s.effective_on <= today());
  const [components, setComponents] = useState(
    Object.entries(
      current?.components || { Basic: "", HRA: "", "Special Allowance": "" },
    ),
  );
  const [currency, setCurrency] = useState(current?.currency || "INR"),
    [error, setError] = useState(""),
    [busy, setBusy] = useState(false);
  const total = components.reduce(
    (sum, [, value]) => sum + Number(value || 0),
    0,
  );
  return (
    <Modal title="Record salary change" close={close}>
      <p className="muted">
        Enter annual component amounts. This creates a new version and preserves
        previous salaries.
      </p>
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          setError("");
          try {
            if (
              new Set(components.map(([name]) => name.trim())).size !==
              components.length
            )
              throw new Error("Component names must be unique");
            const values = Object.fromEntries(new FormData(e.currentTarget));
            await api(`/employees/${employee.id}/compensations`, {
              method: "POST",
              body: JSON.stringify({
                lock_version: employee.lock_version,
                compensation: {
                  ...values,
                  currency,
                  components: Object.fromEntries(
                    components.map(([name, amount]) => [name.trim(), amount]),
                  ),
                },
              }),
            });
            saved();
          } catch (e) {
            setError(e.message);
          } finally {
            setBusy(false);
          }
        }}
      >
        <div className="form-grid">
          <label>
            Effective date
            <input
              name="effective_on"
              type="date"
              required
              defaultValue={today()}
            />
          </label>
          <label>
            Currency
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
            >
              {currencies.map((c) => (
                <option key={c}>{c}</option>
              ))}
            </select>
          </label>
          <label>
            Annual CTC
            <input
              name="annual_ctc"
              type="number"
              min="1"
              step={currency === "JPY" ? "1" : "0.01"}
              required
              defaultValue={current?.annual_ctc || ""}
            />
          </label>
          <label>
            Reason
            <input
              name="reason"
              required
              maxLength={500}
              placeholder="Annual evaluation"
            />
          </label>
        </div>
        <h3>Annual breakdown</h3>
        {components.map(([name, value], index) => (
          <div className="component" key={index}>
            <input
              aria-label={`Component ${index + 1} name`}
              required
              value={name}
              onChange={(e) =>
                setComponents((rows) =>
                  rows.map((r, i) =>
                    i === index ? [e.target.value, r[1]] : r,
                  ),
                )
              }
            />
            <input
              aria-label={`Component ${index + 1} amount`}
              type="number"
              min="0"
              step={currency === "JPY" ? "1" : "0.01"}
              required
              value={value}
              onChange={(e) =>
                setComponents((rows) =>
                  rows.map((r, i) =>
                    i === index ? [r[0], e.target.value] : r,
                  ),
                )
              }
            />
            <button
              type="button"
              aria-label={`Remove component ${index + 1}`}
              onClick={() =>
                setComponents((rows) => rows.filter((_, i) => i !== index))
              }
            >
              <X size={16} />
            </button>
          </div>
        ))}
        <button
          type="button"
          disabled={components.length >= 20}
          onClick={() => setComponents((rows) => [...rows, ["", ""]])}
        >
          + Add component
        </button>
        <div className="preview">
          <span>
            Component total <strong>{money(total, currency)}</strong>
          </span>
          <span>
            Monthly equivalent <strong>{money(total / 12, currency)}</strong>
          </span>
        </div>
        <p className="small muted">
          The annual component total must equal annual CTC. The server validates
          exact amounts before saving.
        </p>
        {error && (
          <div role="alert" className="alert">
            {error}
          </div>
        )}
        <button className="primary" disabled={busy}>
          {busy ? "Saving…" : "Save compensation version"}
        </button>
      </form>
    </Modal>
  );
}
export function ImportForm({ close, saved }) {
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false),
    [file, setFile] = useState(null);
  return (
    <Modal title="Import employees" close={close}>
      <p className="muted">
        Add new employees with their initial compensation. Existing employees
        are never overwritten. If any row fails, nothing is imported.
      </p>
      <p className="small">
        Use the{" "}
        <a href="/import-template.csv" download>
          CSV template
        </a>
        . Maximum 5 MB / 10,000 rows. Components contain annual amounts as JSON.
      </p>
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          if (!file) return;
          setBusy(true);
          setError("");
          try {
            if (file.size > 5 * 1024 * 1024)
              throw new Error("File exceeds 5 MB");
            await api("/transfers", {
              method: "POST",
              body: JSON.stringify({ csv: await file.text() }),
            });
            saved();
          } catch (e) {
            setError(e.message);
          } finally {
            setBusy(false);
          }
        }}
      >
        <label>
          CSV file
          <input
            type="file"
            accept=".csv,text/csv"
            required
            onChange={(e) => setFile(e.target.files[0])}
          />
        </label>
        {error && (
          <pre role="alert" className="alert">
            {error}
          </pre>
        )}
        <button disabled={busy} className="primary">
          {busy ? "Importing…" : "Import employees"}
        </button>
      </form>
    </Modal>
  );
}
