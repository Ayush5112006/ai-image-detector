/* ═══════════════════════════════════════════════════════════════════════════
   ChitraVision AI — Application Logic
   Handles auth, file upload, detection API calls, history, particles, and
   page navigation.  Talks to the Node.js backend at API_BASE.
   ═══════════════════════════════════════════════════════════════════════════ */

// ── CONFIG ───────────────────────────────────────────────────────────────────
const API_BASE = 'https://ai-image-detector-ebon.vercel.app/api';

// ── STATE ────────────────────────────────────────────────────────────────────
let authToken = localStorage.getItem('cv_token') || null;
let currentUser = JSON.parse(localStorage.getItem('cv_user') || 'null');

// ── DOM HELPERS ──────────────────────────────────────────────────────────────
const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

// ── TOAST NOTIFICATIONS ──────────────────────────────────────────────────────
function toast(msg, type = 'info', ms = 3500) {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.textContent = msg;
  $('#toast-container').appendChild(el);
  setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 350); }, ms);
}

// ── API WRAPPER ──────────────────────────────────────────────────────────────
async function api(path, opts = {}) {
  const headers = { ...(opts.headers || {}) };
  if (authToken) headers['Authorization'] = `Bearer ${authToken}`;
  // Don't set Content-Type for FormData — browser handles boundary
  if (opts.body && !(opts.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(opts.body);
  }
  const res = await fetch(`${API_BASE}${path}`, { ...opts, headers });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.message || json.error || `Request failed (${res.status})`);
  return json;
}

// ── AUTH HELPERS ──────────────────────────────────────────────────────────────
function saveAuth(token, user) {
  authToken = token;
  currentUser = user;
  localStorage.setItem('cv_token', token);
  localStorage.setItem('cv_user', JSON.stringify(user));
}
function clearAuth() {
  authToken = null;
  currentUser = null;
  localStorage.removeItem('cv_token');
  localStorage.removeItem('cv_user');
}
function isLoggedIn() {
  return Boolean(authToken);
}

