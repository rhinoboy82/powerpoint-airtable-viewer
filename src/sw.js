const CACHE_NAME = "slide-viewer-v1";

// Cache the add-in shell on install
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll([
        "./content.html",
        "https://appsforoffice.microsoft.com/lib/1/hosted/office.js",
      ]);
    })
  );
  self.skipWaiting();
});

// Clean up old caches on activate
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// Network-first for add-in assets, skip caching for iframe content
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // Only cache our own assets and office.js — don't intercept iframe requests
  const isOwnAsset =
    url.origin === self.location.origin ||
    url.href.startsWith("https://appsforoffice.microsoft.com/lib/");

  if (!isOwnAsset) return;

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Update the cache with the fresh response
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        return response;
      })
      .catch(() => {
        // Network failed — serve from cache
        return caches.match(event.request);
      })
  );
});
