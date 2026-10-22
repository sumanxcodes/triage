// Triage Safari Web Extension - Background Service Worker (Manifest V3)
const api = typeof browser !== "undefined" ? browser : chrome;

function sendHeartbeat() {
  try {
    api.runtime.sendNativeMessage("application.id", { action: "heartbeat" }, (response) => {
      if (api.runtime.lastError) {
        // Native port may not be initialized yet
      }
    });
  } catch (e) {
    // Suppress error
  }
}

// Send heartbeat when background service worker starts up
sendHeartbeat();

api.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request && request.action === "heartbeat") {
    sendHeartbeat();
    sendResponse({ status: "ok" });
    return false;
  }

  if (request && request.action === "checkUrl") {
    // Forward request from content script to native Swift handler (SafariWebExtensionHandler)
    api.runtime.sendNativeMessage("application.id", { url: request.url }, (nativeResponse) => {
      if (api.runtime.lastError) {
        console.error("[Triage] Native messaging error:", api.runtime.lastError);
        sendResponse({ action: "allow", error: api.runtime.lastError.message });
      } else {
        sendResponse(nativeResponse);
      }
    });

    // Return true to signal asynchronous response
    return true;
  }
});
