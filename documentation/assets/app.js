(() => {
  "use strict";

  const searchInput = document.querySelector("[data-action='nav-search']");
  const navItems = document.querySelectorAll("[data-nav-item]");

  if (searchInput && navItems.length) {
    searchInput.addEventListener("input", () => {
      const q = searchInput.value.trim().toLowerCase();
      let sections = document.querySelectorAll("[data-nav-section]");

      navItems.forEach((li) => {
        const text = li.textContent.toLowerCase();
        li.classList.toggle("hidden", q.length > 0 && !text.includes(q));
      });

      sections.forEach((sec) => {
        const next = [];
        let el = sec.nextElementSibling;
        while (el && !el.hasAttribute("data-nav-section")) {
          if (el.hasAttribute("data-nav-item")) next.push(el);
          el = el.nextElementSibling;
        }
        const allHidden = next.every((n) => n.classList.contains("hidden"));
        sec.classList.toggle("hidden", q.length > 0 && allHidden);
      });
    });
  }

  const toggle = document.querySelector("[data-nav-toggle]");
  const sidebar = document.querySelector(".sidebar");
  const overlay = document.querySelector(".sidebar-overlay");

  function openSidebar() {
    sidebar && sidebar.classList.add("open");
    overlay && overlay.classList.add("open");
  }

  function closeSidebar() {
    sidebar && sidebar.classList.remove("open");
    overlay && overlay.classList.remove("open");
  }

  if (toggle) toggle.addEventListener("click", () => {
    sidebar.classList.contains("open") ? closeSidebar() : openSidebar();
  });

  if (overlay) overlay.addEventListener("click", closeSidebar);

  document.querySelectorAll(".nav a").forEach((a) => {
    a.addEventListener("click", () => {
      if (window.innerWidth <= 900) closeSidebar();
    });
  });
})();
