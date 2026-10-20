// Triage Safari Extension Content Script - Executed at document_start
(function () {
  const currentUrl = window.location.href;

  // Intercept before DOM finishes rendering
  if (typeof browser !== "undefined" && browser.runtime && browser.runtime.sendNativeMessage) {
    browser.runtime.sendNativeMessage("application.id", { url: currentUrl }, function (response) {
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
                background: rgba(0, 0, 0, 0.4);
                border-radius: 16px;
                padding: 32px;
                max-width: 480px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.5);
              }
              h1 { font-size: 24px; margin-bottom: 12px; }
              p { font-size: 16px; line-height: 1.5; color: #fca5a5; }
              .url-box {
                background: #450a0a;
                padding: 10px;
                border-radius: 8px;
                font-family: monospace;
                font-size: 13px;
                word-break: break-all;
                margin: 16px 0;
              }
              button {
                background: #ef4444;
                color: white;
                border: none;
                border-radius: 8px;
                padding: 12px 24px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                margin-top: 16px;
              }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>⚠️ Malicious Link Blocked</h1>
              <p>Triage detected this webpage as a dangerous smishing or phishing site attempting to steal your credentials.</p>
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
