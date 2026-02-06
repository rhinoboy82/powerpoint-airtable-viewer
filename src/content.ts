import "./content.css";

const SETTINGS_KEY = "airtableUrl";
const AIRTABLE_EMBED_PATTERN = /^https:\/\/airtable\.com\/embed\//;

/* ---- DOM References ---- */

function $(id: string): HTMLElement {
  return document.getElementById(id)!;
}

/* ---- Initialization ---- */

Office.onReady((info) => {
  if (info.host === Office.HostType.PowerPoint) {
    initializeAddin();
  }
});

function initializeAddin(): void {
  $("load-btn").addEventListener("click", onLoadClicked);
  $("settings-btn").addEventListener("click", onSettingsClicked);
  $("url-input").addEventListener("keydown", (e: Event) => {
    if ((e as KeyboardEvent).key === "Enter") onLoadClicked();
  });

  // Check for a previously saved URL
  const savedUrl = Office.context.document.settings.get(SETTINGS_KEY);
  if (savedUrl && typeof savedUrl === "string") {
    loadAirtableView(savedUrl);
  }
}

/* ---- URL Validation ---- */

function isValidEmbedUrl(url: string): boolean {
  try {
    new URL(url);
    return AIRTABLE_EMBED_PATTERN.test(url);
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

  if (!isValidEmbedUrl(url)) {
    showError(
      "Enter a valid Airtable embed URL (starts with https://airtable.com/embed/)"
    );
    return;
  }

  // Persist to document settings
  Office.context.document.settings.set(SETTINGS_KEY, url);
  Office.context.document.settings.saveAsync((result) => {
    if (result.status === Office.AsyncResultStatus.Succeeded) {
      loadAirtableView(url);
    } else {
      showError("Failed to save settings. " + (result.error?.message || ""));
    }
  });
}

function onSettingsClicked(): void {
  // Switch back to config view
  $("display-view").classList.add("hidden");
  $("config-view").classList.remove("hidden");

  // Pre-populate with current URL
  const savedUrl = Office.context.document.settings.get(SETTINGS_KEY);
  if (savedUrl) {
    ($("url-input") as HTMLInputElement).value = savedUrl;
  }
}

/* ---- View Switching ---- */

function loadAirtableView(url: string): void {
  const iframe = $("airtable-frame") as HTMLIFrameElement;
  iframe.src = url;

  $("config-view").classList.add("hidden");
  $("display-view").classList.remove("hidden");
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
