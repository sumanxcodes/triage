from dataclasses import dataclass, field
import logging
from typing import List, Optional
from urllib.parse import urlsplit

logger = logging.getLogger(__name__)


@dataclass
class ScrapedPageData:
    url: str
    final_url: str = ""
    title: str = ""
    text_snippet: str = ""
    has_password_input: bool = False
    has_credit_card_input: bool = False
    has_sensitive_inputs: bool = False
    form_actions: List[str] = field(default_factory=list)
    external_domains: List[str] = field(default_factory=list)
    screenshot_bytes: Optional[bytes] = None
    error: Optional[str] = None


def scrape_url_headless(
    url: str,
    timeout_ms: int = 15000,
    capture_screenshot: bool = True,
) -> ScrapedPageData:
    """
    Launches a headless Chromium browser instance via Playwright to safely render
    untrusted zero-day URLs, extract DOM heuristics, and capture a rendered screenshot.
    """
    from playwright.sync_api import sync_playwright

    data = ScrapedPageData(url=url, final_url=url)

    try:
        with sync_playwright() as p:
            # Launch browser with sandboxing flags for security in containerized environments
            browser = p.chromium.launch(
                headless=True,
                args=[
                    "--no-sandbox",
                    "--disable-setuid-sandbox",
                    "--disable-dev-shm-usage",
                    "--disable-gpu",
                ],
            )

            # Emulate Mobile Safari / iPhone 15 user agent to catch mobile-targeted phishing
            context = browser.new_context(
                user_agent=(
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
                ),
                viewport={"width": 390, "height": 844},
                ignore_https_errors=True,
            )

            page = context.new_page()
            page.set_default_timeout(timeout_ms)

            # Navigate to the page
            response = page.goto(url, wait_until="domcontentloaded")
            if response:
                data.final_url = page.url

            # Wait briefly for dynamic JS rendering if needed
            try:
                page.wait_for_load_state("networkidle", timeout=3000)
            except Exception:
                pass

            data.title = page.title() or ""

            # Extract body text
            try:
                raw_text = page.inner_text("body") or ""
                data.text_snippet = " ".join(raw_text.split())[:2000]
            except Exception:
                data.text_snippet = ""

            # Inspect input fields for credential harvesting signals
            try:
                password_inputs = page.locator('input[type="password"]').count()
                data.has_password_input = password_inputs > 0

                cc_inputs = page.locator(
                    'input[name*="card"], input[name*="cc"], input[autocomplete*="cc"], input[name*="cvv"]'
                ).count()
                data.has_credit_card_input = cc_inputs > 0

                data.has_sensitive_inputs = data.has_password_input or data.has_credit_card_input
            except Exception as e:
                logger.warning(f"Failed to inspect inputs: {e}")

            # Inspect forms & external submission targets
            try:
                forms = page.locator("form").all()
                actions = []
                for f in forms:
                    action = f.get_attribute("action")
                    if action:
                        actions.append(action)
                data.form_actions = actions
            except Exception as e:
                logger.warning(f"Failed to inspect forms: {e}")

            # Inspect external script origins
            try:
                base_domain = urlsplit(data.final_url).netloc.lower()
                scripts = page.locator("script[src]").all()
                external_domains = set()
                for s in scripts:
                    src = s.get_attribute("src")
                    if src and src.startswith(("http://", "https://")):
                        domain = urlsplit(src).netloc.lower()
                        if domain and domain != base_domain:
                            external_domains.add(domain)
                data.external_domains = list(external_domains)
            except Exception as e:
                logger.warning(f"Failed to inspect scripts: {e}")

            # Capture viewport screenshot for Gemini multimodal analysis
            if capture_screenshot:
                try:
                    data.screenshot_bytes = page.screenshot(type="jpeg", quality=60)
                except Exception as e:
                    logger.warning(f"Failed to capture screenshot: {e}")

            browser.close()

    except Exception as e:
        logger.error(f"Error scraping {url}: {e}")
        data.error = str(e)

    return data
