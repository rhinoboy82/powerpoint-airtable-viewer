import "./content.css";

const SETTINGS_URL_KEY = "embedUrl";
const SETTINGS_VIEWPORT_KEY = "viewportWidth";

/* ---- DOM References ---- */

function $(id: string): HTMLElement {
  return document.getElementById(id)!;
}

/* ---- State ---- */

let currentViewportWidth = 0; // 0 = auto (no scaling)
let isPresentationMode = false;

/* ---- Initialization ---- */

Office.onReady(() => {
  initializeAddin();
});

function initializeAddin(): void {
  $("load-btn").addEventListener("click", onLoadClicked);
  $("settings-btn").addEventListener("click", onSettingsClicked);
  $("url-input").addEventListener("keydown", (e: Event) => {
    if ((e as KeyboardEvent).key === "Enter") onLoadClicked();
  });

  // Viewport slider
  const slider = $("viewport-slider") as HTMLInputElement;
  slider.addEventListener("input", () => {
    currentViewportWidth = parseInt(slider.value, 10);
    updateViewportLabel();
  });

  // Preset buttons
  document.querySelectorAll(".preset-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const width = parseInt((btn as HTMLElement).dataset.width || "0", 10);
      currentViewportWidth = width;
      slider.value = String(width);
      updateViewportLabel();
    });
  });

  // Recalculate scale when the add-in is resized
  window.addEventListener("resize", () => {
    applyScale();
    checkPresentationMode();
  });

  // Detect presentation mode changes
  checkPresentationMode();
  try {
    Office.context.document.addHandlerAsync(
      Office.EventType.ActiveViewChanged,
      () => { checkPresentationMode(); }
    );
  } catch (e) {
    // Event not supported — fall back to polling
    setInterval(checkPresentationMode, 2000);
  }

  // Check for previously saved settings
  try {
    const savedUrl = Office.context.document.settings.get(SETTINGS_URL_KEY);
    const savedViewport = Office.context.document.settings.get(SETTINGS_VIEWPORT_KEY);

    if (savedViewport !== null && savedViewport !== undefined) {
      currentViewportWidth = parseInt(savedViewport, 10) || 0;
      slider.value = String(currentViewportWidth);
      updateViewportLabel();
    }

    if (savedUrl && typeof savedUrl === "string") {
      loadEmbedView(savedUrl);
    }
  } catch (e) {
    console.log("Settings API not available:", e);
  }
}

/* ---- Viewport Label ---- */

function updateViewportLabel(): void {
  const label = $("viewport-label");
  if (currentViewportWidth === 0) {
    label.textContent = "Auto (fit to box)";
  } else {
    label.textContent = currentViewportWidth + "px wide";
  }
}

/* ---- Presentation Mode Detection ---- */

function checkPresentationMode(): void {
  try {
    // Primary: getActiveViewAsync returns the actual current view
    Office.context.document.getActiveViewAsync((result) => {
      if (result.status === Office.AsyncResultStatus.Succeeded) {
        isPresentationMode = result.value === "read";
      } else {
        // Fallback: check document mode
        isPresentationMode =
          Office.context.document.mode === Office.DocumentMode.ReadOnly;
      }
      updateEditButtonVisibility();
    });
  } catch (e) {
    isPresentationMode = false;
    updateEditButtonVisibility();
  }
}

function updateEditButtonVisibility(): void {
  const btn = $("settings-btn");
  if (isPresentationMode) {
    btn.classList.add("presentation-hidden");
  } else {
    btn.classList.remove("presentation-hidden");
  }
}

/* ---- Scaling Logic ---- */

function applyScale(): void {
  const wrapper = $("iframe-wrapper");
  const iframe = $("embed-frame") as HTMLIFrameElement;
  const container = $("display-view");

  const containerWidth = container.clientWidth;
  const containerHeight = container.clientHeight;

  if (currentViewportWidth === 0 || currentViewportWidth <= containerWidth) {
    // Auto mode — iframe fills the container normally
    iframe.style.width = "100%";
    iframe.style.height = "100%";
    iframe.style.transform = "";
    iframe.style.transformOrigin = "";
    wrapper.style.width = "100%";
    wrapper.style.height = "100%";
    wrapper.style.overflow = "";
    return;
  }

  // Scale mode: iframe is wider than container, scale it down
  const scale = containerWidth / currentViewportWidth;
  const scaledHeight = containerHeight / scale;

  iframe.style.width = currentViewportWidth + "px";
  iframe.style.height = scaledHeight + "px";
  iframe.style.transform = "scale(" + scale + ")";
  iframe.style.transformOrigin = "0 0";
  wrapper.style.width = containerWidth + "px";
  wrapper.style.height = containerHeight + "px";
  wrapper.style.overflow = "hidden";
}

/* ---- URL Validation ---- */

function isValidHttpsUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === "https:";
  } catch {
    return false;
  }
}

/* ---- Event Handlers ---- */

function onLoadClicked(): void {
  const input = $("url-input") as HTMLInputElement;
  const url = input.value.trim();

  hideError();

  if (!url) {
    showError("Please enter a URL.");
    return;
  }

  if (!isValidHttpsUrl(url)) {
    showError("Please enter a valid HTTPS URL.");
    return;
  }

  // Persist to document settings
  try {
    Office.context.document.settings.set(SETTINGS_URL_KEY, url);
    Office.context.document.settings.set(SETTINGS_VIEWPORT_KEY, currentViewportWidth);
    Office.context.document.settings.saveAsync((result) => {
      if (result.status === Office.AsyncResultStatus.Succeeded) {
        loadEmbedView(url);
      } else {
        showError("Failed to save: " + (result.error?.message || ""));
      }
    });
  } catch (e) {
    console.log("Settings API not available, loading without persistence:", e);
    loadEmbedView(url);
  }
}

function onSettingsClicked(): void {
  const iframe = $("embed-frame") as HTMLIFrameElement;
  iframe.src = "about:blank";

  $("display-view").classList.add("hidden");
  $("config-view").classList.remove("hidden");

  // Pre-populate with current settings
  try {
    const savedUrl = Office.context.document.settings.get(SETTINGS_URL_KEY);
    if (savedUrl) {
      ($("url-input") as HTMLInputElement).value = savedUrl;
    }
    const savedViewport = Office.context.document.settings.get(SETTINGS_VIEWPORT_KEY);
    if (savedViewport !== null && savedViewport !== undefined) {
      currentViewportWidth = parseInt(savedViewport, 10) || 0;
      ($("viewport-slider") as HTMLInputElement).value = String(currentViewportWidth);
      updateViewportLabel();
    }
  } catch (e) {
    // Settings not available
  }

  ($("url-input") as HTMLInputElement).select();
}

/* ---- View Switching ---- */

function loadEmbedView(url: string): void {
  const iframe = $("embed-frame") as HTMLIFrameElement;
  iframe.src = url;

  $("config-view").classList.add("hidden");
  $("display-view").classList.remove("hidden");

  // Apply scaling after a brief delay to let the container render
  requestAnimationFrame(() => {
    applyScale();
  });
}

/* ---- Error Display ---- */

function showError(message: string): void {
  const el = $("error-msg");
  el.textContent = message;
  el.classList.remove("hidden");
}

function hideError(): void {
  $("error-msg").classList.add("hidden");
}
