# State Management Examples

Real-world examples of state.py implementations for LangGraph workflows.

## Complete state.py Example

```python
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Literal, Annotated


# Reducer function for list fields
def extend_state(existing: list, update: list):
    """Append new items to existing list instead of replacing."""
    return existing + update


# Base model with strict configuration
class StateBaseModel(BaseModel):
    model_config = ConfigDict(
        extra="ignore",           # Ignore extra fields not in schema
        strict=True,              # Strict type checking
        arbitrary_types_allowed=True  # Allow non-Pydantic types
    )


# Individual field models
class Username(StateBaseModel):
    username: str = Field(default="User", description="User's display name")


class UserMessage(StateBaseModel):
    user_message: str = Field(..., description="User's input message")


class RewrittenQuery(StateBaseModel):
    rewritten_query: str = Field(..., description="Context-aware rewritten query")


class SessionId(StateBaseModel):
    session_id: str = Field(..., description="Unique session identifier")


class QueryType(StateBaseModel):
    query_type: Literal["CONSULTATION", "FACTUAL", "INTERPRETATION", "PROCEDURAL"] = (
        Field(..., description="Classified type of user query")
    )


class NeedsWebSearch(StateBaseModel):
    needs_web_search: bool = Field(
        ...,
        description="Whether the query requires web search for recent information not in legal database",
    )


class NeedsEmpathy(StateBaseModel):
    needs_empathy: bool = Field(
        ..., description="Whether the user is in an emotionally difficult situation"
    )


class StepBackQuery(StateBaseModel):
    step_back_query: str = Field(..., description="Generated step-back question")


class Answer(StateBaseModel):
    answer: str | None = Field(default=None, description="Response to user query")


# Complex nested model
class Citation(StateBaseModel):
    id: str = Field(..., description="Reference identifier")
    title: str = Field(..., description="Reference title")
    url: str = Field(..., description="Reference URL")
    type: Literal["statute", "precedent"] = Field(..., description="Type of legal reference")


# List field with reducer
class Citations(StateBaseModel):
    citations: Annotated[List[Citation], extend_state] = Field(
        default_factory=list, description="List of related statutes or precedents"
    )


class Response(StateBaseModel):
    response: str | None = Field(default=None, description="Final markdown-formatted response")


class NextResponses(StateBaseModel):
    next_responses: List[str] = Field(
        default_factory=list, description="Three suggested follow-up questions"
    )


class Lawyers(StateBaseModel):
    lawyers: List[dict] = Field(default_factory=list, description="Recommended lawyer profiles")


# Composite states for workflow
class InputState(Username, UserMessage, SessionId):
    """State required at workflow entry point."""
    pass


class PrivateState(
    RewrittenQuery, StepBackQuery, QueryType, NeedsWebSearch, NeedsEmpathy
):
    """Internal state not exposed to workflow output."""
    pass


class OutputState(
    Response, Citations, NextResponses, RewrittenQuery, StepBackQuery, Lawyers
):
    """State returned from workflow."""
    pass


class OverallState(InputState):
    """Complete state schema for the entire workflow graph."""
    pass
```

## Pattern Explanations

### 1. StateBaseModel Configuration

```python
class StateBaseModel(BaseModel):
    model_config = ConfigDict(
        extra="ignore",               # Silently ignore extra fields
        strict=True,                  # Enforce strict type validation
        arbitrary_types_allowed=True  # Allow non-Pydantic types (e.g., DB clients)
    )
```

**Why this configuration:**
- `extra="ignore"`: Prevents errors when LangGraph passes additional fields
- `strict=True`: Catches type mismatches early in development
- `arbitrary_types_allowed=True`: Allows storing complex objects like database connections

### 2. Single-Field Models

```python
class UserMessage(StateBaseModel):
    user_message: str = Field(..., description="User's input message")

class SessionId(StateBaseModel):
    session_id: str = Field(..., description="Unique session identifier")
```

