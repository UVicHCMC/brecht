/**
 * Popover nav (Popover API–first) + focus trap
 *
 * What this version does (and what it intentionally does NOT do):
 *
 * ✅ Uses Popover API declaratively
 *    - Opening/closing is handled by your HTML attributes:
 *        popovertarget / popovertargetaction on buttons + popover="auto" on the nav
 *
 * ✅ Minimal JS responsibilities
 *    1) Enforce your rule: at/above the desktop breakpoint, the popover must be closed.
 *    2) Trap focus inside the popover only while it is open; restore focus on close.
 *
 * 🚫 Important change:
 * - We do NOT set aria-expanded anywhere.
 *   Nu checker error: "aria-expanded must not be used on any element which has a popovertarget attribute."
 *   The UA exposes expanded/collapsed semantics for popover invokers; author must not manage aria-expanded.
 *
 * Breakpoint requirement:
 * - CSS defines: :root { --desktop-break: 48rem; }  <-- NOT supported here
 *   This script accepts only pixel values like "768px" or "768".
 *   If --desktop-break is missing or not parseable as pixels, it falls back to 768.
 */

(function initWhenReady() {
  // Ensure the DOM exists before we query by ID.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  function init() {
    // --- Required elements ---------------------------------------------------------------

    const toggleBtn = document.getElementById("site-menu-toggle");
    const popoverEl = document.getElementById("site-navigation");
    if (!toggleBtn || !popoverEl) return;

    // --- Popover API support check -------------------------------------------------------

    // This is a Popover-first script. If the API isn't there, we bail out cleanly.
    const hasPopoverAPI =
      typeof popoverEl.showPopover === "function" &&
      typeof popoverEl.hidePopover === "function" &&
      typeof popoverEl.togglePopover === "function";

    if (!hasPopoverAPI) return;

    // --- Helpers: real state -------------------------------------------------------------

    /**
     * Returns true if the popover is currently open.
     * :popover-open is the canonical way to read actual open state.
     */
    function isOpen() {
      return popoverEl.matches(":popover-open");
    }

    /**
     * Close the popover if it’s open.
     * Used when enforcing the desktop rule.
     */
    function closePopover() {
      if (isOpen()) popoverEl.hidePopover();
    }

    // --- Breakpoint (read once) ----------------------------------------------------------

    /**
     * Reads --desktop-break from :root. Accepts "768px" or "768".
     * Falls back to 768 if missing/invalid.
     *
     * If you want to support rem/em, standardize --desktop-break as pixels,
     * or compute rem->px (adds JS complexity).
     */
    function readDesktopBreakPx() {
      const raw = getComputedStyle(document.documentElement)
        .getPropertyValue("--desktop-break")
        .trim();

      if (!raw) return 768;

      // Only parse a plain pixel number.
      const m = raw.match(/^([0-9]*\.?[0-9]+)\s*(px)?$/i);
      return m ? Number(m[1]) : 768;
    }

    const breakPx = readDesktopBreakPx();
    const mqDesktop = window.matchMedia(`(min-width: ${breakPx}px)`);

    /**
     * Enforce: on desktop widths, the popover must be closed.
     * On mobile widths, do nothing special; the Popover API governs open/close.
     */
    function enforceDesktopClosed() {
      if (mqDesktop.matches) {
        // Closing triggers the popover "toggle" event, which will update the focus trap.
        closePopover();
      }
    }

    // --- Focus trap ----------------------------------------------------------------------

    /**
     * A selector for focusable elements.
     * We’ll query these within the popover whenever it is open.
     */
    const FOCUSABLE_SELECTOR = [
      "a[href]",
      "area[href]",
      "button:not([disabled])",
      "input:not([disabled]):not([type='hidden'])",
      "select:not([disabled])",
      "textarea:not([disabled])",
      "iframe",
      "object",
      "embed",
      "[contenteditable='true']",
      "[tabindex]:not([tabindex='-1'])",
    ].join(",");

    /**
     * Get focusable descendants of the popover, filtered to elements that are visible.
     * This avoids trapping focus onto display:none or visibility:hidden elements.
     */
    function getFocusable() {
      const candidates = Array.from(
        popoverEl.querySelectorAll(FOCUSABLE_SELECTOR),
      );

      return candidates.filter((el) => {
        // hidden attribute explicitly removes element from interaction.
        if (el.hasAttribute("hidden")) return false;

        // Edge case: elements inside closed <details> should not be focusable.
        const details = el.closest("details");
        if (details && !details.open) return false;

        // Basic computed style visibility checks.
        const style = getComputedStyle(el);
        if (style.display === "none" || style.visibility === "hidden")
          return false;

        // Ensure it actually has a rendered box.
        return el.getClientRects().length > 0;
      });
    }

    // Track what had focus when the popover opened so we can restore it on close.
    let restoreFocusTo = null;

    // Track whether the trap is active to avoid double binding.
    let trapActive = false;

    /**
     * Move focus into the popover when it opens.
     * We focus the first focusable control (often your close button or first link).
     */
    function focusFirstInside() {
      const focusables = getFocusable();

      if (focusables.length > 0) {
        focusables[0].focus({ preventScroll: true });
        return;
      }

      // If there are no focusables (rare), make the popover itself focusable.
      // tabindex="-1" allows programmatic focus without inserting into Tab order.
      if (!popoverEl.hasAttribute("tabindex"))
        popoverEl.setAttribute("tabindex", "-1");
      popoverEl.focus({ preventScroll: true });
    }

    /**
     * Trap Tab key navigation within the popover.
     * - Tab on the last element wraps to the first
     * - Shift+Tab on the first wraps to the last
     */
    function onKeydownTrap(e) {
      // Defensive: only trap if still open.
      if (!isOpen()) return;

      // Trap only Tab / Shift+Tab.
      if (e.key !== "Tab") return;

      const focusables = getFocusable();

      // If nothing focusable exists, prevent Tab from escaping.
      if (focusables.length === 0) {
        e.preventDefault();
        return;
      }

      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      const active = document.activeElement;

      // Shift+Tab from first should wrap to last.
      if (e.shiftKey && active === first) {
        e.preventDefault();
        last.focus();
        return;
      }

      // Tab from last should wrap to first.
      if (!e.shiftKey && active === last) {
        e.preventDefault();
        first.focus();
      }
    }

    /**
     * Activate the trap:
     * - remember focus origin (so we can restore on close)
     * - bind keydown handler
     * - move focus into popover
     */
    function activateTrap() {
      if (trapActive) return;
      trapActive = true;

      restoreFocusTo = document.activeElement;

      // Use document-level listener so focus cannot “slip past” the popover boundary.
      document.addEventListener("keydown", onKeydownTrap);

      // Defer focus move until after open has fully committed.
      queueMicrotask(focusFirstInside);
    }

    /**
     * Deactivate the trap:
     * - remove keydown handler
     * - restore focus to opener (usually the toggle button)
     */
    function deactivateTrap() {
      if (!trapActive) return;
      trapActive = false;

      document.removeEventListener("keydown", onKeydownTrap);

      // Restore focus if the saved element still exists; otherwise use the toggle button.
      const target =
        restoreFocusTo && document.contains(restoreFocusTo)
          ? restoreFocusTo
          : toggleBtn;

      // If focus is currently nowhere useful (body) or inside the (now closed) popover,
      // restore it to the opener.
      const active = document.activeElement;
      const shouldRestore =
        !active ||
        active === document.body ||
        (active && popoverEl.contains(active));

      if (shouldRestore) {
        queueMicrotask(() => target.focus({ preventScroll: true }));
      }

      restoreFocusTo = null;
    }

    // --- Core wiring: rely on Popover API events -----------------------------------------

    /**
     * The Popover API fires a "toggle" event when the popover opens/closes, no matter how:
     * - toggle button (popovertargetaction="toggle")
     * - close button (popovertargetaction="hide")
     * - ESC
     * - click-away light dismiss (popover="auto")
     *
     * We use this to:
     * - enforce desktop closed
     * - activate/deactivate the focus trap
     */
    popoverEl.addEventListener("toggle", (e) => {
      // Modern browsers provide e.newState: "open" | "closed".
      // If absent, fall back to :popover-open.
      const open = e && e.newState ? e.newState === "open" : isOpen();

      // Enforce “desktop must be closed” even if something tries to open it on desktop.
      if (open && mqDesktop.matches) {
        closePopover(); // triggers another toggle -> closed
        return;
      }

      // Focus trap toggles with the popover state.
      if (open) activateTrap();
      else deactivateTrap();
    });

    /**
     * When crossing into desktop width, force close.
     */
    if (typeof mqDesktop.addEventListener === "function") {
      mqDesktop.addEventListener("change", enforceDesktopClosed);
    } else {
      // Older Safari
      mqDesktop.addListener(enforceDesktopClosed);
    }

    // --- Initial state sync ---------------------------------------------------------------

    // Enforce desktop closed immediately on load if needed.
    enforceDesktopClosed();

    // If the popover happens to be open at load on mobile (rare), activate the trap.
    if (isOpen() && !mqDesktop.matches) activateTrap();
  }
})();

