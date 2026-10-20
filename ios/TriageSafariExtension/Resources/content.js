// Triage Safari Extension Content Script - Executed at document_start
(function () {
  const currentUrl = window.location.href;
  const api = typeof browser !== "undefined" ? browser : chrome;

  // 1. ZERO-EXPOSURE SHIELD:
  // Synchronously prevent WebKit from painting malicious phishing DOM, logos, or input fields
  // before the asynchronous threat check completes.
  const guardStyle = document.createElement("style");
  guardStyle.id = "triage-pre-scan-shield";
  guardStyle.textContent = `
    html {
      visibility: hidden !important;
      opacity: 0 !important;
      pointer-events: none !important;
      background-color: #0f172a !important;
    }
  `;
  (document.head || document.documentElement).appendChild(guardStyle);

  function unguard() {
    const el = document.getElementById("triage-pre-scan-shield");
    if (el) el.remove();
  }

  // Fallback safety: If native check ever hangs, unguard after 400ms to preserve browser performance
  const safetyTimer = setTimeout(unguard, 400);

  // 2. Intercept and evaluate with native on-device threat intelligence
  if (api && api.runtime && api.runtime.sendMessage) {
    api.runtime.sendMessage({ action: "checkUrl", url: currentUrl }, function (response) {
      clearTimeout(safetyTimer);

      if (response && response.action === "block") {
        // Abort all pending script executions, image downloads, and network sockets
        window.stop();

        // Render the blocking interstitial
        document.documentElement.innerHTML = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Triage - Malicious Link Blocked</title>
            <style>
              html, body {
                visibility: visible !important;
                opacity: 1 !important;
                pointer-events: auto !important;
                background-color: #7f1d1d !important;
              }
              body {
                margin: 0;
                padding: 32px 20px;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                color: #ffffff;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
                box-sizing: border-box;
                text-align: center;
              }
              .card {
                background: rgba(0, 0, 0, 0.45);
                border-radius: 20px;
                padding: 32px 24px;
                max-width: 440px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.6);
              }
              .shield-icon {
                font-size: 54px;
                margin-bottom: 12px;
              }
              h1 { font-size: 24px; margin-bottom: 10px; font-weight: 700; }
              p { font-size: 15px; line-height: 1.5; color: #fca5a5; margin: 0 0 16px 0; }
              .url-box {
                background: #450a0a;
                padding: 12px;
                border-radius: 10px;
                font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                font-size: 12px;
                word-break: break-all;
                margin: 16px 0;
                border: 1px solid rgba(239, 68, 68, 0.3);
              }
              .btn-primary {
                background: #ef4444;
                color: white;
                border: none;
                border-radius: 12px;
                padding: 14px 28px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                margin-top: 12px;
                width: 100%;
                box-sizing: border-box;
                transition: background 0.2s;
              }
              .btn-primary:active {
                background: #dc2626;
              }
              .btn-secondary {
                background: transparent;
                color: #fca5a5;
                border: 1px solid rgba(254, 202, 202, 0.3);
                border-radius: 12px;
                padding: 12px 28px;
                font-size: 14px;
                font-weight: 500;
                cursor: pointer;
                margin-top: 10px;
                width: 100%;
                box-sizing: border-box;
              }
            </style>
          </head>
          <body>
            <div class="card">
              <div class="shield-icon">🛡️</div>
              <h1>Malicious Link Blocked</h1>
              <p>Triage detected this link as a dangerous smishing or phishing site attempting to steal your credentials.</p>
              <div class="url-box">${escapeHtml(currentUrl)}</div>
              <button id="triage-back-btn" class="btn-primary">Go Back Safely</button>
              <button id="triage-close-btn" class="btn-secondary">Leave this Page</button>
            </div>
          </body>
          </html>
        `;

        // Programmatic click listeners bypass CSP restrictions
        const backBtn = document.getElementById("triage-back-btn");
        if (backBtn) {
          backBtn.addEventListener("click", function () {
            if (window.history.length > 1) {
              window.history.back();
            } else {
              window.location.replace("about:blank");
            }
          });
        }

        const closeBtn = document.getElementById("triage-close-btn");
        if (closeBtn) {
          closeBtn.addEventListener("click", function () {
            window.location.replace("about:blank");
          });
        }
      } else {
        // Safe website: immediately unguard to reveal page
        unguard();
      }
    });
  } else {
    unguard();
  }

  function escapeHtml(string) {
    return String(string).replace(/[&<>"']/g, function (s) {
      return {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;"
      }[s];
    });
  }
})();
