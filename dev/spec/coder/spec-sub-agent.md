
# Spec: Sub-agent Support for pro@coder

This document defines the specification for the `sub_agents` feature in `pro@coder`. This feature allows users to chain specialized agents to pre-process parameters, instructions, and task data at various stages of the agent execution.

## Requirements

- **AIPack Version**: 0.8.15 or above.

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
They can be defined as a simple string (the agent name) or an object containing the name and additional properties.

```toml
sub_agents = [
  "context-builder",
  { name = "pro@coder/agent-selector", some_prop = "value" }
]
```

## Data Structures

### Sub-agent Input

Each sub-agent receives a single `input` table (accessible via the `input` variable in `# Data` and `# Output` stages) containing the current state of the request, the execution stage, the parameters, and the prompt segments.

```ts
type SubAgentInput = {
  // Current execution stage
  coder_stage: "pre" | "pre_task" | "post_task" | "post",
  // Absolute path to the directory containing the coder prompt file
  coder_prompt_dir: string,
  // Current parameters (TOML parsed, or modified by previous sub-agents)
  coder_params: table,
  // List of prompt segments (initially [instruction])
  coder_prompts: string[],
  // Normalized configuration for the current sub-agent
  agent_config: AgentConfig,
}
```

> NOTE: For now, only coder_stage `pre` is supported

### AgentConfig

A normalized version of the sub-agent definition.

```ts
type AgentConfig = {
  name: string,
  [key: string]: any // Any other properties provided in the object definition
}
```

### Sub-agent Output

Sub-agents must return a table adhering to this format. If the return value is `nil`, it is interpreted as success with no modifications to the state. If `coder_params` or `coder_prompts` are omitted from the returned table, the previous state is preserved. If `success` is omitted, it defaults to `true`. If `error_msg` is present (even if `success` is not `false`), the execution is considered failed.

**Warning**: When providing `coder_params` or `coder_prompts`, the sub-agent should modify the existing ones. Any keys or segments removed from these structures will be lost for subsequent sub-agents and the parent `pro@coder` agent.

```ts
type SubAgentOutput = {
  coder_params?: table,  // Optional: Replaces the current parameters if provided
  coder_prompts?: string[],    // Optional: Replaces the current prompts list if provided
  success?: boolean,     // Optional (defaults to true).
  error_msg?: string,    // Optional. If present (or success is false), the run fails.
  error_details?: string // Optional: More context for failure
}
```

### Returning Data

A sub-agent can return its response in two ways:

- **Via `# Output`**: The return value of the `# Output` stage for the processed input.
- **Via `# After All`**: The return value of the `# After All` stage (which becomes the `after_all` field in `RunAgentResponse`).

## Execution Flow

The execution occurs in the `# Before All` stage of `pro@coder/main.aip`.

1.  **Extraction**: The main agent extracts the `meta` and `inst` from the prompt file.
2.  **Initialization**: 
    - `raw_params` is set to the extracted metadata.
    - `agent_configs` is created by normalizing `raw_params.sub_agents` into a list of `AgentConfig` objects using `extract_sub_agent_configs`.
    - `current_params` is initialized with `raw_params`.
    - `current_params.context_globs`, `current_params.structure_globs`, and `current_params.knowledge_globs` are initialized as empty tables `{}` if they are `nil`.
    - `current_coder_prompts` is initialized as `{ inst }`.
3.  **Iteration**: For each `config` in `agent_configs`:
    - Prepare `coder_params_for_sub` by deep cloning `current_params` and removing the `sub_agents` key (using `extract_coder_params`).
    - Prepare sub-input with `agent_config = config`, `coder_params = coder_params_for_sub`, and other state fields.
    - Invoke `local run_res = aip.agent.run(config.name, { input = sub_input, ... })`.
    - Let `res = run_res.after_all` (fallback to `run_res.outputs[1]` if `after_all` is nil).
    - If `res` is nil, continue to the next sub-agent (interpreted as success with no modifications).
    - If `res.success == false` or `res.error_msg` is present, halt execution and report error (ignore `coder_params` and `coder_prompts`).
    - If `res.coder_params` is present, `current_params = res.coder_params` (cleaned to ensure no recursive `sub_agents` insertion).
    - If `res.coder_prompts` is present, `current_coder_prompts = res.coder_prompts`.
4.  **Finalization**:
    - The final parameters used by the main agent are `current_params`.
    - The final instruction `inst` is created by `table.concat(current_coder_prompts, "\n\n")`.

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
