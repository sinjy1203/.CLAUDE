# Structured Output LLM Node (Bedrock)

## Overview

Bedrock models don't have native structured output support. Use StructuredOutputParser to parse JSON from LLM responses.

## Key Differences from OpenAI

| Aspect | OpenAI | Bedrock |
|--------|--------|---------|
| Structured output | `with_structured_output()` | StructuredOutputParser |
| SYSTEM_TEMPLATE | Standard | Must include Answer Format section |
| Chain structure | LLM only | `llm \| StructuredOutputParser` |

## Components

1. InputState / OutputState
2. SYSTEM_TEMPLATE (with Answer Format section)
3. USER_TEMPLATE
4. ResponseFormat
5. Node class (with chain = llm | StructuredOutputParser)

## Standard Template

```python
import json
from langchain_aws import ChatBedrockConverse
from ..state import StateBaseModel, NestedModel, ...
from ..utils import StructuredOutputParser


class InputState(StateBaseModel):
    required_field: type = Field(...)
    optional_field: type | None = Field(default=None)
    shared_field: Annotated[list[str], extend_state] = Field(default_factory=list)
    nested_field: NestedModel = Field(default_factory=NestedModel)


class OutputState(StateBaseModel):
    ...


SYSTEM_TEMPLATE = """[1-2 sentences: brief role and task definition]

## Answer Guidelines
1. [Main step description]
  1-1) [Context to reference from state fields]
  1-2) [How to behave: conditions, edge cases]
  1-3) [Inline example if helpful]
2. [Next step description]
  2-1) [Context to reference]
  2-2) [How to behave]
...

## Answer Format
The output should be formatted as a JSON instance that conforms to the JSON schema below.
As an example, for the schema {{"properties": {{"foo": {{"title": "Foo", "description": "a list of strings", "type": "array", "items": {{"type": "string"}}}}}}, "required": ["foo"]}}
the object {{"foo": ["bar", "baz"]}} is a well-formatted instance of the schema. The object {{"properties": {{"foo": ["bar", "baz"]}}}} is not well-formatted.
Here is the output schema:
```json
{response_schema}
"""

USER_TEMPLATE = """# [Section Title 1]
{context_variable_1}

# [Section Title 2]
{context_variable_2}
"""


class ResponseFormat(StateBaseModel):
    field: type = Field(..., description="...")


class NodeName:
    name = "{NodeName}"

    def __init__(self, llm_model: str, region_name: str):
        llm = ChatBedrockConverse(
            model_id=llm_model,
            region_name=region_name,
        )
        self.chain = llm | StructuredOutputParser(ResponseFormat)

    async def __call__(self, state: InputState) -> OutputState:
        context1, context2 = self._get_context(state.field1, state.field2)

        system_prompt = SYSTEM_TEMPLATE.format(
            response_schema=json.dumps(ResponseFormat.model_json_schema(), indent=2, ensure_ascii=False)
        )
        user_prompt = USER_TEMPLATE.format(context_variable_1=context1, context_variable_2=context2)

        structured_response = await self.chain.ainvoke([
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ])

        return OutputState(field3=structured_response.field3)

    def _get_context(self, field1, field2) -> tuple[str, str]:
        context1 = f"Processing {field1}..."
        context2 = f"Based on {field2}..."
        return context1, context2
```

## Answer Format Section

The Answer Format section in SYSTEM_TEMPLATE is **mandatory** for Bedrock structured output.

### Template
```
## Answer Format
The output should be formatted as a JSON instance that conforms to the JSON schema below.
As an example, for the schema {{"properties": {{"foo": {{"title": "Foo", "description": "a list of strings", "type": "array", "items": {{"type": "string"}}}}}}, "required": ["foo"]}}
the object {{"foo": ["bar", "baz"]}} is a well-formatted instance of the schema. The object {{"properties": {{"foo": ["bar", "baz"]}}}} is not well-formatted.
Here is the output schema:
```json
{response_schema}
```

### Schema Injection
```python
system_prompt = SYSTEM_TEMPLATE.format(
    response_schema=json.dumps(ResponseFormat.model_json_schema(), indent=2, ensure_ascii=False)
)
```

## ResponseFormat Rules

Same as OpenAI structured output:
- Inherit from StateBaseModel
- Each field MUST have a `description`
- Descriptions in English, clear and concise
