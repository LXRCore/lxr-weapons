/* LXR-WEAPONS — gunsmith counter on the LXR UI Kit | © 2026 iBoss21 / LXRCore
   Works on the server's panel: { shop, weapons[], parts{key→…}, ammo[], cash, prices, returnToSatchel }.
   Every action is a post → RPC; the server answers with a fresh panel. */
(function () {
  const $ = (id) => document.getElementById(id);
  const app = $('app');
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-weapons';
  let D = null, L = {}, sel = null;
  const t = (k, vars) => { let s = L[k] || k.split('.').pop().replace(/_/g, ' '); if (vars) for (const v in vars) s = s.replace('%{' + v + '}', vars[v]); return s; };
  const money = (n) => (Math.round((n || 0) * 100) / 100).toFixed(2);
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({ ok: false }));
  const sound = (name, set) => post('sound', { name, set });
  const STATS = ['damage', 'range', 'rate', 'accuracy', 'reload'];
  const GROUPS = ['barrel', 'sight', 'scope', 'grip', 'stock', 'rifling', 'finish', 'engrave', 'wrap'];

  let toastEl;
  function toast(msg, bad) {
    if (!toastEl) { toastEl = document.createElement('div'); toastEl.className = 'lxr-toast gs-toast'; document.body.appendChild(toastEl); }
    toastEl.textContent = msg; toastEl.classList.toggle('is-bad', !!bad); toastEl.classList.toggle('is-ok', !bad); toastEl.classList.add('show');
    setTimeout(() => toastEl.classList.remove('show'), 2500);
  }
  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { const k = 'ui.' + el.dataset.l; if (L[k]) el.textContent = L[k]; }); }
  const condClass = (q) => q <= 10 ? 'is-bad' : q <= 25 ? 'is-warn' : '';
  const repairPrice = (w) => { const missing = Math.max(0, 100 - w.quality) / 100; if (missing <= 0) return 0; return Math.round(Math.max(D.prices.repairMin, (w.value || 0) * D.prices.repairPct * missing) * (D.shop.priceMult || 1) * 100) / 100; };

  // ─── left: rows ────────────────────────────────────────────────────────
  function renderRows() {
    const host = $('rows'); host.innerHTML = '';
    $('count').textContent = D.weapons.length ? String(D.weapons.length).padStart(2, '0') : '';
    if (!D.weapons.length) { host.innerHTML = `<div class="gs-empty">${esc(t('ui.none'))}</div>`; return; }
    D.weapons.forEach((w, i) => {
      const row = document.createElement('button'); row.className = 'lxr-row lxr-row--compact' + (sel === w.serial ? ' is-active' : '');
      row.innerHTML = `<span class="lxr-row-index">${String(i + 1).padStart(2, '0')}</span><span class="lxr-row-body"><span class="lxr-row-name">${esc(w.label)}</span><span class="lxr-row-sub">${esc(w.categoryLabel || w.category)}${w.drawn ? ' · ' + esc(t('ui.drawn')) : ''}</span></span><span class="lxr-grow"></span><span class="gs-row-cond"><span class="lxr-meter"><span class="lxr-meter-fill ${condClass(w.quality)}" style="width:${Math.max(0, Math.min(100, w.quality))}%"></span></span></span>`;
      row.addEventListener('click', () => { sel = w.serial; sound('NAV_UP'); renderRows(); renderDetail(); });
      host.appendChild(row);
    });
  }
  function renderAmmo() {
    const host = $('ammo'); host.innerHTML = '';
    if (!D.ammo.length) { host.innerHTML = `<div class="gs-empty">—</div>`; return; }
    D.ammo.forEach(a => {
      const row = document.createElement('div'); row.className = 'lxr-row';
      row.innerHTML = `<span class="lxr-row-name">${esc(a.label)}</span><span class="lxr-grow"></span><span class="lxr-row-meta lxr-num">${a.n} ${esc(t('ui.rounds'))}</span>${D.returnToSatchel ? `<button class="lxr-btn lxr-btn-ghost lxr-btn-sm" data-class="${esc(a.class)}">${esc(t('ui.unload'))}</button>` : ''}`;
      const b = row.querySelector('button'); if (b) b.addEventListener('click', () => act('unload', { class: a.class }));
      host.appendChild(row);
    });
  }

  // ─── right: the gun on the counter ────────────────────────────────────
  function block(title, sub) {
    const el = document.createElement('div'); el.className = 'gs-block';
    el.innerHTML = `<div class="gs-block__head"><span class="gs-block__title">${esc(title)}</span>${sub ? `<span class="gs-block__sub">${esc(sub)}</span>` : ''}</div><div class="gs-block__body"></div>`;
    return el;
  }
  function renderDetail() {
    const host = $('detail'); host.innerHTML = '';
    const w = D.weapons.find(x => x.serial === sel);
    if (!w) { host.classList.add('is-empty'); host.innerHTML = `<span class="lxr-mono">${esc(t('ui.pick'))}</span>`; return; }
    host.classList.remove('is-empty');
    const head = document.createElement('div'); head.className = 'gs-head';
    head.innerHTML = `<div><h2 class="lxr-cut gs-name">${esc(w.label)}</h2><div class="gs-facts">${w.maker ? `<span>${esc(t('ui.maker'))} <b>${esc(w.maker)}</b></span>` : ''}<span>${esc(t('ui.era'))} <b>${esc(w.era)}</b></span>${w.clip ? `<span>${esc(t('ui.clip'))} <b>${w.clip}</b></span>` : ''}<span>${esc(t('ui.serial'))} <b>${esc(w.serial)}</b></span></div></div><div class="gs-state ${w.drawn ? 'is-on' : ''}">${esc(t(w.drawn ? 'ui.drawn' : 'ui.stowed'))}</div>`;
    host.appendChild(head);

    // condition + repair
    const price = repairPrice(w);
    const cond = block(t('ui.condition'), w.quality <= 0 ? t('ui.jammed') : w.quality >= 100 ? t('ui.pristine') : '');
    const cb = cond.querySelector('.gs-block__body'); cb.className += ' gs-cond';
    cb.innerHTML = `<div><div class="gs-cond__val"><span>${esc(t('ui.condition'))}</span><b>${Math.floor(w.quality)}%</b></div><div class="lxr-meter"><div class="lxr-meter-fill ${condClass(w.quality)}" style="width:${Math.max(0, Math.min(100, w.quality))}%"></div></div></div><button class="lxr-btn" id="btn-repair" ${price <= 0 ? 'disabled' : ''}>${esc(t('ui.repair'))} · $${money(price)}</button>`;
    cb.querySelector('#btn-repair').addEventListener('click', () => act('repair', { serial: w.serial }, price));
    host.appendChild(cond);

    // stats
    const st = block(t('ui.stats'), '');
    const sb = st.querySelector('.gs-block__body'); sb.className += ' gs-stats';
    STATS.forEach(k => {
      const base = (w.base && w.base[k]) || 0, v = (w.stats && w.stats[k]) || base;
      const el = document.createElement('div'); el.className = 'gs-stat';
      let pips = '';
      for (let i = 1; i <= 10; i++) pips += `<span class="gs-pip ${i <= Math.min(v, base) ? 'is-on' : ''} ${i > base && i <= v ? 'is-mod' : ''}"></span>`;
      el.innerHTML = `<span class="gs-stat__label"><span>${esc(t('ui.' + k))}</span><b class="${v > base ? 'up' : ''}">${v}</b></span><span class="gs-pips">${pips}</span>`;
      sb.appendChild(el);
    });
    host.appendChild(st);

    // parts by group
    const parts = block(t('ui.parts'), '');
    const pb = parts.querySelector('.gs-block__body'); pb.className += ' gs-groups';
    const fitted = new Set(w.components || []);
    GROUPS.forEach(g => {
      const keys = (w.fits || []).filter(k => D.parts[k] && D.parts[k].group === g);
      if (!keys.length) return;
      const row = document.createElement('div'); row.className = 'gs-group';
      row.innerHTML = `<span class="gs-group__label">${esc(t('ui.group_' + g))}</span><div class="gs-chips"></div>`;
      const chips = row.querySelector('.gs-chips');
      keys.forEach(k => {
        const p = D.parts[k]; const on = fitted.has(k);
        const chip = document.createElement('button'); chip.className = 'gs-chip' + (on ? ' is-on' : '');
        chip.innerHTML = `<span>${esc(p.label)}</span><span class="gs-price">${on ? esc(t('ui.fitted')) : '$' + money(p.price)}</span>`;
        chip.title = p.cosmetic ? t('ui.cosmetic') : Object.entries(p.stat || {}).map(([s, d]) => `${t('ui.' + s)} ${d > 0 ? '+' : ''}${d}`).join(' · ');
        chip.addEventListener('click', () => on ? act('strip', { serial: w.serial, key: k }, D.prices.remove) : act('fit', { serial: w.serial, key: k }, p.price));
        chips.appendChild(chip);
      });
      pb.appendChild(row);
    });
    if (!pb.children.length) pb.innerHTML = `<span class="gs-block__sub">—</span>`;
    host.appendChild(parts);
  }

  async function act(name, body, price) {
    if (price != null && price > (D.cash || 0)) { sound('UNAFFORDABLE', 'Ledger_Sounds'); return toast(t('error.no_money', { amount: money(price) }), true); }
    const r = await post(name, body);
    if (!r.ok) { if (r.why) toast(t('error.' + r.why), true); return; }
    if (r.data) { D = Object.assign(D, r.data); $('cash').textContent = money(D.cash); renderRows(); renderAmmo(); renderDetail(); }
    sound('PURCHASE', 'HUD_SHOP_SOUNDSET');
  }

  $('btn-close').addEventListener('click', () => post('close'));
  document.addEventListener('keydown', (e) => { if (D && (e.key === 'Backspace' || e.key === 'Escape') && e.target.type !== 'text') post('close'); });

  function open(m) {
    D = m.data; L = m.locale || D.locale || {};
    document.body.classList.toggle('lang-ka', m.lang === 'ka');
    applyLocale();
    $('shop-label').textContent = (D.shop && D.shop.label) || (m.brand && m.brand.name) || '';
    $('cash').textContent = money(D.cash);
    sel = D.weapons[0] ? D.weapons[0].serial : null;
    app.classList.remove('lxr-hidden');
    renderRows(); renderAmmo(); renderDetail();
  }
  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.theme || (m.brand && m.brand.theme)) document.documentElement.dataset.theme = m.theme || m.brand.theme;
    if (m.action === 'open') open(m);
    if (m.action === 'close') { app.classList.add('lxr-hidden'); D = null; }
  });
  if (window.__LXR_MOCK__) open(window.__LXR_MOCK__);
})();
