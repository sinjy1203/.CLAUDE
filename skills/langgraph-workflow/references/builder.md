# builder.py Development Guide

## Components

`build_workflow()` function:
1. Create graph object with InputState, OutputState
2. Define retry policy
3. Add nodes
4. Connect edges
5. Compile graph

## Standard Template

```python
from langgraph.graph import StateGraph
from langgraph.types import RetryPolicy

from .utils import node_retry_on

from .nodes.node_name1 import NodeName1
...


def build_workflow():
    graph = StateGraph(state_schema=InputState, input_schema=InputState, output_schema=OutputState)

    retry_policy = RetryPolicy(
        retry_on=node_retry_on,
        max_attempts=MAX_NODE_RETRY,
        initial_interval=1.0,
        backoff_factor=2.0,
        max_interval=10.0,
    )

    graph.add_node(NodeName1.name, NodeName1(...), retry_policy=retry_policy)
    graph.add_node(NodeName2.name, NodeName2(...), retry_policy=retry_policy)
    ...

    graph.set_entry_point(NodeName1.name)

    graph.add_conditional_edges(
        NodeName1.name,
        edge_node,
        {
            NodeName2.name: NodeName2.name,
            NodeName3.name: NodeName3.name
        },
    )
    graph.add_edge(NodeName2.name, NodeName4.name)
    ...
    graph.add_conditional_edges(
        NodeName4.name,
        edge_node,
        [
            NodeName5,
            ...
        ],
    )  # map reduce pattern
    graph.add_edge(NodeName5.name, "__end__")


    return graph.compile(name=workflow_name)
```

## Patterns

### Linear Chain
```python
graph.add_edge(NodeA.name, NodeB.name)
graph.add_edge(NodeB.name, NodeC.name)
```

### Conditional Branching
```python
graph.add_conditional_edges(
    source_node.name,
    routing_function,
    {
        NodeA.name: NodeA.name,
        NodeB.name: NodeB.name,
    },
)
```

### Map-Reduce (Parallel Fan-out)
```python
graph.add_conditional_edges(
    "__reduce__",
    map_function,
    [NodeA.name, NodeB.name, ...],
)
```

## Temperature Guidelines

| Temperature | Use Case |
|------------|----------|
| 0.0 | Classification, routing, deterministic decisions |
| 0.2-0.4 | Analysis, advice, structured responses |
| 0.5+ | Creative writing, brainstorming |

## Common Mistakes

### Wrong: Missing retry policy
```python
graph.add_node(NodeName.name, NodeName())  # No retry policy
```

### Correct: With retry policy
```python
graph.add_node(NodeName.name, NodeName(...), retry_policy=retry_policy)
```

### Wrong: Hardcoded node name strings
```python
graph.add_edge("node_a", "node_b")
```

### Correct: Using class name attribute
```python
graph.add_edge(NodeA.name, NodeB.name)
```