/* =========================
   Splash arrow bounce
   ========================= */
(function () {
  "use strict";

  function initSplashBounce() {
    const el = document.querySelector(".splash-down-link img");
    if (!el) return;

    function restartBounceCycle() {
      el.classList.remove("bounce-run");
      void el.offsetWidth;
      el.classList.add("bounce-run");

      setTimeout(restartBounceCycle, 1.6 * 5 * 1000 + 7000);
    }

    restartBounceCycle();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initSplashBounce);
  } else {
    initSplashBounce();
  }
})();

/* =========================
   Header opacity on scroll
   ========================= */
(function () {
  "use strict";

  function initHeaderOpacity() {
    const header = document.querySelector("header");
    if (!header) return;

    const threshold = 40;

    function updateHeaderOpacity() {
      header.classList.toggle("header-transparent", window.scrollY > threshold);
    }

    updateHeaderOpacity();
    window.addEventListener("scroll", updateHeaderOpacity, { passive: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initHeaderOpacity);
  } else {
    initHeaderOpacity();
  }
})();

/* =========================
   Fade-up reveal on scroll
   ========================= */
(function () {
  "use strict";

  function isInViewport(el) {
    const rect = el.getBoundingClientRect();
    const vh = window.innerHeight || document.documentElement.clientHeight;
    return rect.top < vh && rect.bottom > 0;
  }

  function initFadeSelected() {
    const main = document.querySelector("main");
    if (!main) return;

    const elements = main.querySelectorAll("h1, h2, h3, h4, h5, h6, img, div");
    if (!elements.length) return;

    if (
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    ) {
      elements.forEach((el) =>
        el.classList.remove("fade-up-init", "fade-up-visible"),
      );
      return;
    }

    const toObserve = [];

    elements.forEach((el) => {
      if (isInViewport(el)) {
        el.classList.remove("fade-up-init", "fade-up-visible");
      } else {
        el.classList.add("fade-up-init");
        toObserve.push(el);
      }
    });

    if (!toObserve.length) return;

    if (!("IntersectionObserver" in window)) {
      toObserve.forEach((el) => el.classList.add("fade-up-visible"));
      return;
    }

    function handleIntersection(entries, observer) {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("fade-up-visible");
        observer.unobserve(entry.target);
      });
    }

    const observer = new IntersectionObserver(handleIntersection, {
      threshold: 0.2,
    });

    toObserve.forEach((el) => observer.observe(el));
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initFadeSelected);
  } else {
    initFadeSelected();
  }
})();

/* =========================
   Scroll-to-top button
   ========================= */
(function () {
  "use strict";

  function initScrollToTop() {
    const scrollBtn = document.querySelector("#scroll-to-top");
    if (!scrollBtn) return;

    const threshold = 300;

    function updateScrollButtonVisibility() {
      scrollBtn.classList.toggle("is-visible", window.scrollY > threshold);
    }

    function handleScrollToTopClick() {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }

    scrollBtn.addEventListener("click", handleScrollToTopClick);
    window.addEventListener("scroll", updateScrollButtonVisibility, {
      passive: true,
    });
    updateScrollButtonVisibility();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initScrollToTop);
  } else {
    initScrollToTop();
  }
})();
