// Triage Safari Web Extension - Background Service Worker (Manifest V3)
const api = typeof browser !== "undefined" ? browser : chrome;

api.runtime.onMessage.addListener((request, sender, sendResponse) => {
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
