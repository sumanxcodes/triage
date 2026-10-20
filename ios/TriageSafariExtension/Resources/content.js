// Triage Safari Extension Content Script - Executed at document_start
(function () {
  const currentUrl = window.location.href;
  const api = typeof browser !== "undefined" ? browser : chrome;

  // Intercept before DOM finishes rendering
  if (api && api.runtime && api.runtime.sendMessage) {
    api.runtime.sendMessage({ action: "checkUrl", url: currentUrl }, function (response) {
      if (response && response.action === "block") {
        // Halt page rendering immediately and replace with warning screen
        window.stop();
        document.documentElement.innerHTML = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Triage - Malicious Link Blocked</title>
            <style>
              body {
                margin: 0;
                padding: 32px 20px;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                background-color: #7f1d1d;
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
              button {
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
              }
            </style>
          </head>
          <body>
            <div class="card">
              <div class="shield-icon">🛡️</div>
              <h1>Malicious Link Blocked</h1>
              <p>Triage detected this link as a dangerous smishing or phishing site attempting to steal your credentials.</p>
              <div class="url-box">${escapeHtml(currentUrl)}</div>
              <button onclick="window.history.back()">Go Back Safely</button>
            </div>
          </body>
          </html>
        `;
      }
    });
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
