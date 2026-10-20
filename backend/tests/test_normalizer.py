from app.core.normalizer import (
    canonicalize_url,
    decode_punycode_host,
    extract_raw_urls,
    extract_registered_domain,
    generate_threat_lookup_keys,
    is_shortener,
    normalize_ip_host,
)


def test_extract_raw_urls():
    text = "Check package at https://auspost-track-verify.xyz/update and http://bit.ly/cba-secure-verify now!"
    urls = extract_raw_urls(text)
    assert len(urls) == 2
    assert "https://auspost-track-verify.xyz/update" in urls
    assert "http://bit.ly/cba-secure-verify" in urls


def test_punycode_decoding():
    assert decode_punycode_host("xn--pple-43d.com") == "аpple.com"
    assert decode_punycode_host("google.com") == "google.com"


def test_ip_normalization():
    # Hex IP for 127.0.0.1
    assert normalize_ip_host("0x7f000001") == "127.0.0.1"
    # Dword IP for 127.0.0.1
    assert normalize_ip_host("2130706433") == "127.0.0.1"


def test_canonicalize_url_tracking_params():
    url_with_tracking = "https://example.com/login?utm_source=sms&utm_medium=smish&fbclid=123&account=user1#section"
    canonical = canonicalize_url(url_with_tracking)
    assert canonical == "https://example.com/login?account=user1"


def test_canonicalize_url_ports_and_scheme():
    assert canonicalize_url("EXAMPLE.COM:443/login/") == "http://example.com:443/login"
    assert canonicalize_url("https://example.com:443/login/") == "https://example.com/login"
    assert canonicalize_url("http://example.com:80/login") == "http://example.com/login"


def test_extract_registered_domain():
    assert extract_registered_domain("subdomain.auspost-track-verify.xyz") == "auspost-track-verify.xyz"
    assert extract_registered_domain("portal.phish.co.uk") == "phish.co.uk"
    assert extract_registered_domain("scam.net.au") == "scam.net.au"
    assert extract_registered_domain("example.com") == "example.com"


def test_is_shortener():
    assert is_shortener("http://bit.ly/xyz123") is True
    assert is_shortener("https://tinyurl.com/abc456") is True
    assert is_shortener("https://auspost.com.au/track") is False


def test_generate_threat_lookup_keys():
    url = "https://sub.scam-site.xyz/path"
    keys = generate_threat_lookup_keys(url)
    prefixes = [k[0] for k in keys]
    assert "url" in prefixes
    assert "domain" in prefixes
    assert "host" in prefixes
