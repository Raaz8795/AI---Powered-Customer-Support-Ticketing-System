# Agentforce setup guide

## Current state
The deployed LWC calls `SupportTicketAI.suggest`, which uses transparent keyword rules as a safe, testable baseline. It does **not** call a live generative model. This keeps the starter usable even in a Developer Org without Agentforce entitlement.

## Suggested Agentforce agent
Name: Telecom Customer Support Agent

Purpose:
- Summarize a support ticket.
- Suggest category and priority.
- Detect customer sentiment.
- Draft a response for an agent to review.
- Retrieve relevant approved Knowledge articles.

Guardrails:
- Never claim an outage is confirmed unless an approved source says so.
- Never invent account status, refunds, credits, resolution times, or SLA promises.
- Do not expose customer data the current user is not authorized to access.
- Treat generated content as a draft; a human agent approves before sending.
- Escalate security, fraud, safety, and critical service cases to the designated team.

## Prompt template draft: Ticket triage
**Inputs:** ticket subject, ticket description, allowed ticket fields, approved Knowledge search results.

**Instructions:**
Return structured JSON with:
- `category`: one of Network Issue, Billing, SIM / Activation, Device Support, Service Request, General Inquiry
- `priority`: Low, Medium, High, Critical
- `sentiment`: Positive, Neutral, Negative
- `summary`: no more than 50 words
- `suggested_response`: empathetic and factual draft
- `rationale`: short evidence-based explanation
- `needs_human_review`: boolean

Do not make up facts. If evidence is insufficient, state uncertainty and set `needs_human_review` to true.

## Build steps
1. Open Setup and search for Agentforce / Agents (labels vary by Salesforce release and org entitlement).
2. Create an agent, add a support topic, and define clear topic scope and instructions.
3. Add actions for ticket summarization, classification, approved Knowledge retrieval, and response drafting.
4. Configure prompt templates or Flow/Apex actions supported by your org.
5. Ground answers in Salesforce Knowledge and explicitly permitted record fields.
6. Grant the minimum necessary access to the agent user and actions.
7. Test on synthetic cases: outage, incorrect bill, SIM activation, device support, angry customer, and ambiguous request.
8. Verify the output against expected labels and require human approval before any customer-facing action.

Agentforce builder capabilities and metadata formats vary by org and release; create the agent/prompt in Setup and retrieve supported metadata with Salesforce CLI if you want it version-controlled.
