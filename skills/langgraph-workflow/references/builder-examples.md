# Builder Examples

Real-world examples of workflow graph configuration in builder.py.

## Complete builder.py Example

```python
from langgraph.graph import StateGraph
from langgraph.types import Send
from .nodes.query_rewriter import QueryRewriter
from .nodes.query_router import QueryRouter
from .nodes.step_back import StepBack
from .nodes.intro import Intro
from .nodes.statute import Statute
from .nodes.precedent import Precedent
from .nodes.advice import Advice
from .nodes.direct_answer import DirectAnswer
from .nodes.synthesis import Synthesis
from .nodes.next_response import NextResponse
from .nodes.recommend_lawyers import RecommendLawyers
from .state import InputState, OutputState, OverallState, PrivateState, AgentQuery


def map_agent(state: PrivateState) -> list[Send]:
    """Map-reduce pattern: conditionally dispatch to parallel nodes."""
    send_list = []

    # Always run these nodes in parallel
    send_list.extend(
        [
            Send(
                node=Statute.name,
                arg=AgentQuery(
                    agent_query=(
                        state.step_back_query
                        if state.query_type in ("FACTUAL", "INTERPRETATION")
                        else state.rewritten_query
                    )
                ),
            ),
            Send(
                node=Precedent.name,
                arg=AgentQuery(agent_query=state.rewritten_query),
            ),
            Send(
                node=RecommendLawyers.name,
                arg=AgentQuery(agent_query=state.rewritten_query),
            ),
        ]
    )

    # Conditionally add nodes based on query type
    if state.query_type == "CONSULTATION":
        if state.needs_empathy:
            send_list.append(
                Send(
                    node=Intro.name,
                    arg=AgentQuery(agent_query=state.rewritten_query),
                )
            )

        if state.needs_advice:
            send_list.append(
                Send(
                    node=Advice.name,
                    arg=AgentQuery(agent_query=state.rewritten_query),
                )
            )

    return send_list


def build_workflow():
    """Build and compile the LangGraph workflow.

    IMPORTANT: Function must be named 'build_workflow' (not just 'build').
    """
    # 1. Create StateGraph instance
    graph = StateGraph(
        state_schema=OverallState,      # Schema for all state in graph
        input_schema=InputState,        # Schema for workflow inputs
        output_schema=OutputState       # Schema for workflow outputs
    )

    # 2. Add nodes
    # Special reduce node for map-reduce pattern
    graph.add_node("__reduce__", lambda x: x)

    # Regular nodes with model configuration
    graph.add_node(
        QueryRewriter.name,
        QueryRewriter(model_name="gpt-4.1", temperature=0.0)
    )
    graph.add_node(
        StepBack.name,
        StepBack(model_name="gpt-4.1", temperature=0.2)
    )
    graph.add_node(
        QueryRouter.name,
        QueryRouter(model_name="gpt-4.1", temperature=0.0)
    )
    graph.add_node(
        Intro.name,
        Intro(model_name="gpt-4.1", temperature=0.5)
    )
    graph.add_node(
        Statute.name,
        Statute(model_name="gpt-4.1", temperature=0.0)
    )
    graph.add_node(
        Precedent.name,
        Precedent(model_name="gpt-4.1", temperature=0.2)
    )
    graph.add_node(
        Advice.name,
        Advice(model_name="gpt-4.1", temperature=0.4)
    )
    graph.add_node(
        RecommendLawyers.name,
        RecommendLawyers(model_name="gpt-4.1", temperature=0.1)
    )
    graph.add_node(
        DirectAnswer.name,
        DirectAnswer(model_name="gpt-4.1", temperature=0.3)
    )
    graph.add_node(
        Synthesis.name,
        Synthesis()
    )
    graph.add_node(
        NextResponse.name,
        NextResponse(model_name="gpt-4.1", temperature=0.4)
    )

    # 3. Add edges
    # Linear flow at start
    graph.add_edge("__start__", QueryRewriter.name)

    # Parallel processing
    graph.add_edge(QueryRewriter.name, StepBack.name)
    graph.add_edge(QueryRewriter.name, QueryRouter.name)

    # Converge to reduce node
    graph.add_edge(StepBack.name, "__reduce__")
    graph.add_edge(QueryRouter.name, "__reduce__")

    # Conditional fan-out (map-reduce pattern)
    graph.add_conditional_edges(
        "__reduce__",
        map_agent,
        [Intro.name, Statute.name, Precedent.name, Advice.name, RecommendLawyers.name],
    )

    # Converge back to single path
    graph.add_edge(Intro.name, DirectAnswer.name)
    graph.add_edge(Statute.name, DirectAnswer.name)
    graph.add_edge(Precedent.name, DirectAnswer.name)
    graph.add_edge(Advice.name, DirectAnswer.name)
    graph.add_edge(RecommendLawyers.name, DirectAnswer.name)

    # Final linear flow
    graph.add_edge(DirectAnswer.name, Synthesis.name)
    graph.add_edge(Synthesis.name, NextResponse.name)
    graph.add_edge(NextResponse.name, "__end__")

    # 4. Compile and return
    return graph.compile(name="ai_legal_chat")
```

