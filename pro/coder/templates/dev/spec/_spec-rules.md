
# Rules & Skill for creating and following a code spec

## When to use this skill

Use this file when the user asks to create, follow, implement from, or update a code specification.

## Key Rules

This file defines how to manage spec files.

- A spec should help both humans and LLMs understand a code-related functionality by capturing:
  - the intended functionality and interface
  - the code design used to implement it
  - the design considerations behind that design

- A spec should be implementation-aware, but it is not the implementation itself.

- The scope should stay code-focused, for example a module, feature, subsystem, service, API surface, data flow, UI behavior, or integration boundary.

- The format should work across stacks and architectures.

- Keep the spec clear, concise, and stable enough that plans and implementation tasks can reference its headings directly.

- Explain why the code design was chosen, but do not include broader product justification.

- When the user asks to create or update a spec, do not implement code unless implementation is explicitly requested as a separate task.

## Core spec structure

Each spec should describe one clear functionality scope and use this top-level structure:

- `# ...` document title
- `## Intent`
- `## Code Design`
- `## Design Considerations`

### Intent

Describe the what:

- the goal of the functionality
- the exposed interface or visible behavior
- the scope boundaries
- important inputs, outputs, and interactions when relevant

Do not explain broader product motivation here.

### Code Design

Describe the how:

- the main parts of the system or module
- the responsibilities of each part
- the relationships between parts
- important data flow, control flow, or lifecycle details
- the code-facing interfaces, contracts, or boundaries implementation should follow

Use subsections only when they improve clarity.

### Design Considerations

Describe the why of the chosen design:

- main design choices
- important tradeoffs and constraints
- assumptions that shaped the structure
- maintainability, performance, safety, UX, operational, or integration considerations when relevant

This section should explain the design choices, not restate the intent.


## Markdown formatting rules

- Favor concise prose and bullets.
- Use `-` for bullet points.
- Leave exactly one empty line after headings.
- Keep sections in a predictable order.
- Use short content blocks and concrete wording.
- Wrap file paths in backticks.

## Spec writing rules

- Keep each spec focused on one functionality scope. Split it if it becomes too broad.
- Be concrete enough that implementation can follow without guessing the intended architecture.
- Prefer direct statements over low-value narrative.
- Avoid aspirational wording. Define the target design clearly.
- Do not include unrelated roadmap items, process notes, or product-level rationale.
- Name major modules, services, UI areas, or data structures directly when helpful.
- Keep terminology consistent.
- List open questions clearly when they exist.

## Relationship to planning and implementation

- A spec defines the intended functionality and code design.
- A plan breaks implementation into safe incremental steps.
- Implementation should follow the current spec unless the user asks to revise it.
- When a plan step depends on a spec, reference the relevant file or heading directly.

## Quality bar

A good spec should let a reader quickly answer:

- What functionality is being defined?
- What is its interface or visible behavior?
- How is the code structured?
- Why was this design chosen?

If those answers are not easy to find, revise the spec for clarity.
