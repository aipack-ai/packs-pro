
# Spec: Sub-agent Support for pro@coder

This document defines the specification for the `sub_agents` feature in `pro@coder`. This feature allows users to chain specialized agents to pre-process parameters, instructions, and task data at supported stages of the agent execution.

## Requirements

- **AIPack Version**: 0.8.15 or above.

## Overview

The `sub_agents` feature enables a pipeline where multiple agents can modify or inspect the state of the current request. This is particularly useful for context building, automated file selection, instruction refinement, or post-processing AI responses.

### Execution Stages

Sub-agents can be triggered at different points in the `pro@coder` lifecycle, identified by the `coder_stage` variable:

- `pre`: Runs during `# Before All` (initialization).
- `pre_task`: Runs during `# Data` (before each task prompt is rendered).
- `post_task`: Runs during `# Output` (after each AI response).
- `post`: Runs during `# After All` (final cleanup/aggregation).

Currently implemented:

- `pre`
- `post`

## Configuration

Sub-agents are defined in the metadata block of the coder prompt file.
They can be defined as a simple string, or an object containing the name and additional properties.

```yaml
sub_agents:
  - context-builder
  - name: pro@coder/agent-selector
    some_prop: value
```

## Data Structures

### Sub-agent Input

Each sub-agent receives a single `input` table (accessible via the `input` variable in `# Data` and `# Output` stages) containing the current state of the request, the execution stage, the parameters, and the prompt segments.

The current implementation supports distinct `pre` and `post` input shapes.

```ts
type SubAgentPreInput = {
  // Current execution stage for the pre pipeline.
  coder_stage: "pre",

  // Absolute path to the directory containing the coder prompt file.
  coder_prompt_dir: string,

  // Current parameters after prompt metadata parsing and any earlier pre-stage sub-agent merges.
  coder_params: table,

  // Current prompt segment, initially the user instruction, then replaced if an earlier pre-stage sub-agent returned coder_prompt.
  coder_prompt: string,

  // Normalized configuration for the current sub-agent.
  agent_config: AgentConfig,

  // Already executed pre-stage sub-agents in execution order.
  sub_agents_prev?: SubAgentHistoryItem[],

  // Not-yet-executed normalized sub-agent configs in execution order.
  sub_agents_next?: AgentConfig[],
}

type SubAgentPostInput = {
  // Current execution stage for the global after-all pipeline.
  coder_stage: "post",

  // Absolute path to the directory containing the coder prompt file.
  coder_prompt_dir: string,

  // Final effective coder params after pre-stage processing, reused as read-only post context.
  coder_params: table,

  // Resolved context file refs actually used by the main run.
  coder_context_file_refs: table | nil,

  // Resolved knowledge file refs actually used by the main run.
  coder_knowledge_file_refs: table | nil,

  // Aggregate resolved working file refs used across the run.
  coder_working_file_refs: table | nil,

  // Final effective instruction after pre-stage processing, reused as read-only post context.
  coder_prompt: string,

  // Normalized configuration for the current sub-agent.
  agent_config: AgentConfig,

  // Already executed post-stage sub-agents in execution order for this same post run.
  sub_agents_prev?: SubAgentHistoryItem[],

  // Not-yet-executed normalized sub-agent configs in execution order.
  sub_agents_next?: AgentConfig[],

  // Collected main-agent task responses in output order.
  coder_responses: CoderAgentResponse[],
}

type CoderAgentResponse = {
  // AI response body with FILE_CHANGES removed by the output layer.
  content_extruded: string,

  // Final file change apply status exposed by the output layer.
  file_changes_status: FileChangesStatus,

  // Saved raw AI response file path for this task output.
  content_raw_path: string,
}
```

Interpretation notes:

- `coder_params` in `SubAgentPostInput` reflects the final effective coder params after `pre` stage processing.
- `coder_prompt` in `SubAgentPostInput` reflects the final effective instruction after `pre` stage processing.
- `coder_context_file_refs`, `coder_knowledge_file_refs`, and `coder_working_file_refs` are the resolved file refs actually used for the main run.
- `coder_responses` contains one item per output task, in output order.
- `coder_responses[*].content_extruded` is the AI response body with file change directives removed.
- `coder_responses[*].file_changes_status` is the final file change apply result exposed by the output layer.
- `coder_responses[*].content_raw_path` points to the saved raw AI response file for that task.

### Sub-agent History Context

Sub-agents can receive stage-local pipeline history and pending tail information.

```ts
type SubAgentHistoryItem = {
  config: AgentConfig,
  agent_result: any,
  sub_agent_result: any,
}
```

Behavior:

- `sub_agents_prev` contains already executed sub-agents in the current stage run, in execution order.
- `sub_agents_next` contains not-yet-executed normalized sub-agent configs in execution order.
- During `post`, `sub_agents_prev` contains only earlier `post` executions from that same stage run, not prior `pre` history.

### AgentConfig

A normalized version of the sub-agent definition.

```ts
type AgentConfig = {
  name: string,
  enabled: boolean,
  stage_pre: boolean,
  stage_post: boolean,
  options?: table,
  [key: string]: any
}
```

Normalization defaults:

- String form normalizes to:

```ts
"my-agent"
// =>
{ name: "my-agent", enabled: true, stage_pre: true, stage_post: false }
```

- Table form applies defaults when omitted:
  - `enabled: true`
  - `stage_pre: true`
  - `stage_post: false`

### Sub-agent Output

Sub-agents must return a table adhering to one of the stage-specific output shapes below. If the return value is `nil`, it is interpreted as success with no modifications to the state. If `coder_params` or `coder_prompt` are omitted from the returned table, the previous state is preserved. If `success` is omitted, it defaults to `true`. If `error_msg` is present, even if `success` is not explicitly `false`, the execution is considered failed.

