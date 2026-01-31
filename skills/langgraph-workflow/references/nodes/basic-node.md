# Basic Node (Non-LLM)

## Overview

Basic nodes perform logic without LLM calls. Common use cases:
- Database queries
- External API calls
- Data transformation
- Result aggregation

## Naming Convention

Use **role-based / agent-style naming**:
- `content_writer`
- `data_fetcher`
- `result_aggregator`
- `document_loader`

## Components

1. InputState / OutputState
2. Node class

## Standard Template

```python
from ..state import StateBaseModel, NestedModel, ...


class InputState(StateBaseModel):
    required_field: type = Field(...)
    optional_field: type | None = Field(default=None)
    shared_field: Annotated[list[str], extend_state] = Field(default_factory=list)
    nested_field: NestedModel = Field(default_factory=NestedModel)


class OutputState(StateBaseModel):
    ...


class NodeName:
    name = "{NodeName}"

    def __init__(self, database_client: Client, ...):
        self.database_client = database_client

    async def __call__(self, state: InputState) -> OutputState:
        result = self.database_client.search(state.query)
        return OutputState(field3=result)
```

## Node Class Rules

1. **Class variable `name`**: Must match class name
   ```python
   class DataFetcher:
       name = "DataFetcher"
   ```

2. **`__init__` (optional)**: Initialize service objects if needed
   ```python
   def __init__(self, db_client: DBClient, api_key: str):
       self.db_client = db_client
       self.api_key = api_key
   ```

3. **`__call__`**: Main method with type hints `InputState` → `OutputState`
   ```python
   async def __call__(self, state: InputState) -> OutputState:
       ...
       return OutputState(...)
   ```

4. **Internal methods**: Use `_` prefix, ordered by usage in `__call__`
   ```python
   def _validate_input(self, data):
       ...

   def _process_result(self, raw_result):
       ...
   ```

## Modularization Guidelines

Extract to separate methods when:
- Logic is complex and hard to follow inline
- Same logic is reused multiple times
- Testing specific logic in isolation is beneficial

Keep inline when:
- Logic is simple (1-3 lines)
- Only used once
- Extraction would hurt readability
