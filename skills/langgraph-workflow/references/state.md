# state.py Development Guide

## Components

1. **extend_state function**: Reducer for parallel node list field handling
2. **StateBaseModel**: Base model with common configuration
3. **InputState / OutputState**: Workflow-level input and output definitions
4. **Nested Models**: Complex data types used in states

## Standard Template

```python
from pydantic import BaseModel, ConfigDict


def extend_state(existing: list, update: list):
    return existing + update


class StateBaseModel(BaseModel):
    model_config = ConfigDict(extra="ignore", strict=True, arbitrary_types_allowed=True)


class NestedModel(StateBaseModel):
    required_field: type = Field(...)
    optional_field: type | None = Field(default=None)


class InputState(StateBaseModel):
    required_field: type = Field(...)
    optional_field: type | None = Field(default=None)
    shared_field: Annotated[list[str], extend_state] = Field(default_factory=list)
    nested_field: NestedModel = Field(default_factory=NestedModel)


class OutputState(StateBaseModel):
    ...

```

## Development Rules

1. **extend_state location**: Can be defined externally if multiple workflows share it

2. **StateBaseModel**: Base for InputState, OutputState, and node-level states. Can be externalized for multi-workflow projects

3. **InputState / OutputState**: Define workflow-level input and output

4. **Nested models**: All nested models used in workflow-level and node-level states must be defined in state.py and imported where needed

5. **Field definition rules**:
   - All fields must have type annotation and `pydantic.Field`
   - Required field: `Field(...)`
   - Optional field: `Field(default=...)` or `Field(default_factory=...)`
   - **Do NOT use Field's `description` attribute**

## Patterns

### Reducer Pattern (Parallel Nodes)
When multiple parallel nodes write to the same list field:
```python
shared_results: Annotated[list[str], extend_state] = Field(default_factory=list)
```

### Nested Model Pattern
```python
class SearchResult(StateBaseModel):
    title: str = Field(...)
    content: str = Field(...)
    score: float = Field(...)

class InputState(StateBaseModel):
    results: list[SearchResult] = Field(default_factory=list)
```

### Literal/Enum Pattern
```python
from typing import Literal

class InputState(StateBaseModel):
    status: Literal["pending", "processing", "completed"] = Field(default="pending")
```

### Optional Field Pattern
```python
class InputState(StateBaseModel):
    user_input: str = Field(...)
    cached_result: str | None = Field(default=None)
```
