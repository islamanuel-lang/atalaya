/* global */
const API = "__API_BASE__";
const TESTFLIGHT = "__TESTFLIGHT__";
const APK = "__APK__";

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

/* Detección de sistema */
function detectOS() {
  const ua = navigator.userAgent;
  const ios = /iPhone|iPad|iPod/.test(ua);
  return { ios, android: /Android/.test(ua) };
}

function paintInstall() {
  const { ios, android } = detectOS();
  for (const el of $$("[data-install]")) {
    if (el.dataset.install === "ios") {
      el.href = TESTFLIGHT;
      el.classList.toggle("hidden", !ios);
    }
    if (el.dataset.install === "android") {
      el.href = APK;
      el.classList.toggle("hidden", !android);
    }
    if (el.dataset.install === "web") el.href = "/check";
  }
  const note = $("[data-os-note]");
  if (note) {
    if (ios) note.textContent = "iPhone detectado. TestFlight instala sin perfiles ni confiar nada.";
    else if (android) note.textContent = "Android detectado: instala el APK y permite el origen desconocido.";
    else note.textContent = "Puedes comprobar tu frase aquí mismo, sin instalar nada.";
  }
}

/* Validación BIP-39 en cliente */
let words = null;
let wordIndex = null;

async function loadWords() {
  if (words) return;
  const res = await fetch("/assets/bip39.txt");
  words = (await res.text()).trim().split("\n");
  wordIndex = new Map(words.map((w, i) => [w, i]));
}

function normalize(text) {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .split(/[^a-z]+/)
    .filter(Boolean);
}

async function validate(text) {
  await loadWords();
  const tokens = normalize(text);
  if (tokens.length === 0) return { tokens, message: "", ok: false };
  if (![12, 15, 18, 21, 24].includes(tokens.length)) {
    return { tokens, message: `Faltan palabras: ${tokens.length} de 12.`, ok: false };
  }
  for (let i = 0; i < tokens.length; i++) {
    if (!wordIndex.has(tokens[i])) {
      return { tokens, message: `La palabra ${i + 1} no está en el diccionario.`, ok: false };
    }
  }
  const indices = tokens.map((t) => wordIndex.get(t));
  const total = tokens.length * 11;
  const cs = total / 33;
  const ent = total - cs;
  const bits = indices.flatMap((value) => Array.from({ length: 11 }, (_, k) => (value >> (10 - k)) & 1));
  const bytes = new Uint8Array(ent / 8);
  for (let i = 0; i < ent; i++) if (bits[i]) bytes[i >> 3] |= 0x80 >> (i & 7);
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  for (let i = 0; i < cs; i++) {
    const expected = (digest[i >> 3] >> (7 - (i & 7))) & 1;
    if (bits[ent + i] !== expected) return { tokens, message: "Revisa el orden: el checksum no cuadra.", ok: false };
  }
  return { tokens, message: "Frase válida.", ok: true };
}

/* Flujo del comprobador */
function installID() {
  let id = localStorage.getItem("semencheck.install");
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem("semencheck.install", id);
  }
  return id;
}

