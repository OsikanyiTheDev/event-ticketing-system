// ─────────────────────────────────────────────────────────────
// Event Registration UI — calls the serverless REST API.
// API URL is set in config.js (window.API_BASE_URL) by deploy_ui.sh.
// ─────────────────────────────────────────────────────────────

const API = (window.API_BASE_URL || "").replace(/\/$/, ""); // strip trailing slash

// Event icons for a bit of visual variety
const ICONS = ["🎤", "🚀", "☁️", "📊", "🛠️", "🎯", "💡", "🤝"];
function iconFor(i) {
  return ICONS[i % ICONS.length];
}

// ───────── Helpers ─────────
async function api(path, options = {}) {
  const res = await fetch(`${API}${path}`, options);
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body.success === false) {
    throw new Error(body.error || `Request failed (${res.status})`);
  }
  return body.data;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]
  );
}

function toast(message, type = "") {
  const el = document.getElementById("toast");
  el.textContent = message;
  el.className = `toast ${type}`;
  el.hidden = false;
  clearTimeout(toast._t);
  toast._t = setTimeout(() => (el.hidden = true), 4000);
}

// ───────── Tabs ─────────
document.querySelectorAll(".tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach((b) => b.classList.remove("active"));
    document.querySelectorAll(".tab-panel").forEach((p) => p.classList.remove("active"));
    btn.classList.add("active");
    document.getElementById(`tab-${btn.dataset.tab}`).classList.add("active");
  });
});

// ───────── Load & render events ─────────
let EVENTS = [];
async function loadEvents() {
  const grid = document.getElementById("events-grid");
  const loading = document.getElementById("loading");
  const count = document.getElementById("event-count");
  try {
    const data = await api("/events");
    EVENTS = data.events || [];
    loading.remove();
    count.textContent = `${EVENTS.length} event${EVENTS.length === 1 ? "" : "s"}`;

    if (!EVENTS.length) {
      grid.innerHTML = '<p class="muted">No events yet. Run <code>scripts/seed_events.py</code> first.</p>';
      return;
    }

    grid.innerHTML = EVENTS.map(
      (e, i) => `
      <div class="card">
        <div class="card-banner">${iconFor(i)}</div>
        <div class="card-body">
          <h3>${escapeHtml(e.name)}</h3>
          <p class="meta">📅 ${escapeHtml(e.date || "Date TBA")}</p>
          <p class="meta">📍 ${escapeHtml(e.location || "Location TBA")}</p>
          <p class="meta">🎟️ ${escapeHtml(String(e.capacity ?? "—"))} seats</p>
          ${e.description ? `<p class="desc">${escapeHtml(e.description)}</p>` : ""}
          <div class="card-cta">
            <button class="primary block" onclick="openRegister('${escapeHtml(e.event_id)}')">Register</button>
          </div>
        </div>
      </div>`
    ).join("");
  } catch (err) {
    loading.textContent = `⚠️ ${err.message}`;
    loading.className = "muted";
    toast(err.message, "err");
  }
}

// ───────── Register modal ─────────
function openRegister(eventId) {
  const ev = EVENTS.find((e) => e.event_id === eventId);
  if (!ev) return;
  document.getElementById("reg-event").value = eventId;
  document.getElementById("modal-event-name").textContent = ev.name;
  document.getElementById("reg-name").value = "";
  document.getElementById("reg-email").value = "";
  document.getElementById("modal").hidden = false;
  document.getElementById("reg-name").focus();
}
window.openRegister = openRegister;

document.getElementById("modal-close").addEventListener("click", () => (document.getElementById("modal").hidden = true));
document.getElementById("modal").addEventListener("click", (e) => {
  if (e.target.id === "modal") document.getElementById("modal").hidden = true;
});

document.getElementById("register-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const btn = e.target.querySelector("button[type=submit]");
  btn.disabled = true;
  btn.textContent = "Registering…";
  try {
    const data = await api("/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        event_id: document.getElementById("reg-event").value,
        name: document.getElementById("reg-name").value.trim(),
        email: document.getElementById("reg-email").value.trim(),
      }),
    });
    document.getElementById("modal").hidden = true;
    toast(`✅ Registered! Confirmation ID: ${data.registration_id.slice(0, 8)}… Check your email 📧`, "ok");
  } catch (err) {
    toast(err.message, "err");
  } finally {
    btn.disabled = false;
    btn.textContent = "Confirm Registration 🎫";
  }
});

// ───────── Look up registrations ─────────
document.getElementById("lookup-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("lookup-email").value.trim();
  const out = document.getElementById("registrations");
  out.innerHTML = '<p class="muted">Looking up…</p>';
  try {
    const data = await api(`/registrations/${encodeURIComponent(email)}`);
    const regs = data.registrations || [];
    if (!regs.length) {
      out.innerHTML = '<p class="muted">No registrations found for that email.</p>';
      return;
    }
    out.innerHTML = regs
      .map(
        (r) => `
        <div class="ticket">
          <div class="t-info">
            <div class="t-event">${escapeHtml(eventName(r.event_id))}</div>
            <div class="t-meta">ID: ${escapeHtml(r.registration_id.slice(0, 8))}… · ${escapeHtml(r.created_at || "")}</div>
          </div>
          <span class="badge ${r.status === "cancelled" ? "cancelled" : ""}">${escapeHtml(r.status)}</span>
          ${r.status !== "cancelled" ? `<button class="small danger" onclick="cancelReg('${escapeHtml(r.registration_id)}')">Cancel</button>` : ""}
        </div>`
      )
      .join("");
  } catch (err) {
    out.innerHTML = `<p class="muted">⚠️ ${err.message}</p>`;
    toast(err.message, "err");
  }
});

function eventName(id) {
  const ev = EVENTS.find((e) => e.event_id === id);
  return ev ? ev.name : id;
}

async function cancelReg(id) {
  if (!confirm("Cancel this registration?")) return;
  try {
    await api(`/registration/${encodeURIComponent(id)}`, { method: "DELETE" });
    toast("Registration cancelled.", "ok");
    document.getElementById("lookup-form").dispatchEvent(new Event("submit"));
  } catch (err) {
    toast(err.message, "err");
  }
}
window.cancelReg = cancelReg;

// ───────── init ─────────
if (!API || API.includes("REPLACE_ME")) {
  toast("⚠️ API URL not configured. Run: bash scripts/deploy_ui.sh", "err");
}
loadEvents();
