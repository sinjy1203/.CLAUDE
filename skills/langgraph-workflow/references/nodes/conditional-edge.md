# Conditional Edge Node

## Overview

Conditional edge nodes determine the next node based on state conditions. They are **functions** (not classes) that return a string indicating the next node.

## Naming Convention

Use **verb-based / action-oriented naming**:
- `route_task`
- `check_data`
- `determine_path`
- `select_handler`

## Components

1. InputState
2. Function (returns `str`)

## Standard Template

```python
from ..state import StateBaseModel, NestedModel, ...
from .node_name_1 import NodeName1
from .node_name_2 import NodeName2


class InputState(StateBaseModel):
    required_field: type = Field(...)
    optional_field: type | None = Field(default=None)
    shared_field: Annotated[list[str], extend_state] = Field(default_factory=list)
    nested_field: NestedModel = Field(default_factory=NestedModel)


def route_task(state: InputState) -> str:
    if state.field1 == "...":
        return NodeName1.name
    else:
        return NodeName2.name
```

## Usage in builder.py

```python
from .nodes.route_task import route_task
from .nodes.node_a import NodeA
from .nodes.node_b import NodeB

graph.add_conditional_edges(
    source_node.name,
    route_task,
    {
        NodeA.name: NodeA.name,
        NodeB.name: NodeB.name,
    },
)
```

## Multiple Conditions Example

```python
def route_by_status(state: InputState) -> str:
    if state.status == "error":
        return ErrorHandler.name
    elif state.status == "retry":
        return RetryNode.name
    elif state.requires_review:
        return ReviewNode.name
    else:
        return ProcessNode.name
```

## Key Points

1. **Function, not class**: No `__init__`, no `__call__`, just a plain function
2. **Return type**: `str` (the name of the next node)
3. **Import target nodes**: To access their `.name` attribute
4. **Deterministic**: Should always return the same output for the same input state
