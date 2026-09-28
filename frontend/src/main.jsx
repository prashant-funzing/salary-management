import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  Users,
  ChartNoAxesCombined,
  Wallet,
  Search,
  Plus,
  ArrowUpRight,
  LogOut,
  X,
  ChevronLeft,
  ChevronRight,
  History,
  Building2,
} from "lucide-react";
import { api, money, today } from "./api";
import "./style.css";
import {
  Stat,
  Modal,
  Login,
  EmployeeForm,
  SalaryForm,
  ImportForm,
} from "./components";

function App() {
  const [user, setUser] = useState(undefined),
    [view, setView] = useState("employees"),
    [error, setError] = useState("");
  const [filters, setFilters] = useState({
    q: "",
    country: "",
    department: "",
    level: "",
    status: "active",
  });
  const [options, setOptions] = useState({
    country: [],
    department: [],
    level: [],
    currencies: [],
  });
  const [data, setData] = useState(null),
    [page, setPage] = useState(1),
    [revision, setRevision] = useState(0);
  const [selected, setSelected] = useState(null),
    [editing, setEditing] = useState(null),
    [salary, setSalary] = useState(false),
    [importing, setImporting] = useState(false);
  const [report, setReport] = useState(null),
    [asOf, setAsOf] = useState(today()),
    [groupBy, setGroupBy] = useState("department");
  useEffect(() => {
    api("/session")
      .then((d) => setUser(d.user))
      .catch((e) => setError(e.message));
  }, []);
  useEffect(() => {
    if (user)
      api("/employees/options")
        .then(setOptions)
        .catch((e) => setError(e.message));
  }, [user, revision]);
  useEffect(() => {
    if (!user) return;
    let active = true;
    setData(null);
    const timer = setTimeout(
      () =>
        api(`/employees?${new URLSearchParams({ ...filters, page })}`)
          .then((d) => {
            if (active) setData(d);
          })
          .catch((e) => {
            if (active) setError(e.message);
          }),
      200,
    );
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [user, filters, page, revision]);
  useEffect(() => {
    if (!user) return;
    let active = true;
    api(
      `/reports?${new URLSearchParams({ ...filters, as_of: asOf, group_by: groupBy })}`,
    )
      .then((d) => {
        if (active) setReport(d);
      })
      .catch((e) => {
        if (active) setError(e.message);
      });
    return () => {
      active = false;
    };
  }, [user, filters, revision, asOf, groupBy]);
  async function openEmployee(id) {
    try {
      setSelected(await api(`/employees/${id}`));
    } catch (e) {
      setError(e.message);
    }
  }
  const refresh = () => setRevision((r) => r + 1);
  if (user === undefined)
    return <div className="loading">{error || "Loading ACME…"}</div>;
  if (!user) return <Login onLogin={setUser} />;
  return (
    <div className="layout">
      <aside>
        <div className="brand">
          <div className="brand-icon">
            <Building2 size={22} />
          </div>
          acme<span>people</span>
        </div>
        <p className="nav-label">WORKSPACE</p>
        <button
          className={view === "employees" ? "nav active" : "nav"}
          onClick={() => setView("employees")}
        >
          <Users size={18} />
          Employees
        </button>
        <button
          className={view === "reports" ? "nav active" : "nav"}
          onClick={() => setView("reports")}
        >
          <ChartNoAxesCombined size={18} />
          Compensation insights
        </button>
        <div className="sidebar-bottom">
          <div className="avatar">HR</div>
          <div>
            <strong>HR workspace</strong>
            <small>{user.email}</small>
          </div>
          <button
            aria-label="Sign out"
            className="icon"
            onClick={async () => {
              await api("/session", { method: "DELETE" });
              setUser(null);
            }}
          >
            <LogOut size={17} />
          </button>
        </div>
      </aside>
      <main>
        <header>
          <span>
            Workspace <span className="slash">/</span>{" "}
            {view === "employees" ? "Employees" : "Compensation insights"}
          </span>
          <span className="tag">ACME ORGANIZATION</span>
        </header>
        <div className="content">
          <div className="title-row">
            <div>
              <div className="eyebrow">PEOPLE & COMPENSATION</div>
              <h1>
                {view === "employees"
                  ? "Your people, in one place."
                  : "Understand how you pay."}
              </h1>
              <p className="muted">
                {view === "employees"
                  ? "Manage your global team and make every compensation decision clear."
                  : "Explore compensation across your workforce, with currencies kept separate."}
              </p>
            </div>
            {view === "employees" && (
              <div className="actions">
                <button onClick={() => setImporting(true)}>Import CSV</button>
                <a
                  className="button-link"
                  href={`/api/transfers?${new URLSearchParams(filters)}`}
                >
                  Export CSV
                </a>
                <button className="primary" onClick={() => setEditing({})}>
                  <Plus size={17} />
                  Add employee
                </button>
              </div>
            )}
          </div>
          {error && (
            <div role="alert" className="alert">
              {error}
              <button onClick={() => setError("")} aria-label="Dismiss error">
                <X size={16} />
              </button>
            </div>
          )}
          <div className="stats">
            <Stat
              label="ACTIVE EMPLOYEES"
              value={report?.headcount?.toLocaleString() ?? "—"}
              icon={<Users />}
              detail="Across your filtered workforce"
            />
            <Stat
              label="COUNTRIES"
              value={options.country.length}
              icon={<Building2 />}
              detail="One connected organization"
            />
            <Stat
              label="PAY CURRENCIES"
              value={report?.totals.length ?? "—"}
              icon={<Wallet />}
              detail="Local currency, clear compensation"
            />
          </div>
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>
                  {view === "employees"
                    ? "Employee directory"
                    : "Compensation overview"}
                </h2>
                <p className="muted small">
                  {view === "employees"
                    ? "Find a teammate to view their salary and growth history."
                    : report?.note}
                </p>
              </div>
              <span className="pill">
                {data?.total?.toLocaleString() ?? "…"} employees
              </span>
            </div>
            <div className="filters">
              <label className="search">
                <Search size={17} />
                <input
                  aria-label="Search employees"
                  placeholder="Search name, email or employee ID…"
                  value={filters.q}
                  onChange={(e) => {
                    setFilters({ ...filters, q: e.target.value });
                    setPage(1);
                  }}
                />
              </label>
              <select
                aria-label="Employee status"
                value={filters.status}
                onChange={(e) => {
                  setFilters({ ...filters, status: e.target.value });
                  setPage(1);
                }}
              >
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="">All statuses</option>
              </select>
              {["country", "department", "level"].map((field) => (
                <select
                  key={field}
                  aria-label={field}
                  value={filters[field]}
                  onChange={(e) => {
                    setFilters({ ...filters, [field]: e.target.value });
                    setPage(1);
                  }}
                >
                  <option value="">
                    All{" "}
                    {field === "country"
                      ? "countries"
                      : field === "department"
                        ? "departments"
                        : "levels"}
                  </option>
                  {options[field].map((v) => (
                    <option key={v}>{v}</option>
                  ))}
                </select>
              ))}
            </div>
            {view === "employees" ? (
              <>
                <div className="table-scroll">
                  <table>
                    <thead>
                      <tr>
                        <th>EMPLOYEE</th>
                        <th>DEPARTMENT / LEVEL</th>
                        <th>COUNTRY</th>
                        <th>ANNUAL CTC</th>
                        <th>MONTHLY CTC</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      {!data ? (
                        <tr>
                          <td colSpan="6" className="empty">
                            Loading employees…
                          </td>
                        </tr>
                      ) : data.employees.length === 0 ? (
                        <tr>
                          <td colSpan="6" className="empty">
                            No employees match your filters.
                          </td>
                        </tr>
                      ) : (
                        data.employees.map((e) => (
                          <tr key={e.id}>
                            <td>
                              <button
                                className="person"
                                onClick={() => openEmployee(e.id)}
                              >
                                <span className="avatar">
                                  {e.name
                                    .split(" ")
                                    .map((w) => w[0])
                                    .slice(0, 2)
                                    .join("")}
                                </span>
                                <span>
                                  <strong>{e.name}</strong>
                                  <small>
                                    {e.employee_code} · {e.email}
                                  </small>
                                </span>
                              </button>
                            </td>
                            <td>
                              {e.department}
                              <small>{e.level}</small>
                            </td>
                            <td>{e.country}</td>
                            <td className="amount">
                              {e.compensation
                                ? money(
                                    e.compensation.annual_ctc,
                                    e.compensation.currency,
                                  )
                                : "Not set"}
                              <small>{e.compensation?.currency}</small>
                            </td>
                            <td>
                              {e.compensation
                                ? money(
                                    e.compensation.monthly_ctc,
                                    e.compensation.currency,
                                  )
                                : "—"}
                            </td>
                            <td>
                              <button
                                className="icon"
                                aria-label={`View ${e.name}`}
                                onClick={() => openEmployee(e.id)}
                              >
                                <ArrowUpRight size={17} />
                              </button>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
                <footer>
                  <span>
                    Showing {data?.total ? (page - 1) * 25 + 1 : 0}–
                    {Math.min(page * 25, data?.total || 0)} of{" "}
                    {data?.total?.toLocaleString() || 0}
                  </span>
                  <div>
                    <button
                      disabled={page === 1}
                      onClick={() => setPage((p) => p - 1)}
                      aria-label="Previous page"
                    >
                      <ChevronLeft size={16} />
                    </button>
                    <span>Page {page}</span>
                    <button
                      disabled={!data || page * 25 >= data.total}
                      onClick={() => setPage((p) => p + 1)}
                      aria-label="Next page"
                    >
                      <ChevronRight size={16} />
                    </button>
                  </div>
                </footer>
              </>
            ) : (
              <div className="reports">
                <div className="report-controls">
                  <label>
                    Salary effective on
                    <input
                      type="date"
                      value={asOf}
                      onChange={(e) => setAsOf(e.target.value)}
                    />
                  </label>
                  <label>
                    Group by
                    <select
                      value={groupBy}
                      onChange={(e) => setGroupBy(e.target.value)}
                    >
                      {["department", "country", "level"].map((v) => (
                        <option key={v}>{v}</option>
                      ))}
                    </select>
                  </label>
                </div>
                {report?.planning_equivalent && (
                  <div className="planning-total">
                    <span className="eyebrow">
                      ILLUSTRATIVE INR PLANNING EQUIVALENT
                    </span>
                    <h2>
                      {money(report.planning_equivalent.annual_ctc, "INR")} /
                      year
                    </h2>
                    <p className="small muted">
                      {report.planning_equivalent.note}
                    </p>
                    <details>
                      <summary>View conversion assumptions</summary>
                      <p className="small">
                        {Object.entries(report.planning_equivalent.rates)
                          .map(
                            ([currency, rate]) => `1 ${currency} = ${rate} INR`,
                          )
                          .join(" · ")}
                      </p>
                    </details>
                  </div>
                )}
                <div className="currency-cards">
                  {report?.totals.map((t) => (
                    <div className="currency-card" key={t.currency}>
                      <span className="pill">{t.currency}</span>
                      <h2>{money(t.annual_ctc, t.currency)}</h2>
                      <p>Annual CTC · {t.count.toLocaleString()} employees</p>
                      <small>Median {money(t.median, t.currency)}</small>
                    </div>
                  ))}
                </div>
                <h3>Annual CTC by {groupBy}</h3>
                <table>
                  <thead>
                    <tr>
                      <th>GROUP</th>
                      <th>CURRENCY</th>
                      <th>ANNUAL CTC</th>
                    </tr>
                  </thead>
                  <tbody>
                    {report?.groups.map((g) => (
                      <tr key={`${g.name}-${g.currency}`}>
                        <td>{g.name}</td>
                        <td>{g.currency}</td>
                        <td>{money(g.annual_ctc, g.currency)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
          <p className="footnote">
            Compensation figures are CTC equivalents, before taxes and
            deductions. Monthly figures may include rounding.
          </p>
        </div>
      </main>
      {importing && (
        <ImportForm
          close={() => setImporting(false)}
          saved={() => {
            setImporting(false);
            refresh();
          }}
        />
      )}
      {selected && (
        <Modal title={selected.name} close={() => setSelected(null)} wide>
          <div className="detail-meta">
            {selected.employee_code} · {selected.department} · {selected.level}{" "}
            · {selected.country}
          </div>
          <div className="actions">
            <button onClick={() => setEditing(selected)}>Edit employee</button>
            <button className="primary" onClick={() => setSalary(true)}>
              <Plus size={16} />
              Record salary change
            </button>
          </div>
          <h3>
            <History size={18} /> Compensation history
          </h3>
          {selected.history.length === 0 && (
            <p className="empty">No salary recorded yet.</p>
          )}
          {selected.history.map((s, index) => {
            const previous = selected.history[index + 1];
            const growth =
              previous && previous.currency === s.currency
                ? (
                    (Number(s.annual_ctc) / Number(previous.annual_ctc) - 1) *
                    100
                  ).toFixed(1)
                : null;
            return (
              <div className="salary-version" key={s.id}>
                <div className="version-top">
                  <div>
                    <span className="pill">
                      {s.effective_on > today()
                        ? "Scheduled"
                        : index ===
                            selected.history.findIndex(
                              (h) => h.effective_on <= today(),
                            )
                          ? "Current"
                          : "Previous"}
                    </span>
                    <strong>Effective {s.effective_on}</strong>
                  </div>
                  {growth !== null && (
                    <span className="growth">
                      {growth > 0 ? "+" : ""}
                      {growth}%
                    </span>
                  )}
                </div>
                <h2>
                  {money(s.annual_ctc, s.currency)} <small>/ year</small>
                </h2>
                <p className="muted">
                  {money(s.monthly_ctc, s.currency)} / month · {s.reason}
                </p>
                <table>
                  <thead>
                    <tr>
                      <th>COMPONENT</th>
                      <th>ANNUAL</th>
                      <th>MONTHLY</th>
                    </tr>
                  </thead>
                  <tbody>
                    {Object.entries(s.components).map(([name, amount]) => (
                      <tr key={name}>
                        <td>{name}</td>
                        <td>{money(amount, s.currency)}</td>
                        <td>{money(s.monthly_components[name], s.currency)}</td>
                      </tr>
                    ))}
                    {Number(s.rounding_adjustment) !== 0 && (
                      <tr>
                        <td>Monthly rounding adjustment</td>
                        <td>—</td>
                        <td>{money(s.rounding_adjustment, s.currency)}</td>
                      </tr>
                    )}
                  </tbody>
                </table>
                <small>
                  Recorded by {s.recorded_by} ·{" "}
                  {new Date(s.created_at).toLocaleDateString()}
                </small>
              </div>
            );
          })}
        </Modal>
      )}
      {editing && (
        <EmployeeForm
          employee={editing}
          close={() => setEditing(null)}
          saved={(e) => {
            setEditing(null);
            refresh();
            openEmployee(e.id);
          }}
        />
      )}
      {salary && selected && (
        <SalaryForm
          employee={selected}
          currencies={options.currencies}
          close={() => setSalary(false)}
          saved={() => {
            setSalary(false);
            refresh();
            openEmployee(selected.id);
          }}
        />
      )}
    </div>
  );
}
createRoot(document.getElementById("root")).render(<App />);