// ── PAGE NAVIGATION ──────────────────────────────────────────────────────────
const pages = ['landing', 'login', 'register', 'forgot', 'dashboard'];
function showPage(name) {
  pages.forEach((p) => {
    const el = $(`#page-${p}`);
    if (el) el.classList.toggle('active', p === name);
  });
  updateNavLinks();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateNavLinks() {
  const nav = $('#nav-links');
  nav.innerHTML = '';
  if (isLoggedIn()) {
    const name = currentUser?.name || 'User';
    nav.innerHTML = `
      <span style="color:var(--text-2);font-size:.85rem">Hi, <strong style="color:var(--text-1)">${escHtml(name)}</strong></span>
      <button class="btn btn-ghost btn-sm" id="nav-dashboard">Dashboard</button>
      <button class="btn btn-outline btn-sm" id="nav-logout">Logout</button>
    `;
    $('#nav-dashboard').onclick = () => showPage('dashboard');
    $('#nav-logout').onclick = () => { clearAuth(); showPage('landing'); toast('Signed out', 'info'); };
  } else {
    nav.innerHTML = `
      <button class="btn btn-ghost btn-sm" id="nav-login">Sign In</button>
      <button class="btn btn-primary btn-sm" id="nav-register">Get Started</button>
    `;
    $('#nav-login').onclick = () => showPage('login');
    $('#nav-register').onclick = () => showPage('register');
  }
}

// ── ESCAPE HTML ──────────────────────────────────────────────────────────────
function escHtml(str) {
  const d = document.createElement('div');
  d.textContent = str;
  return d.innerHTML;
}

// ── BUTTON LOADING STATE ─────────────────────────────────────────────────────
function btnLoading(btn, loading) {
  const text = btn.querySelector('.btn-text');
  const loader = btn.querySelector('.btn-loader');
  if (text) text.classList.toggle('hidden', loading);
  if (loader) loader.classList.toggle('hidden', !loading);
  btn.disabled = loading;
}

// ══════════════════════════════════════════════════════════════════════════════
//   PARTICLES BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
(function initParticles() {
  const canvas = $('#particles-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  let w, h, particles = [];
  const COUNT = 55;

  function resize() {
    w = canvas.width = window.innerWidth;
    h = canvas.height = window.innerHeight;
  }

  function createParticles() {
    particles = [];
    for (let i = 0; i < COUNT; i++) {
      particles.push({
        x: Math.random() * w,
        y: Math.random() * h,
        r: Math.random() * 1.8 + .5,
        dx: (Math.random() - .5) * .4,
        dy: (Math.random() - .5) * .4,
        alpha: Math.random() * .35 + .1,
      });
    }
  }

  function draw() {
    ctx.clearRect(0, 0, w, h);
    for (const p of particles) {
      p.x += p.dx; p.y += p.dy;
      if (p.x < 0) p.x = w; if (p.x > w) p.x = 0;
      if (p.y < 0) p.y = h; if (p.y > h) p.y = 0;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(129,140,248,${p.alpha})`;
      ctx.fill();
    }
    // Lines
    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const dx = particles[i].x - particles[j].x;
        const dy = particles[i].y - particles[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 140) {
          ctx.beginPath();
          ctx.moveTo(particles[i].x, particles[i].y);
          ctx.lineTo(particles[j].x, particles[j].y);
          ctx.strokeStyle = `rgba(99,102,241,${.06 * (1 - dist / 140)})`;
          ctx.lineWidth = .6;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(draw);
  }

  resize();
  createParticles();
  draw();
  window.addEventListener('resize', () => { resize(); createParticles(); });
})();

// ══════════════════════════════════════════════════════════════════════════════
//   NAVBAR SCROLL EFFECT
// ══════════════════════════════════════════════════════════════════════════════
window.addEventListener('scroll', () => {
  $('#navbar').classList.toggle('scrolled', window.scrollY > 30);
});

// ══════════════════════════════════════════════════════════════════════════════
//   HERO ANIMATED COUNTERS
// ══════════════════════════════════════════════════════════════════════════════
function animateCounters() {
  $$('.stat-number[data-count]').forEach((el) => {
    const target = parseFloat(el.dataset.count);
    const isFloat = target % 1 !== 0;
    const duration = 1800;
    const start = performance.now();
    function tick(now) {
      const progress = Math.min((now - start) / duration, 1);
      const ease = 1 - Math.pow(1 - progress, 3);
      el.textContent = isFloat ? (target * ease).toFixed(1) : Math.round(target * ease);
      if (progress < 1) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//   EVENT WIRING
// ══════════════════════════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  // Decide initial page
  if (isLoggedIn()) {
    showPage('dashboard');
    loadDashboard();
  } else {
    showPage('landing');
    animateCounters();
  }

  // ── Hero buttons ──
  $('#hero-get-started').onclick = () => showPage('register');
  $('#hero-learn-more').onclick = () => {
    document.getElementById('how-it-works').scrollIntoView({ behavior: 'smooth' });
  };

  // ── Nav logo ──
  $('#nav-logo').onclick = (e) => {
    e.preventDefault();
    showPage(isLoggedIn() ? 'dashboard' : 'landing');
  };

  // ── Auth page links ──
  $('#goto-register').onclick = (e) => { e.preventDefault(); showPage('register'); };
  $('#goto-login-from-reg').onclick = (e) => { e.preventDefault(); showPage('login'); };
  $('#goto-forgot').onclick = (e) => { e.preventDefault(); showPage('forgot'); };
  $('#goto-login-from-forgot').onclick = (e) => { e.preventDefault(); showPage('login'); };

  // ── Toggle password visibility ──
  $$('.toggle-password').forEach((btn) => {
    btn.addEventListener('click', () => {
      const input = btn.parentElement.querySelector('input');
      const isPass = input.type === 'password';
      input.type = isPass ? 'text' : 'password';
      btn.innerHTML = isPass
        ? '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>'
        : '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
    });
  });

  // ── LOGIN ──
  $('#login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = $('#login-submit');
    btnLoading(btn, true);
    try {
      const res = await api('/auth/login', {
        method: 'POST',
        body: { email: $('#login-email').value.trim(), password: $('#login-password').value },
      });
      saveAuth(res.data.token, res.data.user);
      toast('Welcome back!', 'success');
      showPage('dashboard');
      loadDashboard();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      btnLoading(btn, false);
    }
  });

  // ── SEND OTP ──
  $('#send-otp-btn').addEventListener('click', async () => {
    const email = $('#reg-email').value.trim();
    if (!email) { toast('Enter your email first', 'error'); return; }
    const btn = $('#send-otp-btn');
    btn.disabled = true; btn.textContent = 'Sending…';
    try {
      await api('/auth/send-otp', { method: 'POST', body: { email } });
      toast('OTP sent to your email!', 'success');
      btn.textContent = 'Resend';
    } catch (err) {
      toast(err.message, 'error');
      btn.textContent = 'Send OTP';
    } finally {
      btn.disabled = false;
    }
  });

  // ── REGISTER ──
  $('#register-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = $('#register-submit');
    btnLoading(btn, true);
    try {
      const res = await api('/auth/register', {
        method: 'POST',
        body: {
          name: $('#reg-name').value.trim(),
          email: $('#reg-email').value.trim(),
          password: $('#reg-password').value,
          otp: $('#reg-otp').value.trim(),
        },
      });
      saveAuth(res.data.token, res.data.user);
      toast('Account created! 🎉', 'success');
      showPage('dashboard');
      loadDashboard();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      btnLoading(btn, false);
    }
  });

  // ── FORGOT PASSWORD ──
  $('#forgot-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = $('#forgot-submit');
    btnLoading(btn, true);
    try {
      await api('/auth/forgot-password', {
        method: 'POST',
        body: { email: $('#forgot-email').value.trim() },
      });
      toast('If an account exists, a reset code was sent.', 'info');
      $('#reset-form-wrapper').classList.remove('hidden');
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      btnLoading(btn, false);
    }
  });

  // ── RESET PASSWORD ──
  $('#reset-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = $('#reset-submit');
    btnLoading(btn, true);
    try {
      await api('/auth/reset-password', {
        method: 'POST',
        body: {
          email: $('#forgot-email').value.trim(),
          otp: $('#reset-otp').value.trim(),
          newPassword: $('#reset-new-password').value,
        },
      });
      toast('Password reset! You can now sign in.', 'success');
      showPage('login');
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      btnLoading(btn, false);
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  //   FILE UPLOAD & DETECTION
  // ══════════════════════════════════════════════════════════════════════════

  const dropzone = $('#upload-dropzone');
  const fileInput = $('#file-input');

  // Click to browse
  dropzone.addEventListener('click', () => fileInput.click());

  // Drag & drop
  ['dragenter', 'dragover'].forEach((ev) => {
    dropzone.addEventListener(ev, (e) => { e.preventDefault(); dropzone.classList.add('drag-over'); });
  });
  ['dragleave', 'drop'].forEach((ev) => {
    dropzone.addEventListener(ev, (e) => { e.preventDefault(); dropzone.classList.remove('drag-over'); });
  });
  dropzone.addEventListener('drop', (e) => {
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  });

  // File input change
  fileInput.addEventListener('change', () => {
    if (fileInput.files[0]) handleFile(fileInput.files[0]);
    fileInput.value = '';
  });

  // Scan another
  $('#scan-another').addEventListener('click', resetUpload);

  // Refresh history
  $('#refresh-history').addEventListener('click', loadHistory);
});

// ── FILE HANDLER ─────────────────────────────────────────────────────────────
async function handleFile(file) {
  // Validate
  const ALLOWED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (!ALLOWED.includes(file.type)) {
    toast('Unsupported file type. Use JPG, PNG, WebP, or GIF.', 'error');
    return;
  }
  if (file.size > 10 * 1024 * 1024) {
    toast('File too large. Max 10 MB.', 'error');
    return;
  }

  // Show preview
  const reader = new FileReader();
  reader.onload = () => {
    $('#preview-img').src = reader.result;
  };
  reader.readAsDataURL(file);

  $('#preview-filename').textContent = file.name;
  $('#upload-dropzone').classList.add('hidden');
  $('#analysis-panel').classList.remove('hidden');
  $('#result-loader').classList.remove('hidden');
  $('#result-content').classList.add('hidden');

  // Upload
  try {
    const form = new FormData();
    form.append('file', file);

    const res = await api('/detections/analyze', { method: 'POST', body: form });
    const pred = res.data.prediction || res.data.detection || {};
    showResult(pred);
    loadStats(); // Refresh stats
    loadHistory();
  } catch (err) {
    toast(err.message, 'error');
    resetUpload();
  }
}

function showResult(pred) {
  const verdict = pred.verdict || 'Unknown';
  const confidence = Number(pred.confidence) || 0;
  const label = pred.label || pred.resultLabel || verdict;
  const isAi = verdict.toLowerCase() === 'ai';

  // Badge
  const badge = $('#verdict-badge');
  badge.className = `verdict-badge ${isAi ? 'ai' : 'real'}`;
  $('#verdict-icon').textContent = isAi ? '⚠️' : '✅';
  $('#verdict-text').textContent = isAi ? 'AI Generated' : 'Real Image';

  // Confidence ring animation
  const circumference = 2 * Math.PI * 52; // r=52
  const arc = $('#confidence-arc');
  const target = circumference - (confidence / 100) * circumference;
  arc.style.transition = 'stroke-dashoffset 1.2s ease-out';
  arc.style.strokeDashoffset = circumference; // reset
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      arc.style.strokeDashoffset = target;
    });
  });

  // Confidence number animation
  const numEl = $('#confidence-num');
  animateNumber(numEl, confidence, 1200);

  $('#result-label').textContent = label;
  $('#result-model').textContent = pred.modelName || '';

  $('#result-loader').classList.add('hidden');
  $('#result-content').classList.remove('hidden');
}

function animateNumber(el, target, duration) {
  const start = performance.now();
  const isFloat = target % 1 !== 0;
  function tick(now) {
    const p = Math.min((now - start) / duration, 1);
    const ease = 1 - Math.pow(1 - p, 3);
    el.textContent = isFloat ? (target * ease).toFixed(1) : Math.round(target * ease);
    if (p < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}

function resetUpload() {
  $('#upload-dropzone').classList.remove('hidden');
  $('#analysis-panel').classList.add('hidden');
  $('#result-content').classList.add('hidden');
  $('#result-loader').classList.remove('hidden');
  // Reset arc
  const arc = $('#confidence-arc');
  arc.style.transition = 'none';
  arc.style.strokeDashoffset = 2 * Math.PI * 52;
}

// ══════════════════════════════════════════════════════════════════════════════
//   DASHBOARD DATA
// ══════════════════════════════════════════════════════════════════════════════
async function loadDashboard() {
  loadStats();
  loadHistory();
}

async function loadStats() {
  try {
    const res = await api('/user/stats');
    const s = res.data.stats;
    $('#stat-total').textContent = s.totalScans;
    $('#stat-fakes').textContent = s.fakesFound;
    $('#stat-real').textContent = s.cleared;
    $('#stat-xp').textContent = s.xp;
    $('#stat-level').textContent = s.level;
  } catch (err) {
    // Silently fail
  }
}

async function loadHistory() {
  try {
    const res = await api('/detections');
    const detections = res.data.detections || [];
    renderHistory(detections);
  } catch (err) {
    // Silently fail
  }
}

function renderHistory(detections) {
  const list = $('#history-list');
  if (!detections.length) {
    list.innerHTML = '<div class="history-empty"><p>No scans yet. Upload your first image above! 🚀</p></div>';
    return;
  }
  list.innerHTML = detections.map((d) => {
    const isAi = d.verdict === 'AI';
    const ago = timeAgo(d.createdAt);
    return `
      <div class="history-item" data-id="${d._id}">
        <div class="history-verdict ${isAi ? 'ai' : 'real'}">${isAi ? 'AI' : '✓'}</div>
        <div class="history-info">
          <div class="history-filename">${escHtml(d.fileName || 'Image')}</div>
          <div class="history-meta">${escHtml(d.category || 'image')} · ${ago}</div>
        </div>
        <div class="history-confidence" style="color:${isAi ? 'var(--clr-ai)' : 'var(--clr-real)'}">
          ${d.confidence}%
        </div>
        <button class="history-delete" title="Delete scan" data-id="${d._id}">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
        </button>
      </div>
    `;
  }).join('');

  // Delete buttons
  list.querySelectorAll('.history-delete').forEach((btn) => {
    btn.addEventListener('click', async (e) => {
      e.stopPropagation();
      const id = btn.dataset.id;
      try {
        await api(`/detections/${id}`, { method: 'DELETE' });
        toast('Scan deleted', 'info');
        loadHistory();
        loadStats();
      } catch (err) {
        toast(err.message, 'error');
      }
    });
  });
}

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(dateStr).toLocaleDateString();
}