For `pre`, returned `coder_params` are merged into the current parameters, after clearing top-level config concerns that must not propagate back from sub-agents. Returned `coder_prompt` replaces the current instruction.

For `post`, returned `coder_params` and `coder_prompt` are ignored for now. `agent_result`, `sub_agents_next`, and failure fields still apply.

If a sub-agent returns any non-`nil`, non-table value, the execution fails with a validation error.

```ts
type SubAgentPreOutput = {
  // Optional params patch merged into the current coder params during pre.
  coder_params?: table,

  // Optional prompt replacement used for the remainder of the pre pipeline.
  coder_prompt?: string,

  // Optional payload exposed to downstream sub-agents through sub_agents_prev.
  agent_result?: any,

  // Optional replacement for the pending pre-stage sub-agent tail.
  sub_agents_next?: AgentConfig[],

  // Optional success flag, defaults to true when omitted.
  success?: boolean,

  // Optional error message, run fails when present.
  error_msg?: string,

  // Optional additional failure details.
  error_details?: string,
}

type SubAgentPostOutput = {
  // Optional params payload accepted by the response contract, but ignored during post for now.
  coder_params?: table,

  // Optional prompt payload accepted by the response contract, but ignored during post for now.
  coder_prompt?: string,

  // Optional payload exposed to downstream post-stage sub-agents through sub_agents_prev.
  agent_result?: any,

  // Optional replacement for the pending post-stage sub-agent tail.
  sub_agents_next?: AgentConfig[],

  // Optional success flag, defaults to true when omitted.
  success?: boolean,

  // Optional error message, run fails when present.
  error_msg?: string,

  // Optional additional failure details.
  error_details?: string,
}
```

### Returning Data

A sub-agent can return its response in two ways:

- Via `# Output`, as the return value of the `# Output` stage for the processed input.
- Via `# After All`, as the return value of the `# After All` stage, which becomes the `after_all` field in the run response.

If both exist, `# After All` takes precedence.

## Execution Flow

The execution occurs through the shared sub-agent runner, with `pre` invoked from the main setup path and `post` invoked once globally in `# After All`.

### Pre-stage flow

The `pre` stage runs before the main coder task execution.

1. Extract prompt metadata and instruction.
2. Normalize `sub_agents` into shared `AgentConfig` objects.
3. Initialize:
   - `current_params` from prompt metadata
   - `current_coder_prompt` from the instruction
   - empty table defaults for:
     - `context_globs`
     - `structure_globs`
     - `knowledge_globs`
     - `context_globs_pinned`
     - `knowledge_globs_pinned`
4. Iterate the normalized sub-agent list.
5. Skip configs that are disabled for the current stage:
   - `enabled == false`
   - `stage_pre == false` when running `pre`
6. For each executed sub-agent:
   - prepare `coder_params` without the top-level `sub_agents` key
   - pass `sub_agents_prev` and `sub_agents_next`
   - invoke the sub-agent
   - accept `nil` as success with no modifications
   - fail on invalid non-table responses
   - fail when `success == false` or `error_msg` is present
   - merge returned `coder_params` into current params after clearing config-level properties that must not propagate back
   - replace `current_coder_prompt` when `coder_prompt` is returned
   - preserve `agent_result` in execution history
   - allow `sub_agents_next` to replace the pending pipeline tail
7. Persist the normalized sub-agent list in final effective params for later `post` reuse.

### Post-stage flow

The `post` stage runs once globally after all task outputs complete.

1. Collect the final effective:
   - `coder_params`
   - `coder_prompt`
   - `coder_prompt_dir`
2. Collect the resolved file refs used by the main run:
   - `coder_context_file_refs`
   - `coder_knowledge_file_refs`
   - `coder_working_file_refs`
3. Collect ordered `coder_responses` from task outputs.
4. Run the shared sub-agent pipeline for stage `post`.
5. Skip configs that are disabled for the current stage:
   - `enabled == false`
   - `stage_post ~= true` when running `post`
6. Accept the same response validation and failure rules as `pre`.
7. Ignore returned `coder_params` and `coder_prompt` for now.

## Module Responsibilities

### `utils_sub_agent.lua`

This module encapsulates the logic for:

- Normalizing sub-agent config into shared `AgentConfig` objects
- Iterating over the sub-agent list
- Handling the `aip.agent.run` calls
- Validating the return format
- Filtering execution by stage (`pre` or `post`)
- Merging `pre` stage state updates
- Preserving `agent_result` in stage-local history
- Supporting dynamic tail replacement through `sub_agents_next`
- Passing stage-specific extra input payloads such as resolved file refs and `coder_responses`

### `utils_before_all.lua`

This module is responsible for:

- Detecting the presence of `sub_agents` in the parameters
- Running the shared sub-agent logic for the `pre` stage
- Using the resulting `coder_params` and `inst` for subsequent main-agent setup logic
- Preserving the normalized sub-agent list in final effective params for reuse by `post`

### `main.aip`

The main agent is responsible for:

- Persisting the final effective coder state and resolved file refs needed by `# After All`
- Returning structured per-task artifacts from `# Output`, including:
  - `content_extruded`
  - `file_changes_status`
  - `content_raw_path`
- Running the shared sub-agent logic once globally for the `post` stage in `# After All`
- Surfacing post-stage failures as fatal run results without implying rollback of already-applied file changes

## Error Handling

- Sub-agent errors are considered fatal for the current run.
- Validation errors, for example invalid non-table responses, should be reported clearly to the user.
- `post` stage failures are fatal for the run result, but they do not imply rollback of already-applied file changes.

```lua
-- Example Error Return in main agent flow
return nil, nil, "Sub-agent [" .. agent_name .. "] failed: " .. error_msg
```