function esc(text) {
  return String(text ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
}

function money(value) {
  return new Intl.NumberFormat("es-ES", { style: "currency", currency: "USD", maximumFractionDigits: 2 }).format(value || 0);
}

function renderReport(report) {
  const box = $("#report");
  const addresses = (report.addresses || []).map((a) => `
    <div class="panel" style="margin-bottom:8px">
      <div class="row-between"><span class="eyebrow">${esc(a.chain)}</span><strong>${esc(a.amount.toFixed(8))} ${esc(a.symbol)}</strong></div>
      <div class="addr mute">${esc(a.address)}</div>
    </div>`).join("") || `<p class="mute">Sin saldo visible en las redes comprobadas.</p>`;

  const findings = (report.findings || []).map((f) => `
    <li><strong>${esc(f.detail)}</strong>${f.path ? `<br><span class="addr mute">${esc(f.path)}</span>` : ""}</li>`).join("");

  box.innerHTML = `
    <div class="panel">
      <div class="row-between">
        <h2 style="margin:0">Informe</h2>
        <span class="pill ${esc(report.risk)}">${{ high: "Riesgo alto", medium: "Riesgo medio", low: "Riesgo bajo" }[report.risk] || "Riesgo"}</span>
      </div>
      <p class="mute small">Total visible: ${money(report.totalUsd)}</p>
      <h3>Direcciones</h3>
      ${addresses}
      ${findings ? `<h3>Hallazgos</h3><ul class="small">${findings}</ul>` : ""}
      <div class="notice"><span>Revisa que la dirección coincida con la de tu wallet. Sin coincidencia, la frase no es la tuya.</span></div>
      <div class="row" style="margin-top:12px">
        <a class="btn" data-install="ios" href="${TESTFLIGHT}">Auditar el móvil (iPhone)</a>
        <a class="btn btn-ghost" data-install="android" href="${APK}">Auditar el móvil (Android)</a>
        <button class="btn btn-ghost" id="copy">Copiar informe</button>
      </div>
      <p class="hint" style="margin-top:12px">El comprobador web no revisa tu carrete: eso lo hace la app.</p>
    </div>`;
  box.classList.remove("hidden");
  paintInstall();

  $("#copy")?.addEventListener("click", async () => {
    await navigator.clipboard.writeText(box.innerText);
    $("#copy").textContent = "Copiado";
  });
}

async function submitAudit(event) {
  event.preventDefault();
  const phrase = $("#phrase").value;
  const status = $("#status");
  const button = $("#audit");
  const check = await validate(phrase);
  if (!check.ok) {
    status.textContent = check.message;
    status.className = "hint bad";
    return;
  }
  if (!$("#consent").checked) {
    status.textContent = "Marca el consentimiento para enviar la frase.";
    status.className = "hint bad";
    return;
  }

  button.disabled = true;
  status.textContent = "Consultando filtraciones y saldos…";
  status.className = "hint";
  try {
    const res = await fetch(`${API}/v1/audit`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        installID: `web-${installID()}`,
        phrase: check.tokens.join(" "),
        walletHints: []
      })
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.detail || json.error || "error");
    renderReport(json);
    status.textContent = "";
    $("#report").scrollIntoView({ behavior: "smooth", block: "start" });
  } catch (error) {
    status.textContent = `No se pudo completar: ${error.message}`;
    status.className = "hint bad";
  } finally {
    button.disabled = false;
  }
}

/* Arranque */
document.addEventListener("DOMContentLoaded", () => {
  paintInstall();

  const textarea = $("#phrase");
  if (textarea) {
    loadWords().catch(() => {});
    const seed = new URLSearchParams(location.search).get("seed");
    if (seed) {
      textarea.value = seed;
      setTimeout(() => textarea.dispatchEvent(new Event("input")), 50);
    }
    if (new URLSearchParams(location.search).get("auto") === "1") {
      setTimeout(() => {
        $("#consent").checked = true;
        $("#audit-form").dispatchEvent(new Event("submit", { cancelable: true }));
      }, 400);
    }
    let timer;
    textarea.addEventListener("input", () => {
      clearTimeout(timer);
      const status = $("#status");
      timer = setTimeout(async () => {
        const result = await validate(textarea.value);
        status.textContent = result.message;
        status.className = `hint ${result.ok ? "good" : result.message ? "bad" : ""}`;
        $("#audit").disabled = !result.ok;
      }, 180);
    });
    $("#audit").disabled = true;
    $("#audit-form").addEventListener("submit", submitAudit);
  }

  const paste = $("#paste");
  paste?.addEventListener("click", async () => {
    try {
      textarea.value = await navigator.clipboard.readText();
      textarea.dispatchEvent(new Event("input"));
    } catch {
      textarea.focus();
    }
  });

  const file = $("#photo");
  file?.addEventListener("change", () => {
    const status = $("#status");
    status.textContent = "Foto cargada. El OCR se hace en la app; aquí escribe o pega la frase.";
    status.className = "hint";
  });

  fetch(`${API}/v1/stats`).then((r) => r.json()).then((s) => {
    const el = $("#stats");
    if (el && s.audits) el.textContent = `${s.audits} auditorías · ${s.week} esta semana`;
  }).catch(() => {});
});
