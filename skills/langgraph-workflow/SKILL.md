---
name: langgraph-workflow
description: Develop standardized LangGraph-based workflows following specific code patterns and directory structures. Use this skill when creating or modifying LangGraph workflows, including (1) Creating new workflow nodes, (2) Adding or updating state models, (3) Building or modifying workflow graphs, (4) Writing LLM prompts for nodes, or (5) Implementing map-reduce patterns in workflows.
---

# LangGraph Workflow Development Guide

## Framework Overview

LangGraph is a framework for expressing Agent Workflows as node-and-edge graphs. The core concepts are:
- **Node**: A processing step in the workflow
- **State**: Data passed between nodes

## Directory Structure

```
workflow/
├── nodes/              # Node implementations (one file per node)
│   ├── __init__.py     # Empty file
│   └── {node_name}.py  # Node implementation
├── builder.py          # Connect nodes and compile graph
├── state.py            # Input/Output states and nested models
└── utils.py            # Utility functions (retry policy, parsers)
```

## File Overview

### state.py
- `extend_state`: Reducer function for parallel node list field handling
- `StateBaseModel`: Base model for all pydantic models
- `InputState` / `OutputState`: Workflow input/output definitions
- Nested models: Complex data types used in node states

→ See [references/state.md](references/state.md) for detailed rules and template

### builder.py
- `build_workflow()`: Main function that constructs the graph
- Graph construction: add nodes, connect edges, compile

→ See [references/builder.md](references/builder.md) for detailed rules and template

### utils.py
- `node_retry_on`: Retry policy for transient failures
- `StructuredOutputParser`: JSON parser for Bedrock LLM responses

→ See [references/utils.md](references/utils.md) for detailed rules and template

### nodes/
- One file per node
- Each file contains: InputState, OutputState, templates (if LLM), node class

→ See [references/nodes/](references/nodes/) for node type-specific guides:
  - [basic-node.md](references/nodes/basic-node.md) - Non-LLM nodes
  - [llm-node.md](references/nodes/llm-node.md) - LLM nodes
  - [structured-output-openai.md](references/nodes/structured-output-openai.md) - Structured output with OpenAI
  - [structured-output-bedrock.md](references/nodes/structured-output-bedrock.md) - Structured output with Bedrock
  - [conditional-edge.md](references/nodes/conditional-edge.md) - Conditional routing
  - [map-reduce.md](references/nodes/map-reduce.md) - Map-reduce pattern

### Prompt Writing
→ See [references/prompt-guide.md](references/prompt-guide.md) for SYSTEM_TEMPLATE, USER_TEMPLATE, and ResponseFormat guidelines
