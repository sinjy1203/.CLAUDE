# TPM Rate Limiting Guide (OpenAI)

## Purpose

When running parallel LLM calls with OpenAI API, you may hit TPM (Tokens Per Minute) rate limits. This guide provides a token bucket-based rate limiter to prevent 429 errors.

## When to Use

- Running multiple LLM nodes in parallel (map-reduce patterns)
- High-volume workflows that may exceed TPM limits
- Production environments with strict rate limit budgets

## Components

1. **TPM_LIMITS**: Model-specific TPM configuration
2. **TPMRateLimiter**: Token bucket rate limiter class
3. **get_rate_limiter**: Singleton factory for rate limiters
4. **RateLimitedChatOpenAI**: Drop-in replacement for ChatOpenAI

## Template

Place this code in `llm_factory.py`:

```python
from __future__ import annotations

import asyncio
import time
from typing import Any

import tiktoken
from langchain_core.messages import BaseMessage
from langchain_core.outputs import LLMResult
from langchain_openai import ChatOpenAI

TPM_LIMITS = {
    "gpt-4.1": 30_000,
    "gpt-4o-mini": 200_000,
}

_rate_limiters: dict[str, TPMRateLimiter] = {}


class TPMRateLimiter:
    def __init__(self, model: str):
        self.model = model
        self.capacity = TPM_LIMITS.get(model, 800_000)
        self.tokens = float(self.capacity)
        self.refill_rate = self.capacity / 60.0
        self.last_refill = time.time()
        self._lock = asyncio.Lock()
        try:
            self._encoding = tiktoken.encoding_for_model(model)
        except KeyError:
            self._encoding = tiktoken.get_encoding("cl100k_base")

    def _refill(self):
        now = time.time()
        elapsed = now - self.last_refill
        refill_amount = elapsed * self.refill_rate
        self.tokens = min(self.capacity, self.tokens + refill_amount)
        self.last_refill = now

    def count_tokens(self, messages: list[BaseMessage]) -> int:
        total = 0
        for msg in messages:
            content = msg.content if hasattr(msg, "content") else str(msg)
            if isinstance(content, str):
                total += len(self._encoding.encode(content))
        return total

    async def acquire(self, input_tokens: int, max_completion_tokens: int):
        needed = input_tokens + max_completion_tokens

        async with self._lock:
            while True:
                self._refill()

                if self.tokens >= needed:
                    self.tokens -= needed
                    return

                deficit = needed - self.tokens
                wait_time = deficit / self.refill_rate
                await asyncio.sleep(min(wait_time, 1.0))


def get_rate_limiter(model: str) -> TPMRateLimiter:
    if model not in _rate_limiters:
        _rate_limiters[model] = TPMRateLimiter(model)
    return _rate_limiters[model]


class RateLimitedChatOpenAI(ChatOpenAI):
    def __init__(self, **kwargs: Any):
        super().__init__(**kwargs)
        model = kwargs.get("model", "gpt-4.1")
        self._rate_limiter = get_rate_limiter(model)
        self._max_completion_tokens = kwargs.get("max_completion_tokens", 1000)

    async def _agenerate(
        self,
        messages: list[BaseMessage],
        stop: list[str] | None = None,
        run_manager: Any = None,
        **kwargs: Any,
    ) -> LLMResult:
        input_tokens = self._rate_limiter.count_tokens(messages)
        max_tokens = kwargs.get("max_completion_tokens", self._max_completion_tokens)
        await self._rate_limiter.acquire(input_tokens, max_tokens)
        return await super()._agenerate(messages, stop, run_manager, **kwargs)
```

## Configuration

### TPM_LIMITS

Add or modify model limits based on your OpenAI tier:

```python
TPM_LIMITS = {
    "gpt-4.1": 30_000,
    "gpt-4o-mini": 200_000,
    "gpt-4o": 150_000,
}
```

### Default Behavior

- Unknown models default to 800,000 TPM
- Token encoding falls back to `cl100k_base` if model-specific encoding unavailable

## Usage in Node

Replace `ChatOpenAI` with `RateLimitedChatOpenAI`:

```python
from ..llm_factory import RateLimitedChatOpenAI

class NodeName:
    name = "NodeName"

    def __init__(self, llm_model: str):
        self.llm = RateLimitedChatOpenAI(
            model=llm_model,
            temperature=0.2,
            max_completion_tokens=1000,
        )

    async def __call__(self, state: InputState) -> OutputState:
        response = await self.llm.ainvoke([...])
        return OutputState(result=response.content)
```

## Notes

- Only affects async calls (`ainvoke`, `agenerate`)
- Sync calls bypass rate limiting
- Rate limiter is shared per model across all nodes
