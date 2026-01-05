---
name: langgraph-workflow
description: Develop standardized LangGraph-based workflows following specific code patterns and directory structures. Use this skill when creating or modifying LangGraph workflows, including (1) Creating new workflow nodes, (2) Adding or updating state models, (3) Building or modifying workflow graphs, (4) Writing LLM prompts for nodes, or (5) Implementing map-reduce patterns in workflows.
---

# LangGraph Workflow Development

## Overview

This skill enforces standardized patterns for developing LangGraph-based workflows, ensuring consistent code structure, proper state management, and effective prompt engineering.

## Directory Structure

All LangGraph workflows must follow this structure:

```
{workflow-name}/
├── nodes/              # Node implementations (one file per node)
│   ├── __init__.py
│   ├── {node_name}.py
│   └── ...
├── builder.py          # Workflow graph configuration
└── state.py            # All Pydantic models for the workflow
```

## Creating a New Node

### Standard Node Template

Every node file must follow this exact structure:

```python
# 1. Import required classes from state.py
from ..state import StateBaseModel, FieldName1, FieldName2

# 2. Define InputState (inheriting from state.py fields)
class InputState(FieldName1, FieldName2):
    pass

# 3. Define OutputState (inheriting from state.py fields)
class OutputState(FieldName3):
    pass

# 4. LLM Templates (only if node uses LLM)
SYSTEM_TEMPLATE = """[Role and task description in English]

**Guidelines:**
- [Guideline 1]
- [Guideline 2]
- [Guideline 3]
"""

USER_TEMPLATE = """# [Section Title 1]
{context_variable_1}

# [Section Title 2]
{context_variable_2}
"""

# 5. ResponseSchema (only if structured LLM response needed)
class ResponseSchema(FieldName3):
    pass

# 6. Node Class
class NodeName:
    name = "{NodeName}"

    def __init__(self, model_name: str, temperature: float, ...):
        # Initialize LLM, agents, database clients, etc.
        model = ChatOpenAI(model=model_name, temperature=temperature)
        self.agent = create_agent(model=model, response_format=ResponseSchema)

    async def __call__(self, state: InputState) -> OutputState:
        # Get dynamic context
        context1, context2 = self._get_context(state.field1, state.field2)

        # Format prompts
        system_prompt = SYSTEM_TEMPLATE.format(context1=context1)
        user_prompt = USER_TEMPLATE.format(context2=context2)

        # Invoke agent
        response = await self.agent.ainvoke({
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        })

        # Extract structured response
        structured_response = response["structured_response"]
        return OutputState(field3=structured_response.field3)

    def _get_context(self, field1, field2) -> tuple[str, str]:
        # Prepare dynamic context for prompts
        context1 = f"Processing {field1}..."
        context2 = f"Based on {field2}..."
        return context1, context2
```

### Node Implementation Rules

