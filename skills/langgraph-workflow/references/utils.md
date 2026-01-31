# utils.py Development Guide

## Components

1. **node_retry_on**: Retry policy function for transient failures
2. **StructuredOutputParser**: JSON parser for Bedrock LLM responses (only needed for Bedrock workflows)

## node_retry_on Function

### Retry Target Exceptions
- `json.decoder.JSONDecodeError`
- `pydantic.ValidationError`
- `httpx.ConnectError`
- `requests.ConnectionError`
- `TimeoutError`
- `httpx.TimeoutException`
- `requests.Timeout`
- `httpx.RemoteProtocolError`
- `openai.RateLimitError`
- HTTP 5xx status errors

### Template

```python
def node_retry_on(exc: Exception) -> bool:
    import json

    import httpx
    import openai
    import pydantic
    import requests

    if isinstance(
        exc,
        json.decoder.JSONDecodeError
        | pydantic.ValidationError
        | httpx.ConnectError
        | requests.ConnectionError
        | TimeoutError
        | httpx.TimeoutException
        | requests.Timeout
        | httpx.RemoteProtocolError
        | openai.RateLimitError,
    ):
        return True

    if isinstance(exc, httpx.HTTPStatusError):
        return 500 <= exc.response.status_code < 600
    if isinstance(exc, requests.HTTPError):
        return 500 <= exc.response.status_code < 600 if exc.response else True

    return False
```

## StructuredOutputParser (Bedrock Only)

### Purpose
Parse Bedrock LLM text responses into Pydantic models when `with_structured_output()` is not available.

### Processing Logic
1. Remove everything before `</think>` tag (for thinking models)
2. Extract JSON from ` ```json ``` ` code blocks
3. Parse JSON and validate against Pydantic schema

### Template

```python
import json
import re

from langchain_core.output_parsers import StrOutputParser


class StructuredOutputParser(StrOutputParser):
    response_schema: object

    def __init__(self, response_schema: object):
        super().__init__(response_schema=response_schema)

    def parse(self, llm_output: str):
        text = super().parse(llm_output)

        if "</think>" in text:
            think_pattern = r".*</think>"
            text = re.sub(think_pattern, "", text, flags=re.DOTALL)

        if "```json" in text:
            pattern = r"```json(.*?)```"
            match = re.search(pattern, text, re.DOTALL)
            if match:
                text = match.group(1)

        text = text.replace("\\'", "'")
        json_response = json.loads(text)
        structured_output = self.response_schema.model_validate(json_response)
        return structured_output
```

### Usage in Node

```python
from ..utils import StructuredOutputParser

class NodeName:
    def __init__(self, llm_model: str, region_name: str):
        llm = ChatBedrockConverse(model_id=llm_model, region_name=region_name)
        self.chain = llm | StructuredOutputParser(ResponseSchema)
```
