# Prompt Writing Guide

## Core Principles

- **All prompts must be written in English**
- SYSTEM_TEMPLATE: Role definition + answer guidelines
- USER_TEMPLATE: Dynamic context input

## SYSTEM_TEMPLATE Structure

### Template
```python
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
```

### Writing Guidelines

1. **Role Definition (1-2 sentences)**
   - Clearly state what the LLM is and what task it performs
   - Example: "You are a query rewriting assistant. Your task is to transform user queries into optimized search queries."

2. **Answer Guidelines**
   - Break down the task into numbered steps
   - For each step, specify:
     - What context to reference from state fields
     - How to behave in different conditions or edge cases
     - Inline examples when helpful for clarity

## USER_TEMPLATE Structure

### Template
```python
USER_TEMPLATE = """# [Section Title 1]
{context_variable_1}

# [Section Title 2]
{context_variable_2}
"""
```

### Writing Guidelines

- Used for dynamic context injection
- Each context section must be clearly separated
- Section titles should describe the content type
- Variables are filled from state fields via `.format()`

### Example
```python
USER_TEMPLATE = """# User Query
{query}

# Search Results
{search_results}

# Previous Analysis
{analysis}
"""
```

## Answer Format Section (Bedrock Only)

When using StructuredOutputParser with Bedrock, add this section to SYSTEM_TEMPLATE:

```python
SYSTEM_TEMPLATE = """[Role definition...]

## Answer Guidelines
...

## Answer Format
The output should be formatted as a JSON instance that conforms to the JSON schema below.
As an example, for the schema {{"properties": {{"foo": {{"title": "Foo", "description": "a list of strings", "type": "array", "items": {{"type": "string"}}}}}}, "required": ["foo"]}}
the object {{"foo": ["bar", "baz"]}} is a well-formatted instance of the schema. The object {{"properties": {{"foo": ["bar", "baz"]}}}} is not well-formatted.
Here is the output schema:
```json
{response_schema}
"""
```

Usage in node:
```python
system_prompt = SYSTEM_TEMPLATE.format(
    response_schema=json.dumps(ResponseSchema.model_json_schema(), indent=2, ensure_ascii=False)
)
```

## ResponseFormat Field Descriptions

When defining ResponseFormat for structured output:

```python
class ResponseFormat(StateBaseModel):
    field_name: type = Field(..., description="Clear, concise explanation of what this field should contain")
```

### Description Guidelines

- **Language**: Write in English
- **Clarity**: Make it easy for LLM to understand what to fill
- **Conciseness**: Keep descriptions brief but informative
- **Context**: Include any constraints or formatting requirements

### Example
```python
class ResponseFormat(StateBaseModel):
    rewritten_query: str = Field(..., description="The optimized search query with improved keywords")
    confidence_score: float = Field(..., description="Confidence score between 0.0 and 1.0 indicating query quality")
    reasoning: str = Field(..., description="Brief explanation of the changes made to the original query")
```
