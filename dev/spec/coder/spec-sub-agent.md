
# Spec: Sub-agent Support for pro@coder

This document defines the specification for the `sub_agents` feature in `pro@coder`. This feature allows users to chain specialized agents to pre-process parameters, instructions, and task data at various stages of the agent execution.

## Overview

The `sub_agents` feature enables a pipeline where multiple agents can modify the state of the current request. This is particularly useful for context building, automated file selection, instruction refinement, or post-processing AI responses.

### Execution Stages

Sub-agents can be triggered at different points in the `pro@coder` lifecycle, identified by the `coder_stage` variable:

- `pre`: Runs during `# Before All` (initialization).
- `pre_task`: Runs during `# Data` (before each task prompt is rendered).
- `post_task`: Runs during `# Output` (after each AI response).
- `post`: Runs during `# After All` (final cleanup/aggregation).

**Note**: The first iteration focuses on the `pre` stage.

## Configuration

Sub-agents are defined in the TOML metadata block of the coder prompt file.

```toml
sub_agents = ["context-builder", "pro@coder/agent-selector"]
```

## Data Structures

### Sub-agent Input

Each sub-agent receives a single input table containing the current state of the request, the execution stage, and the current parameters.

```ts
type SubAgentInput = {
  coder_stage: "pre" | "pre_task" | "post_task" | "post",
  coder_params: table, // Current parameters (TOML parsed, or modified by previous sub-agents)
  prompts: string[] // List of prompt segments (initially [instruction])
  custom?: table, // optional, from the sub_agent list when
  options?: table, // ...
}
```

### Sub-agent Output

Sub-agents must return a table adhering to this format. If `after_all` is `nil` (e.g., the stage returns nothing), it is interpreted as success with no modifications to the state. If `coder_params` or `prompts` are omitted, the previous state is preserved.

```ts
type SubAgentOutput = {
  success: boolean,
  coder_params?: table,  // Optional: Replaces the current parameters if provided
  prompts?: string[],    // Optional: Replaces the current prompts list if provided
  error_msg?: string,    // Required if success is false
  error_details?: string // Optional: More context for failure
}
```

## Execution Flow

The execution occurs in the `# Before All` stage of `pro@coder/main.aip`.

1.  **Extraction**: The main agent extracts the `meta` and `inst` from the prompt file.
2.  **Initialization**: 
    - `current_params` is set to the extracted metadata.
    - `current_prompts` is initialized as `{ inst }`.
3.  **Iteration**: For each `agent_name` in `meta.sub_agents`:
    - Invoke `local run_res = aip.agent.run(agent_name, { inputs = { { coder_stage = "pre", coder_params = current_params, prompts = current_prompts } } })`.
    - Let `res = run_res.after_all`.
    - If `res` is nil, continue to the next sub-agent (interpreted as success with no modifications).
    - If `res.success == false`, halt execution and report `res.error_msg` and `res.error_details`.
    - If `res.coder_params` is present, `current_params = res.coder_params`.
    - If `res.prompts` is present, `current_prompts = res.prompts`.
4.  **Finalization**:
    - The final parameters used by the main agent is `current_params`.
    - The final instruction `inst` is created by `table.concat(current_prompts, "\n\n")`.

## Module Responsibilities

### `utils_sub_agent.lua`

This new module will encapsulate the logic for:
- Iterating over the sub-agent list.
- Handling the `aip.agent.run` calls.
- Validating the return format.
- Merging/Replacing state.

### `utils_before_all.lua`

This module will be updated to:
- Detect the presence of `sub_agents` in the parameters.
- Call the `utils_sub_agent` logic.
- Use the resulting `coder_params` and `inst` for subsequent logic (file listing, mode detection).

## Error Handling

- Sub-agent errors are considered fatal for the current run.
- Validation errors (e.g., sub-agent not returning a table or missing `success` field) should be reported clearly to the user.

```lua
-- Example Error Return in main agent flow
return nil, nil, "Sub-agent [" .. agent_name .. "] failed: " .. error_msg
```
