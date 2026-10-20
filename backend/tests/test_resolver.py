import httpx
import pytest
from app.core.resolver import resolve_shortlink


@pytest.mark.asyncio
async def test_resolve_shortlink_success():
    def custom_transport(request: httpx.Request) -> httpx.Response:
        if "bit.ly" in str(request.url):
            return httpx.Response(
                status_code=301,
                headers={"Location": "https://cba-netbank-auth.com/login"},
            )
        return httpx.Response(status_code=200)

    transport = httpx.MockTransport(custom_transport)
    async with httpx.AsyncClient(transport=transport) as client:
        result = await resolve_shortlink("http://bit.ly/cba-secure-verify", client=client)

    assert result == "https://cba-netbank-auth.com/login"


@pytest.mark.asyncio
async def test_resolve_shortlink_non_shortener_skipped():
    result = await resolve_shortlink("https://auspost.com.au/real-page")
    assert result is None


@pytest.mark.asyncio
async def test_resolve_shortlink_timeout_handled():
    def timeout_transport(request: httpx.Request):
        raise httpx.TimeoutException("Connection timed out")

    transport = httpx.MockTransport(timeout_transport)
    async with httpx.AsyncClient(transport=transport) as client:
        result = await resolve_shortlink("http://bit.ly/timeout", client=client)

    # Must return None gracefully rather than raising exception
    assert result is None
