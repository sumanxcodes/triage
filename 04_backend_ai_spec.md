# Backend Threat Intelligence & AI Pipeline

## FastAPI Gateway (`app/main.py`)
*   **Strict Privacy Rule:** The endpoint handling the Apple `ILNetworkResponse` must be strictly stateless. Do not use `logger.info(request.body)`.
*   **Performance:** Use `asyncio` and `aioredis` for the cache lookups.

```python
# Example FastAPI Endpoint Structure for Apple IdentityLookup
@app.post("/api/v1/sms/filter")
async def filter_sms(payload: AppleMessageFilterRequest, redis: Redis = Depends(get_redis)):
    # 1. Extract URLs from payload.messageBody using Regex
    urls = extract_urls(payload.messageBody)
    
    # 2. Hash URLs
    hashed_urls = [hash_sha256(url) for url in urls]
    
    # 3. Check Redis Pipeline (O(1) lookup)
    for hash in hashed_urls:
        if await redis.exists(f"threat:{hash}"):
            return {"action": "filter"} # Return immediately
            
    # 4. Trigger async background analysis if URLs look suspicious but aren't in DB
    # Note: We do not wait for this to finish to maintain < 1s Apple requirement
    if urls:
        celery_app.send_task('analyze_urls_zero_day', args=[urls])
        
    return {"action": "none"}