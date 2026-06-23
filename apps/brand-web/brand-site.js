(function () {
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

  const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
  const revealItems = document.querySelectorAll(".hero, .story-band, .section");

  if (motionQuery.matches || !("IntersectionObserver" in window)) {
    revealItems.forEach((item) => item.classList.add("is-visible"));
    return;
  }

  document.body.classList.add("reveal-ready");
  revealItems.forEach((item) => item.classList.add("reveal-item"));

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          return;
        }
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -12% 0px", threshold: 0.12 },
  );

  revealItems.forEach((item) => observer.observe(item));
})();
