/* Обвести и найти — веб-версия.
 * Повторяет логику нативного оверлея (Kit/Features/Overlay):
 * жест → классификация (тап / область) → рамка с морфингом → вырезка → Google Lens.
 * Выделение хранится в нормализованных координатах изображения (0…1).
 */
(() => {
  "use strict";
  const cfg = Object.assign({ shortcutURL: "", language: "ru", uploadMaxSide: 1600 }, window.CIRCLE_CONFIG);
  const $ = (id) => document.getElementById(id);

  const home = $("home"), overlay = $("overlay"), stage = $("stage"), shot = $("shot");
  const sel = $("sel"), ink = $("ink"), searchBtn = $("search"), toastEl = $("toast");
  const ctx = ink.getContext("2d");

  const TAP_THRESHOLD = 10;      // px — короче считается касанием
  const MIN_SIDE = 48;           // px — минимальный размер рамки
  const STROKE_PAD = 10;         // px — запас вокруг обводки

  let image = null;              // HTMLImageElement с исходным снимком
  let fit = { x: 0, y: 0, w: 1, h: 1 };   // где изображение нарисовано на экране
  let selection = null;          // {x,y,w,h} в 0…1
  let points = [];
  let drawing = false;

  // ── Загрузка изображения ──────────────────────────────────────────
  $("file").addEventListener("change", (e) => {
    const file = e.target.files && e.target.files[0];
    if (file) openBlob(file);
    e.target.value = "";
  });

  $("paste").addEventListener("click", pasteFromClipboard);
  $("pastebig").addEventListener("click", async () => {
    if (await pasteFromClipboard()) $("pastegate").hidden = true;
  });

  async function pasteFromClipboard() {
    try {
      const items = await navigator.clipboard.read();
      for (const item of items) {
        const type = item.types.find((t) => t.startsWith("image/"));
        if (type) { openBlob(await item.getType(type)); return true; }
      }
      toast("В буфере нет изображения. Сначала скопируйте скриншот.");
    } catch {
      toast("Не удалось прочитать буфер. Используйте «Выбрать скриншот».");
    }
    return false;
  }

  function openBlob(blob) {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.onload = () => showOverlay(img);
    img.onerror = () => toast("Не удалось открыть изображение.");
    img.src = url;
  }

  // ── Показ / закрытие оверлея ──────────────────────────────────────
  function showOverlay(img) {
    if (image && image.src.startsWith("blob:")) URL.revokeObjectURL(image.src);
    image = img;
    shot.src = img.src;
    home.hidden = true;
    overlay.hidden = false;
    clearSelection(false);
    layout();
    overlay.className = "flash";
    clearTimeout(showOverlay.t);
    showOverlay.t = setTimeout(() => { if (!overlay.classList.contains("busy")) setGlow("calm"); }, 1100);
  }

  function closeOverlay() {
    overlay.hidden = true;
    home.hidden = false;
    clearSelection(false);
  }
  $("close").addEventListener("click", closeOverlay);

  function setGlow(state) {
    overlay.classList.remove("flash", "calm", "busy");
    overlay.classList.add(state);
  }

  // ── Раскладка: изображение «aspect fit», canvas под retina ────────
  function layout() {
    if (!image) return;
    const W = stage.clientWidth, H = stage.clientHeight;
    const s = Math.min(W / image.naturalWidth, H / image.naturalHeight);
    const w = image.naturalWidth * s, h = image.naturalHeight * s;
    fit = { x: (W - w) / 2, y: (H - h) / 2, w, h };
    Object.assign(shot.style, { left: fit.x + "px", top: fit.y + "px", width: w + "px", height: h + "px" });
    const dpr = window.devicePixelRatio || 1;
    ink.width = W * dpr; ink.height = H * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    if (selection) placeSelection(selection, true);
  }
  window.addEventListener("resize", layout);

  // ── Координаты ────────────────────────────────────────────────────
  const toNorm = (r) => ({ x: (r.x - fit.x) / fit.w, y: (r.y - fit.y) / fit.h, w: r.w / fit.w, h: r.h / fit.h });
  const toView = (n) => ({ x: fit.x + n.x * fit.w, y: fit.y + n.y * fit.h, w: n.w * fit.w, h: n.h * fit.h });
  function clampUnit(n) {
    const x = Math.max(0, n.x), y = Math.max(0, n.y);
    return { x, y, w: Math.max(0.01, Math.min(1, n.x + n.w) - x), h: Math.max(0.01, Math.min(1, n.y + n.h) - y) };
  }
  function localPoint(e) {
    const r = stage.getBoundingClientRect();
    return { x: e.clientX - r.left, y: e.clientY - r.top };
  }

  // ── Рисование ─────────────────────────────────────────────────────
  stage.addEventListener("pointerdown", (e) => {
    if (e.target.closest(".h")) return;           // тянут уголок — не рисуем
    drawing = true;
    try { stage.setPointerCapture(e.pointerId); } catch { /* не критично */ }
    points = [localPoint(e)];
    ink.classList.remove("fade");
    overlay.classList.add("drawing");
    clearSelection(true);
  });

  stage.addEventListener("pointermove", (e) => {
    if (!drawing) return;
    // Промежуточные точки дают более гладкий штрих; список бывает пустым — тогда берём само событие.
    const coalesced = e.getCoalescedEvents ? e.getCoalescedEvents() : [];
    for (const ev of coalesced.length ? coalesced : [e]) points.push(localPoint(ev));
    drawStroke();
  });

  const endStroke = () => {
    if (!drawing) return;
    drawing = false;
    overlay.classList.remove("drawing");
    finishStroke();
  };
  stage.addEventListener("pointerup", endStroke);
  stage.addEventListener("pointercancel", endStroke);

  function drawStroke() {
    ctx.clearRect(0, 0, ink.width, ink.height);
    if (points.length < 2) return;
    const path = smoothPath(points);
    const b = bounds(points);
    const grad = ctx.createLinearGradient(b.x, b.y, b.x + Math.max(b.w, 1), b.y + Math.max(b.h, 1));
    ["#4285f4", "#ea4335", "#fbbc05", "#34a853"].forEach((c, i) => grad.addColorStop(i / 3, c));
    ctx.lineCap = "round"; ctx.lineJoin = "round";
    // ореол
    ctx.save();
    ctx.shadowColor = "rgba(90,140,255,.95)"; ctx.shadowBlur = 18;
    ctx.strokeStyle = grad; ctx.lineWidth = 6; ctx.stroke(path);
    ctx.restore();
    // белая сердцевина
    ctx.strokeStyle = "rgba(255,255,255,.9)"; ctx.lineWidth = 1.6; ctx.stroke(path);
  }

  /** Catmull-Rom → кривые Безье (как PathSmoothing.swift). */
  function smoothPath(p) {
    const path = new Path2D();
    path.moveTo(p[0].x, p[0].y);
    for (let i = 0; i < p.length - 1; i++) {
      const p0 = p[Math.max(i - 1, 0)], p1 = p[i], p2 = p[i + 1], p3 = p[Math.min(i + 2, p.length - 1)];
      path.bezierCurveTo(
        p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6,
        p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6,
        p2.x, p2.y);
    }
    return path;
  }

  function bounds(p) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const q of p) { x0 = Math.min(x0, q.x); y0 = Math.min(y0, q.y); x1 = Math.max(x1, q.x); y1 = Math.max(y1, q.y); }
    return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
  }

  function pathLength(p) {
    let l = 0;
    for (let i = 1; i < p.length; i++) l += Math.hypot(p[i].x - p[i - 1].x, p[i].y - p[i - 1].y);
    return l;
  }

  /** Классификация жеста (как LassoGeometry.classify). */
  function finishStroke() {
    const b = bounds(points);
    if (pathLength(points) < TAP_THRESHOLD && Math.max(b.w, b.h) < TAP_THRESHOLD) {
      ctx.clearRect(0, 0, ink.width, ink.height);
      const n = toNorm({ x: points[0].x, y: points[0].y, w: 0, h: 0 });
      commit({ x: n.x - 0.15, y: n.y - 0.08, w: 0.3, h: 0.16 });
      return;
    }
    const grow = (side) => Math.max(0, (MIN_SIDE - side) / 2) + STROKE_PAD;
    const gx = grow(b.w), gy = grow(b.h);
    commit(toNorm({ x: b.x - gx, y: b.y - gy, w: b.w + gx * 2, h: b.h + gy * 2 }));
    ink.classList.add("fade");
  }

  // ── Выделение ─────────────────────────────────────────────────────
  function commit(n) {
    const target = clampUnit(n);
    if (!selection) {
      // Стартуем чуть шире — рамка «сжимается» к объекту.
      placeSelection({ x: target.x - target.w * 0.08, y: target.y - target.h * 0.08,
                       w: target.w * 1.16, h: target.h * 1.16 }, true);
      sel.hidden = false;
      void sel.offsetWidth;   // зафиксировать стартовое состояние перед анимацией
    }
    selection = target;
    placeSelection(target, false);
    overlay.classList.add("has-sel");
    searchBtn.disabled = false;
  }

  function placeSelection(n, instant) {
    const v = toView(n);
    sel.classList.toggle("instant", !!instant);
    Object.assign(sel.style, { left: v.x + "px", top: v.y + "px", width: v.w + "px", height: v.h + "px" });
  }

  function clearSelection(keepInk) {
    selection = null;
    sel.hidden = true;
    overlay.classList.remove("has-sel", "busy");
    searchBtn.disabled = true;
    if (!keepInk) ctx.clearRect(0, 0, ink.width, ink.height);
  }

  // Ресайз за уголки
  sel.querySelectorAll(".h").forEach((h) => {
    let start = null, startRect = null;
    h.addEventListener("pointerdown", (e) => {
      e.stopPropagation();
      try { h.setPointerCapture(e.pointerId); } catch { /* не критично */ }
      start = localPoint(e);
      startRect = toView(selection);
    });
    h.addEventListener("pointermove", (e) => {
      if (!start) return;
      const p = localPoint(e), dx = p.x - start.x, dy = p.y - start.y;
      let { x, y, w, h: hh } = startRect;
      let x1 = x + w, y1 = y + hh;
      const c = h.dataset.corner;
      if (c.includes("l")) x = Math.min(x + dx, x1 - MIN_SIDE); else x1 = Math.max(x1 + dx, x + MIN_SIDE);
      if (c.includes("t")) y = Math.min(y + dy, y1 - MIN_SIDE); else y1 = Math.max(y1 + dy, y + MIN_SIDE);
      selection = clampUnit(toNorm({ x, y, w: x1 - x, h: y1 - y }));
      placeSelection(selection, true);
    });
    const end = () => { start = null; };
    h.addEventListener("pointerup", end);
    h.addEventListener("pointercancel", end);
  });

  // ── Поиск в Google Lens ───────────────────────────────────────────
  searchBtn.addEventListener("click", async () => {
    if (!selection || !image) return;
    setGlow("busy");
    overlay.classList.add("has-sel");
    try {
      const blob = await cropToJPEG(selection);
      submitToLens(blob);
    } catch {
      setGlow("calm");
      toast("Не удалось подготовить изображение.");
    }
  });

  function cropToJPEG(n) {
    const W = image.naturalWidth, H = image.naturalHeight;
    const sx = Math.round(n.x * W), sy = Math.round(n.y * H);
    const sw = Math.max(1, Math.round(n.w * W)), sh = Math.max(1, Math.round(n.h * H));
    const scale = Math.min(1, cfg.uploadMaxSide / Math.max(sw, sh));
    const c = document.createElement("canvas");
    c.width = Math.round(sw * scale); c.height = Math.round(sh * scale);
    c.getContext("2d").drawImage(image, sx, sy, sw, sh, 0, 0, c.width, c.height);
    return new Promise((ok, fail) => c.toBlob((b) => (b ? ok(b) : fail()), "image/jpeg", 0.85));
  }

  /** Тот же запрос, что делает веб-версия Lens: multipart-поле encoded_image. */
  function submitToLens(blob) {
    const form = $("lens"), input = $("lensfile");
    const params = new URLSearchParams({ hl: cfg.language, st: String(Date.now()) });
    form.action = "https://lens.google.com/v3/upload?" + params;
    const dt = new DataTransfer();
    dt.items.add(new File([blob], "image.jpg", { type: "image/jpeg" }));
    input.files = dt.files;
    form.submit();
  }

  // При возврате кнопкой «Назад» страница восстанавливается — убираем «загрузку».
  window.addEventListener("pageshow", (e) => { if (e.persisted && !overlay.hidden) setGlow("calm"); });

  // ── Мелочи ────────────────────────────────────────────────────────
  function toast(text) {
    toastEl.textContent = text;
    toastEl.hidden = false;
    clearTimeout(toast.t);
    toast.t = setTimeout(() => (toastEl.hidden = true), 3200);
  }

  // Готовая команда для касания задней панели
  if (cfg.shortcutURL) {
    $("shortcut-ready").hidden = false;
    $("shortcut-link").href = cfg.shortcutURL;
  }

  // Открыто из команды «Показать веб-страницу» со скриншотом в ссылке: «…/#img=<base64>».
  // Часть после # не уходит на сервер — изображение остаётся на телефоне.
  function openFromHash() {
    const hash = location.hash;
    if (!hash.startsWith("#img=")) return false;
    let b64 = hash.slice(5);
    if (b64.includes("%")) { try { b64 = decodeURIComponent(b64); } catch { /* оставить как есть */ } }
    b64 = b64.replace(/\s+/g, "").replace(/-/g, "+").replace(/_/g, "/");
    const img = new Image();
    img.onload = () => {
      showOverlay(img);
      // Убираем огромную ссылку из истории, чтобы «Назад» после Google вёл к оверлею.
      history.replaceState(null, "", location.pathname + location.search);
    };
    img.onerror = () => toast("Не удалось прочитать скриншот из команды.");
    // Формат по первым байтам: PNG начинается с «iVBOR», JPEG — с «/9j/». Конвертация в команде не обязательна.
    const mime = b64.startsWith("iVBOR") ? "image/png" : b64.startsWith("R0lG") ? "image/gif"
      : b64.startsWith("UklG") ? "image/webp" : b64.startsWith("AAAA") ? "image/heic" : "image/jpeg";
    img.src = "data:" + mime + ";base64," + b64;
    return true;
  }

  // Открыто из команды: «…/?paste» — один тап, чтобы вставить скриншот из буфера.
  if (!openFromHash() && new URLSearchParams(location.search).has("paste")) $("pastegate").hidden = false;

  // Офлайн-кэш для значка на экране «Домой»
  if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
})();
