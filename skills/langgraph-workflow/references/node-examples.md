# Node Implementation Examples

This file contains real-world examples of LangGraph workflow nodes.

## Example 1: Query Rewriter Node (LLM-based with Structured Output)

A complete example showing all components of a node that uses LLM with structured output:

```python
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from pydantic import Field
from typing import List, Dict, Any
from backend.services.conversation_history_service import ConversationHistoryService
from ..state import StateBaseModel, UserMessage, SessionId, RewrittenQuery


# 1. Input/Output State Definitions
class InputState(UserMessage, SessionId):
    pass


class OutputState(RewrittenQuery):
    pass


# 2. LLM Templates
SYSTEM_TEMPLATE = """You are a query rewriting expert for a legal chatbot.

**Role:**
If the user's question depends on previous conversation context, rewrite it into a complete, self-contained question.

**Rewriting Required When:**
1. Pronouns used: "that", "then", "in that case", "that law", "the child", "the company", etc.
2. Omitted subject/object: "How many years is possible?", "Who should pay?", "Where to submit?"
3. Questions assuming previous context: "What other documents needed?", "Then the cost?"

**No Rewriting Needed When:**
1. Already a complete sentence
2. First question (no conversation history)
3. New question unrelated to previous context

**Rules:**
- Maintain the user's speaking style (informal/formal)
- Include specific details mentioned in previous conversation
- Never change the core intent of the question
- Don't add unnecessary content
- If no rewriting needed, return the original question as-is

**Examples:**

<conversation_history>
User: Tell me about parental leave process.
AI: Parental leave is governed by Labor Standards Act Article 74...
</conversation_history>

<current_query>
Then how many children are supported?
</current_query>

Output:
rewritten_query = "How many children are supported under the parental leave system?"
reasoning = "Previous conversation discussed parental leave, and 'children are' was an incomplete expression that was clarified to 'how many children are supported under the parental leave system'."
"""


USER_TEMPLATE = """Analyze the conversation below and rewrite the question:

<conversation_history>
{conversation_history}
</conversation_history>

<current_query>
{current_query}
</current_query>"""


# 3. Response Schema
class ResponseFormat(RewrittenQuery):
    pass


# 4. Node Class
class QueryRewriter:
    name = "QueryRewriter"

    def __init__(self, model_name: str, temperature: float = 0.0):
        model = ChatOpenAI(model=model_name, temperature=temperature)
        self.agent = create_agent(model=model, response_format=ResponseFormat)
        self._history_service = ConversationHistoryService()

    async def __call__(self, state: InputState) -> OutputState:
        # Early return if no conversation history
        conversation_history = await self._history_service.load_conversation_history(
            state.session_id, limit=6
        )
        if len(conversation_history) <= 1:
            return OutputState(rewritten_query=state.user_message)

        # Get context
        conversation_history_str = "\n".join(
            [f"{msg['role']}: {msg['content']}" for msg in conversation_history]
        )

        # Format prompts
        user_prompt = USER_TEMPLATE.format(
            conversation_history=conversation_history_str,
            current_query=state.user_message,
        )

        # Invoke LLM
        response = await self.agent.ainvoke(
            {
                "messages": [
                    {"role": "system", "content": SYSTEM_TEMPLATE},
                    {"role": "user", "content": user_prompt},
                ]
            }
        )
        rewritten_query = response["structured_response"].rewritten_query

        return OutputState(rewritten_query=rewritten_query)
```

**Key Points:**
- InputState combines UserMessage and SessionId from state.py
- OutputState uses RewrittenQuery from state.py
- SYSTEM_TEMPLATE is detailed with role, rules, and examples
- USER_TEMPLATE uses clear section headers with format variables
- ResponseFormat inherits from the state field (RewrittenQuery)
- Node handles both LLM invocation and early returns based on logic
- Uses external services (conversation history) for context

## Example 2: Step-Back Query Node (Simpler LLM Node)

A simpler node focusing on prompt transformation:

```python
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI
from ..state import RewrittenQuery, StepBackQuery


class InputState(RewrittenQuery):
    pass


class OutputState(StepBackQuery):
    pass


SYSTEM_TEMPLATE = """You are an expert at creating step-back questions for legal queries.

**Role:**
Transform specific legal questions into broader, more general questions that help establish foundational understanding.

**Task:**
Generate a step-back question that addresses the underlying legal principles or concepts.

**Guidelines:**
- Make the question more abstract and general than the original
- Focus on fundamental concepts, not specific cases
- Keep the legal domain relevant
- Ensure the step-back question would help answer the original question
"""


USER_TEMPLATE = """# Original Query
{rewritten_query}

Generate a broader step-back question that establishes foundational understanding."""


class ResponseFormat(StepBackQuery):
    pass


class StepBack:
    name = "StepBack"

    def __init__(self, model_name: str, temperature: float = 0.2):
        model = ChatOpenAI(model=model_name, temperature=temperature)
        self.agent = create_agent(model=model, response_format=ResponseFormat)

    async def __call__(self, state: InputState) -> OutputState:
        user_prompt = USER_TEMPLATE.format(rewritten_query=state.rewritten_query)

        response = await self.agent.ainvoke(
            {
                "messages": [
                    {"role": "system", "content": SYSTEM_TEMPLATE},
                    {"role": "user", "content": user_prompt},
                ]
            }
        )

        step_back_query = response["structured_response"].step_back_query
        return OutputState(step_back_query=step_back_query)
```

**Key Points:**
- Much simpler structure - one input field, one output field
- No complex context building or early returns
- Direct prompt formatting and LLM invocation
- Higher temperature (0.2) for more creative output

## Example 3: Synthesis Node (Non-LLM Logic Node)

A node that performs pure logic without LLM:

```python
from ..state import (
    IntroAnswer, StatuteAnswer, PrecedentAnswer,
    AdviceAnswer, NextActionAnswer, Response
)


class InputState(
    IntroAnswer, StatuteAnswer, PrecedentAnswer,
    AdviceAnswer, NextActionAnswer
):
    pass


class OutputState(Response):
    pass


class Synthesis:
    name = "Synthesis"

    async def __call__(self, state: InputState) -> OutputState:
        # Combine all answer sections into markdown response
        sections = []

        if state.intro_answer:
            sections.append(state.intro_answer)

        if state.statute_answer:
            sections.append(f"## Related Statutes\n\n{state.statute_answer}")

        if state.precedent_answer:
            sections.append(f"## Related Precedents\n\n{state.precedent_answer}")

        if state.advice_answer:
            sections.append(f"## Practical Advice\n\n{state.advice_answer}")

        if state.next_action_answer:
            sections.append(f"## Next Steps\n\n{state.next_action_answer}")

        response = "\n\n".join(sections)
        return OutputState(response=response)
```

**Key Points:**
- No LLM templates or ResponseSchema
- No __init__ method (no model initialization needed)
- Pure Python logic to combine multiple inputs
- Still uses InputState/OutputState pattern
- Still has async __call__ for consistency

## Pattern Summary

**LLM Node with Structured Output:**
- Include SYSTEM_TEMPLATE, USER_TEMPLATE, ResponseSchema
- Initialize model and agent in __init__
- Use ainvoke() with messages
- Extract structured_response from result

**Simple LLM Node:**
- Minimal context preparation
- Direct prompt formatting
- Single-purpose transformation

**Logic Node:**
- No LLM templates or ResponseSchema
- No __init__ if no external dependencies
- Pure Python logic
- Still maintains async pattern
