import logging
from typing import List, Optional
from urllib.parse import urlsplit
from pydantic import BaseModel, Field

from app.core.config import settings
from app.core.normalizer import extract_registered_domain
from worker.scraper import ScrapedPageData

logger = logging.getLogger(__name__)


class PhishingAnalysisResult(BaseModel):
    is_phishing: bool = Field(description="True if classified as phishing, False if legitimate")
    target_brand: Optional[str] = Field(
        default=None, description="Impersonated brand (e.g. Australia Post, Apple, Bank)"
    )
    threat_category: str = Field(
        default="benign",
        description="'credential_harvesting', 'brand_impersonation', 'fraud', or 'benign'",
    )
    confidence_score: float = Field(default=0.0, description="Confidence score from 0.0 to 1.0")
    reasons: List[str] = Field(default_factory=list, description="Specific indicators justifying the classification")


def evaluate_with_gemini(data: ScrapedPageData) -> PhishingAnalysisResult:
    """
    Evaluates scraped DOM heuristics and visual screenshots using Google Gemini API.
    Uses structured output parsing for guaranteed schema conformance.
    """
    if not settings.GEMINI_API_KEY:
        logger.info("No GEMINI_API_KEY provided; falling back to heuristic evaluation.")
        return evaluate_heuristics(data)

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(api_key=settings.GEMINI_API_KEY)

        prompt_text = f"""
You are an expert cybersecurity threat analyst specializing in phishing and mobile smishing URL detection.
Evaluate the following webpage details for phishing indicators:

Requested URL: {data.url}
Final Rendered URL: {data.final_url}
Page Title: {data.title}
Contains Password Input: {data.has_password_input}
Contains Credit Card Input: {data.has_credit_card_input}
Form Actions: {data.form_actions}
External Script Domains: {data.external_domains}
Body Text Snippet:
\"\"\"
{data.text_snippet}
\"\"\"

Carefully assess whether this webpage is impersonating a legitimate service (banks, courier delivery,
Apple, government) to harvest credentials or financial data.
Provide your verdict strictly adhering to the JSON schema.
"""
        contents: list = [prompt_text]

        # Attach rendered screenshot if available for multimodal visual comparison
        if data.screenshot_bytes:
            contents.append(
                types.Part.from_bytes(
                    data=data.screenshot_bytes,
                    mime_type="image/jpeg",
                )
            )

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=contents,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=PhishingAnalysisResult,
                temperature=0.1,
            ),
        )

        if response.text:
            return PhishingAnalysisResult.model_validate_json(response.text)

    except Exception as e:
        logger.error(f"Gemini API inference failed: {e}. Falling back to heuristics.")

    return evaluate_heuristics(data)


def evaluate_heuristics(data: ScrapedPageData) -> PhishingAnalysisResult:
    """
    Fast rule-based heuristic fallback classifier for environments without Gemini API key.
    Checks high-signal indicators: credential harvesting on untrusted TLDs, domain spoofing, etc.
    """
    reasons: List[str] = []
    suspicious_tlds = {"xyz", "top", "buzz", "click", "rest", "cam", "fit", "work", "cfd"}
    high_target_brands = {
        "apple": ["apple", "icloud"],
        "australia post": ["auspost", "australiapost", "parcel"],
        "commonwealth bank": ["commbank", "netbank", "cba"],
        "netflix": ["netflix"],
        "mygov": ["mygov", "medicare", "ato"],
    }

    url_lower = data.final_url.lower()
    parts = urlsplit(data.final_url)
    host = parts.netloc.split(":")[0].lower() if parts.netloc else parts.path.split("/")[0].lower()
    domain = extract_registered_domain(host)
    tld = domain.split(".")[-1] if "." in domain else ""

    detected_brand: Optional[str] = None
    for brand, keywords in high_target_brands.items():
        if any(kw in url_lower or kw in data.title.lower() for kw in keywords):
            detected_brand = brand
            break

    # Rule 1: Sensitive credential inputs on untrusted/cheap TLDs
    if data.has_password_input and tld in suspicious_tlds:
        reasons.append(f"Password field detected on suspicious top-level domain (.{tld})")

    # Rule 2: Brand keyword present in URL/Title but domain is not official
    if detected_brand:
        official_domains = {
            "apple": "apple.com",
            "australia post": "auspost.com.au",
            "commonwealth bank": "commbank.com.au",
            "netflix": "netflix.com",
            "mygov": "my.gov.au",
        }
        official = official_domains.get(detected_brand, "")
        if official and official not in domain:
            reasons.append(f"Appears to impersonate {detected_brand.title()} on unauthorized domain '{domain}'")

    # Rule 3: Credit card input on non-standard domain
    if data.has_credit_card_input and (tld in suspicious_tlds or detected_brand):
        reasons.append("Credit card input fields found on unauthorized domain")

    # Rule 4: Form action points to different external domain
    for action in data.form_actions:
        if action.startswith("http") and domain not in action.lower():
            reasons.append(f"Form submission posts data to external domain: {action}")
            break

    is_phish = len(reasons) > 0
    confidence = min(0.5 + (0.2 * len(reasons)), 0.98) if is_phish else 0.05
    category = (
        "credential_harvesting" if data.has_sensitive_inputs
        else ("brand_impersonation" if detected_brand else "benign")
    )

    return PhishingAnalysisResult(
        is_phishing=is_phish,
        target_brand=detected_brand.title() if detected_brand else None,
        threat_category=category,
        confidence_score=confidence,
        reasons=reasons,
    )
