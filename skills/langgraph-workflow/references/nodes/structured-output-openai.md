# Structured Output LLM Node (OpenAI)

## Overview

Use OpenAI's structured output feature to get responses in a specific format. Requires:
- ResponseFormat: Pydantic model defining the output structure
- `with_structured_output()` or `create_agent()` for structured responses

## Components

1. InputState / OutputState
2. SYSTEM_TEMPLATE
3. USER_TEMPLATE
4. ResponseFormat
5. Node class (with structured output agent)

## Standard Template

```python
from langchain_openai import ChatOpenAI
from ..state import StateBaseModel, NestedModel, ...


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

    def __init__(self, model_name: str, temperature: float, ...):
        model = ChatOpenAI(model=model_name, temperature=temperature)
        self.agent = create_agent(model=model, response_format=ResponseFormat)

    async def __call__(self, state: InputState) -> OutputState:
        context1, context2 = self._get_context(state.field1, state.field2)

        system_prompt = SYSTEM_TEMPLATE
        user_prompt = USER_TEMPLATE.format(context_variable_1=context1, context_variable_2=context2)

        response = await self.agent.ainvoke({
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        })

        structured_response = response["structured_response"]
        return OutputState(field3=structured_response.field3)

    def _get_context(self, field1, field2) -> tuple[str, str]:
        context1 = f"Processing {field1}..."
        context2 = f"Based on {field2}..."
        return context1, context2
```

## ResponseFormat Rules

1. **Inherit from StateBaseModel**
2. **Each field MUST have a `description`** (unlike InputState/OutputState)
3. **Description language**: English, clear, and concise
4. **Description purpose**: Helps LLM understand what to fill in each field

### Example

```python
class ResponseFormat(StateBaseModel):
    rewritten_query: str = Field(..., description="The optimized search query")
    search_keywords: list[str] = Field(..., description="List of extracted keywords for search")
    confidence: float = Field(..., description="Confidence score between 0.0 and 1.0")
```

## Alternative: Using with_structured_output

```python
def __init__(self, model_name: str, temperature: float):
    self.llm = ChatOpenAI(model=model_name, temperature=temperature).with_structured_output(ResponseFormat)

async def __call__(self, state: InputState) -> OutputState:
    ...
    response = await self.llm.ainvoke([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ])
    # response is already a ResponseFormat instance
    return OutputState(field3=response.field)
```
