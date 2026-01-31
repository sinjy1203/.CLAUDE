# Map-Reduce Pattern Node

## Overview

Map-reduce nodes fan out work to multiple parallel executions of the same node. They use `Send` to dispatch work items.

## Import

```python
from langgraph.types import Send
```

## Components

1. InputState
2. Function (returns `list[Send]`)

## Standard Template

```python
from langgraph.types import Send
from ..state import StateBaseModel, NestedModel, ...
from .node_name import NodeName


class InputState(StateBaseModel):
    required_field: type = Field(...)
    optional_field: type | None = Field(default=None)
    shared_field: Annotated[list[str], extend_state] = Field(default_factory=list)
    nested_field: NestedModel = Field(default_factory=NestedModel)


def map_to_workers(state: InputState) -> list[Send]:
    return [
        Send(
            NodeName.name,
            state
        )
        for value in state.items_to_process
    ]
```

## Send Object

```python
Send(
    node,  # Target node name (str)
    arg,   # State to pass to the node
)
```

## Usage in builder.py

```python
from .nodes.map_to_workers import map_to_workers
from .nodes.worker_node import WorkerNode

graph.add_conditional_edges(
    source_node.name,
    map_to_workers,
    [WorkerNode.name],
)
```

## Example: Processing Multiple Items

```python
def map_documents(state: InputState) -> list[Send]:
    return [
        Send(
            DocumentProcessor.name,
            {**state.model_dump(), "current_document": doc}
        )
        for doc in state.documents
    ]
```

## Example: With Custom State Per Worker

```python
def map_with_context(state: InputState) -> list[Send]:
    sends = []
    for idx, item in enumerate(state.items):
        worker_state = state.model_copy()
        worker_state.current_item = item
        worker_state.worker_index = idx
        sends.append(Send(WorkerNode.name, worker_state))
    return sends
```

## Collecting Results

Use the `extend_state` reducer in your state to collect results from parallel workers:

```python
# In state.py
class InputState(StateBaseModel):
    results: Annotated[list[str], extend_state] = Field(default_factory=list)
```

Each worker appends to `results`, and they're automatically merged.

## Key Points

1. **Function, not class**: Plain function returning `list[Send]`
2. **Return type**: `list[Send]`
3. **Each Send**: Dispatches one parallel execution
4. **State handling**: Can pass the same state or modified copies
5. **Result collection**: Use `Annotated[list, extend_state]` reducer