## Pattern Explanations

### 1. StateGraph Configuration

```python
graph = StateGraph(
    state_schema=OverallState,      # All fields available to nodes
    input_schema=InputState,        # Fields required at start
    output_schema=OutputState       # Fields returned at end
)
```

**Schema purposes:**
- `state_schema`: Defines what fields exist in the graph state
- `input_schema`: Validates workflow inputs, extracts only these fields from input
- `output_schema`: Filters output to only include these fields

### 2. Special Nodes

```python
# Reduce node for map-reduce pattern
graph.add_node("__reduce__", lambda x: x)
```

**Special node names:**
- `__start__`: Entry point (automatic)
- `__end__`: Exit point (automatic)
- `__reduce__`: Custom convergence point for parallel branches

The reduce node is a pass-through (`lambda x: x`) that serves as a synchronization point.

### 3. Node Initialization

```python
graph.add_node(
    QueryRewriter.name,                              # Use node's name attribute
    QueryRewriter(model_name="gpt-4.1", temperature=0.0)  # Instantiate with config
)
```

**Best practices:**
- Always use `NodeClass.name` attribute, never hardcode strings
- Configure temperature based on task:
  - 0.0: Deterministic tasks (classification, rewriting)
  - 0.2-0.4: Balanced tasks (analysis, advice)
  - 0.5+: Creative tasks (empathy, open-ended responses)

### 4. Simple Edges

```python
graph.add_edge("__start__", QueryRewriter.name)
graph.add_edge(QueryRewriter.name, StepBack.name)
```

**When to use:**
- Unconditional transitions
- Linear sequences
- All parallel branches converging to same node

### 5. Parallel Edges (Fan-Out)

```python
# From one node to multiple nodes
graph.add_edge(QueryRewriter.name, StepBack.name)
graph.add_edge(QueryRewriter.name, QueryRouter.name)
```

**Pattern:** One node splits into multiple parallel paths
**Use case:** Independent operations that can run concurrently

### 6. Convergence (Fan-In)

```python
# Multiple nodes to one node
graph.add_edge(StepBack.name, "__reduce__")
graph.add_edge(QueryRouter.name, "__reduce__")
```

**Pattern:** Multiple parallel paths merge into one node
**Use case:** Wait for all parallel operations to complete

### 7. Conditional Edges (Map-Reduce)

```python
graph.add_conditional_edges(
    "__reduce__",                    # Source node
    map_agent,                       # Function returning list[Send]
    [Intro.name, Statute.name, ...]  # Possible destination nodes
)
```

**When to use:**
- Dynamic number of parallel operations
- Conditional parallel execution
- Different nodes based on state

### 8. Map Function Pattern