**Why single-field models:**
- **Composability**: Can mix and match fields into different states
- **Reusability**: Same field can be used in InputState, OutputState, or node-specific states
- **Type safety**: Each field has its own type definition
- **Documentation**: Field descriptions are self-documenting

### 3. Enum Types with Literal

```python
class QueryType(StateBaseModel):
    query_type: Literal["CONSULTATION", "FACTUAL", "INTERPRETATION", "PROCEDURAL"] = (
        Field(..., description="Classified type of user query")
    )
```

**Why Literal over Enum:**
- More concise syntax
- Better IDE autocomplete
- Pydantic handles validation automatically
- JSON serialization works out of the box

### 4. List Fields with Reducers

```python
def extend_state(existing: list, update: list):
    return existing + update

class Citations(StateBaseModel):
    citations: Annotated[List[Citation], extend_state] = Field(
        default_factory=list, description="List of related statutes or precedents"
    )
```

**Why use reducers:**
- **Accumulation**: Multiple nodes can add to the same list
- **Map-reduce patterns**: Parallel nodes can contribute items
- **No conflicts**: LangGraph knows to merge, not replace

**Without reducer:** Each node would overwrite the list
**With reducer:** Each node appends to the list

### 5. Optional Fields

```python
class Answer(StateBaseModel):
    answer: str | None = Field(default=None, description="Response to user query")
```

**When to use optional fields:**
- Field may not be populated by all workflow paths
- Field is populated conditionally
- Field represents intermediate results

### 6. Nested Models

```python
class Citation(StateBaseModel):
    id: str = Field(..., description="Reference identifier")
    title: str = Field(..., description="Reference title")
    url: str = Field(..., description="Reference URL")
    type: Literal["statute", "precedent"] = Field(..., description="Type of legal reference")

class Citations(StateBaseModel):
    citations: Annotated[List[Citation], extend_state] = Field(
        default_factory=list, description="List of related statutes or precedents"
    )
```

**Why nested models:**
- Strong typing for complex data structures
- Validation for each citation
- Clear schema for what citations contain

### 7. Composite States

```python
class InputState(Username, UserMessage, SessionId):
    pass

class OutputState(Response, Citations, NextResponses):
    pass

class OverallState(InputState):
    pass
```

**State composition patterns:**
- **InputState**: Only fields required at workflow start
- **PrivateState**: Internal fields not exposed in output
- **OutputState**: Fields returned from workflow
- **OverallState**: All fields available to nodes (usually extends InputState)

### 8. Field Descriptions

```python
user_message: str = Field(..., description="User's input message")
```

**Description guidelines:**
- Always write in English (even if app is in another language)
- Be concise but clear
- Describe the semantic meaning, not implementation
- Good: "User's display name"
- Bad: "The name field for the user object"

## Anti-Patterns to Avoid

### ❌ Don't: Define fields directly in composite states

```python
class InputState(StateBaseModel):
    username: str
    user_message: str
    session_id: str
```

**Why not:** Can't reuse fields, harder to maintain, breaks composition pattern

### ❌ Don't: Use mutable defaults

```python
class Citations(StateBaseModel):
    citations: List[Citation] = []  # WRONG
```

**Why not:** All instances share the same list object

✅ **Do: Use default_factory**

```python
class Citations(StateBaseModel):
    citations: List[Citation] = Field(default_factory=list)
```

### ❌ Don't: Forget reducers for lists

```python
class Citations(StateBaseModel):
    citations: List[Citation] = Field(default_factory=list)
```

**Why not:** Parallel nodes will overwrite each other's citations

✅ **Do: Use Annotated with reducer**

```python
class Citations(StateBaseModel):
    citations: Annotated[List[Citation], extend_state] = Field(default_factory=list)
```

### ❌ Don't: Use Korean in descriptions

```python
user_message: str = Field(..., description="사용자 메시지")
```

**Why not:** Violates the style guide requirement

✅ **Do: Use English descriptions**

```python
user_message: str = Field(..., description="User's input message")
```
