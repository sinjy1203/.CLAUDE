# LLM Node

## Overview

LLM nodes use language models to process text. They require:
- SYSTEM_TEMPLATE: Role and guidelines
- USER_TEMPLATE: Dynamic context

## Import

```python
from langchain_openai import ChatOpenAI
# or
from langchain_aws import ChatBedrockConverse
```

## Components

1. InputState / OutputState
2. SYSTEM_TEMPLATE
3. USER_TEMPLATE
4. Node class

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


class NodeName:
    name = "{NodeName}"

    def __init__(self, model_name: str, temperature: float, ...):
        self.llm = ChatOpenAI(model=model_name, temperature=temperature)

    async def __call__(self, state: InputState) -> OutputState:
        context1, context2 = self._get_context(state.field1, state.field2)

        system_prompt = SYSTEM_TEMPLATE
        user_prompt = USER_TEMPLATE.format(context_variable_1=context1, context_variable_2=context2)

        response = await self.llm.ainvoke([
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ])

        return OutputState(field3=response.content)

    def _get_context(self, field1, field2) -> tuple[str, str]:
        context1 = f"Processing {field1}..."
        context2 = f"Based on {field2}..."
        return context1, context2
```

## Prompt Rules

- All prompts must be written in **English**
- See [prompt-guide.md](../prompt-guide.md) for detailed guidelines

## Context Generation

When USER_TEMPLATE context generation is complex, extract to `_get_context` method:

```python
def _get_context(self, field1, field2) -> tuple[str, str]:
    # Complex logic here
    context1 = ...
    context2 = ...
    return context1, context2
```