1. **InputState and OutputState**: Always inherit from state.py fields, never define new fields here
2. **Templates**: Must be written in English only
3. **SYSTEM_TEMPLATE**: Include role, task, and bullet-pointed guidelines
4. **USER_TEMPLATE**: Use section titles (with #) and format variables in {braces}
5. **ResponseSchema**: Only include if LLM needs to return structured data
6. **__call__ method**: Must be async and follow the exact pattern above
7. **_get_context method**: Private helper for preparing dynamic prompt content

### Detailed Node Examples

For complete working examples, see [references/node-examples.md](references/node-examples.md).

## Managing State

### State File Structure

All Pydantic models must be defined in `state.py`:

```python
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Literal, Annotated

# Reducer function for list fields
def extend_state(existing: list, update: list):
    return existing + update

# Base model with strict configuration
class StateBaseModel(BaseModel):
    model_config = ConfigDict(
        extra="ignore",
        strict=True,
        arbitrary_types_allowed=True
    )

# Individual field models (descriptions must be in English)
class FieldName1(StateBaseModel):
    field_name_1: str = Field(..., description="Field description in English")

class FieldName2(StateBaseModel):
    field_name_2: bool = Field(..., description="Field description in English")

# Composite states
class InputState(FieldName1, FieldName2):
    pass

class OutputState(FieldName3):
    pass

class OverallState(InputState):
    pass
```

### State Management Rules

1. **Base Model**: Always create `StateBaseModel` with strict config
2. **Field Models**: Create small, single-field models that can be composed
3. **Descriptions**: Always write in English, even if UI text is in another language
4. **Type Annotations**: Use `Literal` for enums, `Annotated` for reducers
5. **List Fields**: Use `extend_state` reducer with `Annotated[List[T], extend_state]`

### State Examples

For real-world state implementations, see [references/state-examples.md](references/state-examples.md).

## Building Workflows

### Builder File Structure

The `builder.py` file must use the function name `build_workflow` (not just `build`):

```python
from langgraph.graph import StateGraph
from langgraph.types import Send
from .nodes.node1 import Node1
from .nodes.node2 import Node2
from .state import InputState, OutputState, OverallState

def build_workflow():
    # Create graph
    graph = StateGraph(
        state_schema=OverallState,
        input_schema=InputState,
        output_schema=OutputState
    )

    # Add nodes
    graph.add_node(Node1.name, Node1(model_name="gpt-4.1", temperature=0.0))
    graph.add_node(Node2.name, Node2(model_name="gpt-4.1", temperature=0.2))

    # Add edges
    graph.add_edge("__start__", Node1.name)
    graph.add_edge(Node1.name, Node2.name)
    graph.add_edge(Node2.name, "__end__")

    # Compile and return
    return graph.compile(name="workflow_name")
```

### Map-Reduce Pattern

When implementing map-reduce patterns, create a `map_agent` function:

```python
def map_agent(state: PrivateState) -> list[Send]:
    send_list = []

    # Conditionally add parallel nodes
    send_list.append(
        Send(
            node=Node1.name,
            arg=AgentQuery(agent_query=state.query)
        )
    )

    if state.needs_feature:
        send_list.append(
            Send(
                node=Node2.name,
                arg=AgentQuery(agent_query=state.query)
            )
        )

    return send_list

# Use in graph
graph.add_conditional_edges(
    "__reduce__",
    map_agent,
    [Node1.name, Node2.name]
)
```

### Builder Examples

For complete builder implementations, see [references/builder-examples.md](references/builder-examples.md).

## Prompt Writing Guidelines

### System Prompt Structure

```
[Brief role statement]

**Role:**
[1-2 sentences about the agent's role]

**Task:**
[1-2 sentences about what to accomplish]

**Guidelines:**
- [Specific guideline with clear criteria]
- [Another specific guideline]
- [Formatting or output requirements]

**Examples:** (optional)
[Show 1-2 concrete examples if pattern is not obvious]
```

### User Prompt Structure

```
# [Descriptive Section Title]
{dynamic_variable_1}

# [Another Section Title]
{dynamic_variable_2}
```

### Prompt Rules

1. **Language**: Always English, regardless of application language
2. **Format Variables**: Use `{variable_name}` for dynamic content
3. **System Prompt**: Focus on role clarity and specific guidelines
4. **User Prompt**: Use section titles (with #) to organize dynamic content
5. **Conciseness**: Keep prompts focused - avoid unnecessary explanation

## Quick Reference

**Creating a node:**
1. Define InputState and OutputState (inherit from state.py)
2. Add SYSTEM_TEMPLATE and USER_TEMPLATE if using LLM
3. Add ResponseSchema if structured output needed
4. Implement NodeName class with __init__ and async __call__
5. Add _get_context helper method for dynamic content

**Adding state fields:**
1. Open state.py
2. Create new field model inheriting StateBaseModel
3. Write description in English
4. Compose into InputState/OutputState as needed

**Updating builder:**
1. Import new node
2. Add node with add_node()
3. Connect with add_edge() or add_conditional_edges()
4. Ensure function is named `build_workflow`

## Resources

This skill includes reference files with real implementation examples:

- **references/node-examples.md** - Complete node implementations from actual projects
- **references/state-examples.md** - State management patterns and examples
- **references/builder-examples.md** - Workflow graph configuration examples
