(function () {
  const config = window.ONMU_BRAND_CONFIG || {};
  const downloads = config.downloads || {};
  const header = document.querySelector(".site-header--interactive");
  const navToggle = header?.querySelector(".nav-toggle");
  const nav = header?.querySelector(".site-nav");

  if (header && navToggle && nav) {
    const setOpen = (open) => {
      header.classList.toggle("nav-open", open);
      navToggle.setAttribute("aria-expanded", String(open));
    };

    navToggle.addEventListener("click", () => {
      setOpen(!header.classList.contains("nav-open"));
    });

    nav.addEventListener("click", (event) => {
      if (event.target instanceof HTMLAnchorElement) {
        setOpen(false);
      }
    });
  }

  const storeLabels = {
    ios: "App Store로 이동",
    android: "Google Play로 이동",
  };

  const safeStoreUrl = (value) => {
    if (!value) {
      return "";
    }

    try {
      const url = new URL(value);
      return url.protocol === "https:" ? url.href : "";
    } catch (_error) {
      return "";
    }
  };

  const storeUrlFor = (platform) => {
    if (platform === "ios") {
      return safeStoreUrl(downloads.iosUrl);
    }
    if (platform === "android") {
      return safeStoreUrl(downloads.androidUrl);
    }
    return "";
  };

  document.querySelectorAll("[data-download-platform]").forEach((target) => {
    const platform = target.getAttribute("data-download-platform");
    const storeUrl = storeUrlFor(platform);

    if (!storeUrl) {
      return;
    }

    if (target instanceof HTMLAnchorElement) {
      target.href = storeUrl;
      target.rel = "noopener noreferrer";
      target.target = "_blank";
      if (storeLabels[platform]) {
        target.querySelector("[data-store-label]")?.replaceChildren(storeLabels[platform]);
      }
    }
  });

  document.querySelectorAll("[data-store-status]").forEach((target) => {
    const platform = target.getAttribute("data-store-status");
    if (storeUrlFor(platform)) {
      target.textContent = platform === "ios" ? "iOS 링크 연결됨" : "Android 링크 연결됨";
    }
  });

  const pagePlatform = document.body.getAttribute("data-download-page");
  if (new URLSearchParams(window.location.search).get("redirect") === "store") {
    const storeUrl = storeUrlFor(pagePlatform);
    if (storeUrl) {
      window.location.replace(storeUrl);
      return;
    }
  }

  const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
  const revealItems = document.querySelectorAll(
    ".hero, .story-band, .section, .download-hero, .download-detail, .download-section, .legal-hero, .legal-section",
  );

  if (motionQuery.matches || !("IntersectionObserver" in window)) {
    revealItems.forEach((item) => item.classList.add("is-visible"));
    return;
  }

  document.body.classList.add("reveal-ready");
  revealItems.forEach((item) => item.classList.add("reveal-item"));
  revealItems.forEach((item) => {
    item
      .querySelectorAll(
        ".about-card, .flow-steps li, .feature-card, .screen-notes article, .mini-screen-card, .trust-grid article, .faq-list article, .roadmap-list li, .download-card",
      )
      .forEach((child, index) => {
        child.classList.add("reveal-child");
        child.style.setProperty("--reveal-index", String(Math.min(index, 5)));
      });
  });

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting && entry.intersectionRatio <= 0) {
          return;
        }
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -8% 0px", threshold: 0.01 },
  );

  revealItems.forEach((item) => {
    const rect = item.getBoundingClientRect();
    if (rect.top < window.innerHeight && rect.bottom > 0) {
      item.classList.add("is-visible");
      return;
    }
    observer.observe(item);
  });

  window.setTimeout(() => {
    revealItems.forEach((item) => item.classList.add("is-visible"));
  }, 1400);
})();