```python
def map_agent(state: PrivateState) -> list[Send]:
    send_list = []

    # Always execute
    send_list.append(
        Send(
            node=Statute.name,
            arg=AgentQuery(agent_query=state.rewritten_query)
        )
    )

    # Conditionally execute
    if state.needs_empathy:
        send_list.append(
            Send(
                node=Intro.name,
                arg=AgentQuery(agent_query=state.rewritten_query)
            )
        )

    return send_list
```

**Key elements:**
- Takes state as input
- Returns list of Send objects
- Each Send specifies target node and arguments
- Can be conditional based on state

### 9. Node Arguments in Send

```python
Send(
    node=Statute.name,
    arg=AgentQuery(
        agent_query=(
            state.step_back_query
            if state.query_type in ("FACTUAL", "INTERPRETATION")
            else state.rewritten_query
        )
    )
)
```

**Pattern:** Pass specific subset of state to node
**Why:** Nodes only receive fields they declare in InputState

## Common Patterns

### Pattern 1: Linear Chain

```python
graph.add_edge("__start__", NodeA.name)
graph.add_edge(NodeA.name, NodeB.name)
graph.add_edge(NodeB.name, NodeC.name)
graph.add_edge(NodeC.name, "__end__")
```

**Use case:** Sequential processing with dependencies

### Pattern 2: Parallel Processing

```python
# Fan-out
graph.add_edge(NodeA.name, NodeB.name)
graph.add_edge(NodeA.name, NodeC.name)
graph.add_edge(NodeA.name, NodeD.name)

# Fan-in
graph.add_edge(NodeB.name, NodeE.name)
graph.add_edge(NodeC.name, NodeE.name)
graph.add_edge(NodeD.name, NodeE.name)
```

**Use case:** Independent operations that can run in parallel, then merge

### Pattern 3: Map-Reduce

```python
graph.add_node("__reduce__", lambda x: x)
graph.add_edge(NodeA.name, "__reduce__")

graph.add_conditional_edges(
    "__reduce__",
    map_function,
    [NodeB.name, NodeC.name, NodeD.name]
)

graph.add_edge(NodeB.name, NodeE.name)
graph.add_edge(NodeC.name, NodeE.name)
graph.add_edge(NodeD.name, NodeE.name)
```

**Use case:** Dynamic parallel execution based on state

## Temperature Guidelines

Choose temperature based on task requirements:

| Temperature | Use Case | Examples |
|-------------|----------|----------|
| 0.0 | Deterministic, exact | Classification, routing, rewriting |
| 0.1-0.2 | Mostly deterministic | Search queries, structured extraction |
| 0.3-0.4 | Balanced creativity | General Q&A, practical advice |
| 0.5+ | Creative, empathetic | Empathetic responses, brainstorming |

## Common Mistakes

### ❌ Don't: Use 'build' as function name

```python
def build():  # WRONG
    return graph.compile()
```

✅ **Do: Use 'build_workflow'**

```python
def build_workflow():  # CORRECT
    return graph.compile()
```

### ❌ Don't: Hardcode node names

```python
graph.add_node("QueryRewriter", QueryRewriter(...))  # WRONG
```

✅ **Do: Use node's name attribute**

```python
graph.add_node(QueryRewriter.name, QueryRewriter(...))  # CORRECT
```

### ❌ Don't: Forget to compile

```python
def build_workflow():
    graph = StateGraph(...)
    # ... add nodes and edges ...
    return graph  # WRONG - returns uncompiled graph
```

✅ **Do: Always compile before returning**

```python
def build_workflow():
    graph = StateGraph(...)
    # ... add nodes and edges ...
    return graph.compile(name="workflow_name")  # CORRECT
```

### ❌ Don't: Mix conditional_edges and regular edges from same source

```python
graph.add_edge(NodeA.name, NodeB.name)
graph.add_conditional_edges(NodeA.name, func, [NodeC.name])  # CONFLICT
```

**Why not:** Same source node can't have both conditional and unconditional edges

✅ **Do: Choose one edge type per source**

```python
# Either this:
graph.add_edge(NodeA.name, NodeB.name)

# Or this:
graph.add_conditional_edges(NodeA.name, func, [NodeB.name, NodeC.name])
```
