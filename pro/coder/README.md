# pro@coder documentation

This is the documentation and usage guide for the `pro@coder` AI Pack.

The `pro@coder` pack provides AI-powered coding assistance through parametric prompts that allow you to configure context, working files, sub-agent pipelines, and AI model settings for your coding tasks.

The key concept of `pro@coder` is to give you full control over the AI context, enabling you to guide the AI to code the way you want, rather than adapting to the AI's default approach. This is done in part by splitting files into `knowledge`, `context`, and `working` (for concurrency) categories.

[Coder Parameters](#coder-parameters) | [Auto Context](#auto_context) | [Dev](#dev) | [Workflow](#setup--workflow) | [Coder Intro](#coder-promptmd) | [Coder Parameters](#parametric-block-format) | [AIPack config override](#aipack-config-override) | [Plan Development](#plan-based-development)

---

## Setup & Workflow

How to install and run the AI Pack:

```sh
# To install or update to latest
aip install pro@coder

# To run pro@coder
aip run pro@coder
```

1. Run `aip run pro@coder` to create your parametric prompt file
2. Edit the YAML configuration block to specify your context files, working files, and model
3. Write your coding instructions above the `====` separator
4. Press `r` in the aip terminal to execute
5. Review generated code below the `====` separator
6. Set `write_mode: true` when ready to write files to disk

More:

- See [Plan-Based Development](#plan-based-development)

## coder-prompt.md

When running `aip run pro@coder`, a parametric prompt file, `coder-prompt.md`, is created by default at `.aipack/.prompt/pro@coder/coder-prompt.md`.

The prompt folder can be customized with the `-i` AI Pack parameter. For example:

`aip run pro@coder -i some/dir` (this will create `./some/dir/coder-prompt.md`)

### Structure

A coder prompt file consists of three main sections:

1. **YAML Configuration Block** - A markdown code block, by default `yaml` marked as `#!meta (parametric prompt)`, containing all configuration parameters for this agent.

2. **Prompt Instructions** - After this code block and before the `====` marker, this is the natural language prompt to be sent to the LLM with all of the other context specified in the configuration block.

3. **AI Info Section** - Below the `====` separator. Lines prefixed with `>` are meta information about the AI execution (additional info is also available), followed by AI responses and generated code.

Also, when `write_mode: true`, the file content will be removed from the AI response section (below the `====`) and saved to its corresponding file path.

### Coder Parameters

Here is the fully documented parametric code block with its possible values:

```yaml
#!meta (parametric prompt)

# If not set, context_globs and working_globs won't be evaluated
## (relative to workspace dir)
base_dir: "" # Leave empty for workspace root; make sure to refine context_globs

## Add absolute, relative, ~/, or some@pack knowledge globs.
## They will be included in the prompt as knowledge files.
## (relative to workspace dir, i.e. .aipack/ parent dir)
knowledge_globs:
# - path/to/knowledge/**/*.md         # Your own best practices
# - core@doc/**/*.md                  # To help code .aip aipack agents
# - pro@rust10x/guide/base/**/*.md    # Some Rust best practices

## Pinned knowledge globs (always included, not removed by auto_context)
knowledge_globs_pre:       # Prepended before auto-context selection
  - core@doc/**/*.md
knowledge_globs_post:      # Appended after auto-context selection
  - path/to/best-practices/**/*.md

## Files that will be included in your prompt as context files.
## Relative to base_dir, try to keep them as narrow as possible for a large codebase
## The manifest file like package.json or Cargo.toml are good context for the AI at relatively low context cost/size
## (relative to base_dir)
context_globs:
# - package.json    # e.g., for Node.js
# - Cargo.toml      # e.g., for Rust
  - src/**/*.*      # Narrow glob when more than 10 files

## Pinned context globs (always included, not removed by auto_context)
context_globs_pre:         # Prepended after auto-context selection
  - package.json
context_globs_post:        # Appended after auto-context selection
  - .aipack/.prompt/pro@coder/dev/plan/*.md

## Relative to base_dir. Only include paths (not content) in the prompt.
## (A good way to give the AI a cheap overview of the overall structure of the project)
## (relative to base_dir)
structure_globs:
  - src/**/*.*

## Working Globs - Advanced - Create a task per file or file group.
## NOTE - Only enable when working on multiple files at the same time
working_globs:
  - src/**/*.js        # This will do one working group per matched .js
  - ["css/*.css"]      # When in a sub array, this will put all of the css in the same working group
input_concurrency: 2   # Number of concurrent tasks (default set in the config TOML files)

# Max size in KB of all included files (safeguard, default 1000, for 1MB)
max_files_size_kb: 1000

## Explicit cache (Default false)
cache_explicit: false  # Explicit cache for pro@coder prompt and knowledge files (Anthropic only)

## (default true) Will tell the AI to suggest a git commit
suggest_git_commit: false

## Note: This will add or override the model_aliases defined in
##       .aipack/config.toml, ~/.aipack-base/config-user.toml, ~/.aipack-base/config-default.toml
model_aliases:
  super-gpro: gemini-3.1-pro-high # example

## Typically, omit or leave this commented for "udiffx", which is the most efficient
file_content_mode: udiffx # default "udiffx" ("search_replace_auto" for legacy or "whole" for full rewrite)

## Set to true to write the files (otherwise, they will be shown below the `====` separator)
write_mode: true

## MODEL: Here you can use any full model name or model aliases defined above and in the config.toml
## such as ~/.aipack-base/config-default.toml
## For OpenAI and Gemini models, you can use the -low, -medium, or -high suffix for reasoning control

# Full model names (any model name for available API Keys) 
# or aliases "opus", "codex", "gpro" (for Gemini 3 Pro), "flash" (see ~/.aipack-base/config-default.toml)
# Customize reasoning effort with -high, -medium, or -low suffix (e.g., "opus-high", "gpro-low")
model: gpt-5.2 

## Automatic context file selector (shortcut for pro@coder/auto-context sub-agent)
## Since v0.4.0
auto_context:
  model: flash                # The model used to analyze the instruction and code map
  enabled: true               # Whether to run the auto-context agent (default true)
  knowledge: true             # Automatically select knowledge files (default true)
  mode: reduce                # "reduce" (replaces) or "expand" (adds to existing) (default "reduce")
  # input_concurrency: 8      # code map building concurrency (default 8, or coder value)
  # code_map_model: flash-low # code map model (optional, default auto_context model above)
  helper_globs:               # Files to help select relevant context files
    - .aipack/.prompt/pro@coder/dev/plan/*.md

## Dev helpers (shortcut for pro@coder/dev sub-agent)
dev:
  chat: true                 # true uses default path below
  # chat: .aipack/.prompt/pro@coder/workbench-default/dev-chat.md
  # chat:
  #   enabled: true
  #   path: .aipack/.prompt/pro@coder/workbench-default/dev-chat.md
  plan: true                 # true uses default dir below
  # plan: .aipack/.prompt/pro@coder/workbench-default
  # plan:
  #   enabled: true
  #   dir: .aipack/.prompt/pro@coder/workbench-default
  spec: false                # true uses default path below
  # spec: .aipack/.prompt/pro@coder/workbench-default/spec.md
  # spec:
  #   enabled: true
  #   path: .aipack/.prompt/pro@coder/workbench-default/spec.md

## Specialized agents to pre-process parameters and instructions, or to run once after all task outputs
## Since v0.3.0 for pre, post-stage support implemented later
sub_agents:
  - my-agents/prompt-cleaner.aip # simple .aip file (see sub_agent section for input / output)
  - name: pro@coder/code-map     # code-map sub agent is also used in auto-context (but here is a custom example) (since v0.4.0)
    enabled: true # default run
    stage_pre: true
    stage_post: false
    named_maps: 
      - name: external-lib-docs  # will create .aipack/.prompt/pro@coder/.cache/code-map/external-lib-docs-code-map.json
        globs: 
          - doc/external-libs/**/*.md


## To see docs, type "Show Doc" and then press `r` in the aip terminal
```

#### base_dir

Base directory for resolving `context_globs`, `working_globs`, and `structure_globs`. Leave empty for workspace root. When not set or empty, the glob parameters won't be evaluated.

#### knowledge_globs

Array of glob patterns for knowledge files that will be included as knowledge to the AI. These can be:

- Absolute paths
- Relative paths (to workspace root)
- Home directory paths (`~/`)
- Pack references (`some@pack/path/**/*.md`)

This is a great place to put some relatively fix content, like coding best practices, documentation of some libraries, some relatively fix rules on how to create/maintain plan, spec, requirement type of content.

Example:

```yaml
knowledge_globs:
  - path/to/knowledge/**/*.md           # Can be relative to workspace or absolute
  - pro@coder/README.md                 # This is this README.md from the pro@coder, can be used to ask questions about pro@coder
  - core@doc/**/*.md                    # core@doc is a built-in pack with the AI Pack doc
  - pro@rust10x/guide/base/**/*.md      # aip install pro@rust10x, and then this will be available
```

For advanced users, here we can also put the "rules" of the plan or spec base folder like

```yaml
knowledge_globs:
  - .aipack/.prompt/pro@coder/dev/plan/_plan-rules.md
```

And then, in the `context_globs` we can put the plan minus this file by excluding the `_` like

```yaml
context_globs:
  - .aipack/.prompt/pro@coder/dev/plan/[!_]*.md
```

#### knowledge_globs_pre & knowledge_globs_post

`knowledge_globs_pre` are prepended and `knowledge_globs_post` are appended to the knowledge files selection. They are never removed by auto-context.

Example:

```yaml
knowledge_globs_pre:
  - core@doc/**/*.md
knowledge_globs_post:
  - path/to/my/best-practices/**/*.md
```

Final knowledge globs order: `knowledge_globs_pre + auto_context_selected + knowledge_globs_post` (deduped).

#### context_globs

Array of glob patterns (relative to `base_dir`) for files to include as context. These files will be described to the AI as "User's context files". Keep these as narrow as possible for large codebases.

This is a great place to put the code we want to send to the AI for a particular task.

For small codebases, we can have relatively wide globs like `src/**/*.ts`, but as the codebase becomes larger (>5k LOC), using narrower globs can be very effective at improving cost, accuracy, and speed, while minimizing costs.

Example:

```yaml
context_globs:
  - package.json
  - src/main.ts
  - src/event/*.ts
```

#### context_globs_pre & context_globs_post

`context_globs_pre` are prepended and influence auto-context selection; `context_globs_post` are appended after auto-context selection. They are never removed by auto-context.

Example:

```yaml
context_globs_pre:
  - package.json
  - src/shared/**/*.ts
context_globs_post:
  - .aipack/.prompt/pro@coder/dev/plan/*.md
```

Final context globs order: `context_globs_pre + auto_context_selected + context_globs_post` (deduped).

#### structure_globs

Array of glob patterns (relative to `base_dir`) for files whose paths (not content) will be included in the prompt. This provides the AI with an overview of the project structure at low context cost.

Typically, wider glob patterns for source code are a good idea here, as this is a relatively context-efficient way to provide an overview of the system without making the context overly large.

This also acts as a good forcing factor for having good module and file naming structures, allowing us to pass as much information as possible with the minimum token cost.

Example:

```yaml
structure_globs:
  - src/**/*.*
```

#### working_globs

Array of glob patterns or arrays of patterns that define working groups (tasks) to perform instructions concurrently across multiple working groups.

This creates tasks per file or file group:

- Single pattern string: Creates one task per matched file
- Array of patterns: Groups all matched files into a single task

Example:

```yaml
working_globs:
  - src/**/*.js        # One task per .js file
  - ["css/*.css"]      # All .css files in one task
input_concurrency: 6   # Will override the default input_concurrency
```

This will create the following tasks/working groups:

- One workgroup/task for each matched `.js` file
- One workgroup/task for all `css/*.css` files

#### input_concurrency

Number of concurrent tasks to run when processing `working_globs`. Defaults to the value set in config TOML files.

#### max_files_size_kb

Maximum total size in KB of all included files (safeguard). Default is 1000 (1MB). If over the limit, the data will NOT be sent, and a message will appear in the terminal.

#### model_aliases

Define or override model aliases. These will override the config TOML files.

These will be merged with or added to the default aliases from the AIPack config TOML files (see [#AIPack config override](#aipack-config-override)).

Example:

```yaml
model_aliases:
  gpro: gemini-pro-latest
  flash: gemini-flash-latest
```

_Note: These aliases are already present in the `~/.aipack-base/config-default.toml` (and with the latest models)._

#### file_content_mode

Controls how file content is returned:

- `udiffx` (default): Most robust and efficient, uses unified diff format.
- `search_replace_auto`: Uses SEARCH/REPLACE blocks for updates.
- `whole`: Returns entire file content

Typically, leave this out to use the default.

#### write_mode

Boolean flag controlling file writing behavior:

- `false` (default): Files are shown below the `====` separator without writing
- `true`: Files are written directly to disk

- When `write_mode: false`, the content below the `====` that doesn't start with `>` will be sent back as context to the AI. This allows for controlled conversations.
- When `write_mode: true`, the content below the `====` is **NOT** sent to the LLM; only the content specified in the parametric prompt is sent. This allows for clean prompts without confusion from previous answers.
  - To keep historical context, you can use the plan-based prompting technique and put those files in the `context_globs` parameter.

#### model

Specifies which AI model to use for this prompt.

Can be:

- Full model name (e.g., `gpt-4`, `gemini-2.5-pro`)
- Model alias defined in `model_aliases` or config files
- For OpenAI and Gemini models, can append `-low`, `-medium`, or `-high` suffix for reasoning control

Will override the default model from the AIPack config TOML files (see [#AIPack config override](#aipack-config-override)).

Example:

```yaml
model: gpt-5-mini  # or "gpt-5" for normal coding
```

#### auto_context

_since v0.4.0_

Shortcut to configure and run the `pro@coder/auto-context` sub-agent. This agent automatically identifies relevant context and knowledge files for your prompt by analyzing file summaries (via `code-map`). It is a concise alternative to defining it in the `sub_agents` list and supports the same properties.

Can be:
- **A string**: The model name to use (e.g., `auto_context: flash`).
- **A table**: Configuration for the auto-context agent.

Example:

```yaml
auto_context:
  model: flash                # The model used to analyze the instruction and code map
  enabled: true               # Whether to run the auto-context agent (default true)
  knowledge: true             # Automatically select knowledge files (default true)
  mode: reduce                # "reduce" (replaces) or "expand" (adds to existing) (default "reduce")
  # input_concurrency: 8      # code map building concurrency (default 8, or coder value)
  # code_map_model: flash-low # code map model (optional, default auto_context model above)
  helper_globs:               # Files to help select relevant context files
    - .aipack/.prompt/pro@coder/dev/plan/*.md
```

#### dev

Shortcut to configure and run the `pro@coder/dev` sub-agent. This agent enables a "dev workbench" with integrated capabilities for `chat`, `plan`, and `spec`. It automatically manages these files and wires them into the prompt context (no need to manually add them to `context_globs`).

Behavior:
- `chat` ensures the dev chat markdown file exists, then appends its path to `context_globs_post` (deduped).
- `plan` ensures `_plan-rules.md` exists in the plan directory, prepends this rules file to `knowledge_globs_pre` (deduped), and appends `plan-*.md` to `context_globs_post` (deduped).
- `spec` ensures `_spec-rules.md` exists, appends this rules file to `knowledge_globs_post` (deduped), and appends the resolved spec context file path to `context_globs_post` (deduped).
- The sub-agent returns `agent_result.dev_content_globs` containing enabled dev content globs (chat path, plan glob, and/or spec file path). This lets downstream sub-agents consume helper files without depending on `dev` config internals.
- If both `chat` and `plan` are disabled, the sub-agent is automatically disabled (no-op).

Current shape:
- **A table**:
  - `dev.chat`
  - `dev.plan`
  - `dev.spec`

Supported `dev.chat` values:
- **A boolean**:
  - `true`: Enable with default path.
  - `false`: Disable chat.
- **A string**: Path to the dev chat file.
- **A table**: `enabled`, `path`, and future-safe extra keys.

Supported `dev.plan` values:
- **A boolean**:
  - `true`: Enable with the default directory.
  - `false`: Disable plan.
- **A string**: Path to the plan directory, or a `.md` file path whose parent directory will be used as the plan directory.
- **A table**: `enabled`, `dir`, and future-safe extra keys.

Supported `dev.spec` values:
- **A boolean**:
  - `true`: Enable with the default path.
  - `false`: Disable spec.
- **A string**: Path to the spec directory, or to the spec file.
- **A table**: `enabled`, `path`, and future-safe extra keys.

### Default Workbench Behavior

`pro@coder` provides an out-of-the-box development workbench. By default, helper files are organized in a `workbench-default/` directory located in the same folder as your `coder-prompt.md` (the prompt's directory).

- **`dev.dir`**: Defines a custom shared workbench directory. If omitted, it defaults to `workbench-default/` relative to the prompt file.
- **Explicit Paths**: If `path` or `dir` is provided for a specific capability (chat, plan, or spec), it takes precedence over the shared `dev.dir`.
- **Auto-Creation**: Files and directories are created only for enabled capabilities. For example, if `dev.plan` is `false`, no plan files are created in the workbench.

Examples:

```yaml
dev:
  chat: true
  plan: true
  spec: true
```

This resolves to a flat layout:

- `.aipack/.prompt/pro@coder/workbench-default/dev-chat.md`
- `.aipack/.prompt/pro@coder/workbench-default/_plan-rules.md`
- `.aipack/.prompt/pro@coder/workbench-default/plan-*.md`
- `.aipack/.prompt/pro@coder/workbench-default/_spec-rules.md`
- `.aipack/.prompt/pro@coder/workbench-default/spec.md`

Default path when `dev.chat.path` is omitted:

`$coder_prompt_dir/workbench-default/dev-chat.md`

Default directory when `dev.plan.dir` is omitted:

`$coder_prompt_dir/workbench-default`

Default spec file path when `dev.spec.path` is omitted:

`$coder_prompt_dir/workbench-default/spec.md`

For string/table path values, relative paths are passed through unchanged.

Plan path handling details:

- `dev.plan: "some/dir"` resolves to `some/dir`.
- `dev.plan: "some/file.md"` resolves to `some` (parent directory).
- `dev.plan: "plan.md"` resolves to `.`.
- Trailing slashes are normalized.
- For table mode, `dev.plan.dir` must be a directory path, `.md` file paths are rejected with a validation error.
- When `dev.plan.dir` is omitted, the plan directory resolves directly to the shared workbench root, so `_plan-rules.md` and `plan-*.md` live flat in that directory.

Example:

Spec path handling details:

- `dev.spec: "some/dir"` resolves rules to `some/dir/_spec-rules.md` and context to `some/dir/spec.md`.
- `dev.spec: "some/spec.md"` resolves rules to `some/_spec-rules.md` and context to `some/spec.md`.
- `dev.spec: "spec.md"` resolves rules to `./_spec-rules.md` and context to `spec.md`.
- Trailing slashes are normalized.
- When `dev.spec.path` is a file path, it is treated as the spec context file, not the rules file.
- When enabled, `pro@coder/dev` also ensures a blank `spec.md` exists beside `_spec-rules.md`.
- When `dev.dir` is set and `dev.spec` is `true`, spec resolves to `dev.dir/_spec-rules.md` and `dev.dir/spec.md`.

Spec file auto-context behavior:

- The resolved spec context file path is appended to `context_globs_post` when missing.
- The rules file path is appended to `knowledge_globs_post` when missing.
- The sub-agent returns the spec context file path in `agent_result.dev_content_globs`, so downstream helper-aware sub-agents can consume it without depending on `dev` config internals.

For string or table values, relative paths are resolved relative to the workspace root unless they are absolute or use pack references.

#### sub_agents

_since v0.3.0_

Array of specialized agents to run at different stages of the `pro@coder` execution. Sub-agents allow for a pipeline where multiple agents can modify the state of the current request, which is useful for automated context building, instruction refinement, project-specific initialization, or after-all processing.

Currently, `pro@coder` seeds two canonical root events:

- `start`, during initialization (`# Before All`)
- `end`, once globally after all task outputs complete (`# After All`)

The root event-to-stage mapping is:

- `start` -> `stage: "pre"`
- `end` -> `stage: "post"`

Sub-agents may also emit and subscribe to additional namespaced events, for example:

- `auto-context::end`
- `dev::end`
- `code-map::updated`

Sub-agents can be defined as:

- **A string**: The name or path of the agent (e.g., `"my-agent"` or `"ns@pack/agent"`).
- **A table**: An object providing more control.

Available properties for the table definition:

- `name` (string): The name or path of the agent.
- `enabled` (boolean, optional, default `true`): Whether to run this sub-agent.
- `on` (string or string[], optional, default `start`): The event or events this sub-agent subscribes to.
- `options` (table): Agent options (like `model`,`input_concurrency`) specifically for this sub-agent run.
- **Additional properties**: Any other keys provided in the table will be passed to the sub-agent via the `agent_config` field in its input.

### Developing Sub-agents

Sub-agents are standard `.aip` files. They receive stage-specific input structures as their `input` (accessible in `# Data` or `# Output` stages).

```ts
type SubAgentPreInput = {
  event: string,            // Current event being handled, e.g. "start", "auto-context::end"
  stage: "pre",             // Runtime contract marker
  coder_prompt_dir: string, // Absolute path to the prompt file directory
  coder_params: table,      // Current parameters (from YAML block or previous sub-agents)
  coder_prompt: string,     // Current instruction text
  agent_config: AgentConfig,// The configuration object defined in the sub_agents list

  // Present for all stages
  sub_agents_prev?: SubAgentHistoryItem[],
  sub_agents_next?: AgentConfig[],
}
```

For `post`, the runtime input shape is:

```ts
type SubAgentPostInput = {
  event: string,
  stage: "post",
  coder_prompt_dir: string,
  coder_params: table,
  coder_prompt: string,
  agent_config: AgentConfig,
  
  sub_agents_prev?: SubAgentHistoryItem[],
  sub_agents_next?: AgentConfig[],
  
  coder_context_file_refs?: table | nil,
  coder_knowledge_file_refs?: table | nil,
  coder_working_file_refs?: table | nil,
  coder_responses: CoderAgentResponse[],
}
```

The post-stage additional response payload has this shape:

```ts
type CoderAgentResponse = {
  content_extruded: string,
  file_changes_status: FileChangesStatus,
  content_raw_path: string,
}
```

Event defaults and behavior:

- `on` defaults to `start`
- A sub-agent may therefore run on:
  - only `start`
  - only `end`
  - both `start` and `end`
  - emitted namespaced events

The dispatcher still uses `stage_pre` and `stage_post` as runtime gating flags on normalized configs for backward-compatible internal execution, but event subscription is now the public configuration model.

Normalized config shape:

```ts
type AgentConfig = {
  name: string,
  enabled: boolean,
  on: string | string[],
  stage_pre: boolean,
  stage_post: boolean,
  options?: table,
  [key: string]: any
}
```

Normalization examples:

```ts
"my-agent"
// =>
{ name: "my-agent", enabled: true, stage_pre: true, stage_post: false }

{ name: "x", stage_pre: false }
// =>
{ name: "x", enabled: true, stage_pre: false, stage_post: false }

{ name: "x", stage_post: true }
// =>
{ name: "x", enabled: true, stage_pre: true, stage_post: true }
```

To modify the request state, the sub-agent should return a stage-specific table. If the return value is `nil`, it is interpreted as success with no modifications.

```ts
type SubAgentPreOutput = {
  coder_params?: table,          // Optional: Merged into the current parameters during pre
  coder_prompt?: string,         // Optional: Replaces the current instruction during pre
  agent_result?: any,            // Optional: Pipeline payload exposed in sub_agents_prev

  sub_agents_next?: AgentConfig[], // Optional: Replaces the pending sub-agent tail
  emit_events?: string[],        // Optional: Queues follow-up events in FIFO order for the current stage

  success?: boolean,             // Optional (defaults to true). Set to false to fail.
  error_msg?: string,            // Optional. If present, the run fails with this message.
  error_details?: string,        // Optional. More context for the failure.
}
```

```ts
type SubAgentPostOutput = {
  agent_result?: any,            // Optional: Pipeline payload exposed in sub_agents_prev

  sub_agents_next?: AgentConfig[], // Optional: Replaces the pending sub-agent tail
  emit_events?: string[],        // Optional: Queues follow-up events in FIFO order for the current stage

  success?: boolean,             // Optional (defaults to true). Set to false to fail.
  error_msg?: string,            // Optional. If present, the run fails with this message.
  error_details?: string,        // Optional. More context for the failure.
}
```

**Important notes on return values**:

- `coder_params`: If provided in `SubAgentPreOutput`, this table is shallow-merged into the current parameters. This means you only need to return the keys you wish to add or change.
- `coder_prompt`: If provided in `SubAgentPreOutput`, this string replaces the current instruction for the remainder of the pipeline.
- `agent_result`: If provided, this payload is exposed to downstream sub-agents through `sub_agents_prev[*].agent_result` (and `sub_agent_result` for compatibility).
- `sub_agents_next`: If provided, it replaces the pending tail of the pipeline for future dispatch only.
- `emit_events`: If provided, the listed events are appended to the current stage event queue in order.
- Errors: If `success` is `false` or `error_msg` is present, the entire `pro@coder` run will halt with the provided error.

A sub-agent can return this data either from:

- The `# Output` stage (as the return value for the task).
- The `# After All` stage (as the final return value).

Sub-agents require AIPack 0.8.15 or above.

#### Advanced pipeline context: `sub_agents_prev` and `sub_agents_next`

When a sub-agent runs in the `pre` or `post` stage, `pro@coder` also provides pipeline context in the sub-agent input:

- `sub_agents_prev`: already executed sub-agents in the current stage run, in execution order.
- `sub_agents_next`: not-yet-executed sub-agents, in execution order.

Shape:

```ts
type SubAgentHistoryItem = {
  config: table,            // normalized sub-agent config
  agent_result: any,        // canonical result payload from that sub-agent, or nil if none
  sub_agent_result: any,    // compatibility alias of agent_result
}
```

- `sub_agents_prev` is an array of `SubAgentHistoryItem`.
- `sub_agents_next` is an array of normalized sub-agent configs (same shape as `sub_agents` entries after normalization).
- During `post`, `sub_agents_prev` contains only earlier `post` executions from that same stage run, not the prior `pre` history.

Behavior:

- A running sub-agent can return `sub_agents_next` to replace the pending tail of the current stage pipeline.
- A running sub-agent can return `emit_events` to append additional events to the current stage queue.
- This allows dynamically adding, removing, reordering, or re-introducing agents.
- Duplicates are allowed, no deduplication is applied.
- Already executed agents are not modified in-place.
- Event dispatch is FIFO and non-recursive. Emitted events are handled after the current event pass finishes.
- Safety cap: the dynamic pipeline is limited to 100 total steps to prevent accidental loops.

This is an advanced feature intended for orchestrating multi-agent flows and should generally be used only when standard `sub_agents` chaining is not sufficient.

For `post`, `sub_agents_prev` contains only earlier `post` executions from that same stage run, not the prior `pre` history.

## Builtin Sub Agents

### Sub Agent - pro@coder/dev

The dev sub-agent prepares and wires dev capabilities into context. Current capabilities are `chat`, `plan`, and `spec`.

```yaml
sub_agents:
  - name: pro@coder/dev
    enabled: true
    on: start
    chat:            # or chat: true (default false)
      enabled: true  
      # path: .aipack/.prompt/pro@coder/workbench-default/dev-chat.md
    plan:            # or plan: true (default false)
      enabled: true  
      # dir:  .aipack/.prompt/pro@coder/workbench-default
    spec:            # or spec: true (default false)
      enabled: true
      # path: .aipack/.prompt/pro@coder/workbench-default/spec.md
```

- Resolves `chat.path` from config, or defaults to `$coder_prompt_dir/workbench-default/dev-chat.md`.
- Ensures the chat file exists, if the file is empty, it is initialized with the dev-chat template.
- Resolves `plan.dir` from config, or defaults to `$coder_prompt_dir/workbench-default`.
- Ensures the plan rules file exists at `$plan_dir/_plan-rules.md`, if empty, it is initialized from template.
- Resolves `spec.path` from config as either a spec directory or a spec file path.
- Ensures the spec rules file exists at `$spec_dir/_spec-rules.md`, if empty, it is initialized from template.
- Ensures the spec context file exists at the resolved spec file path.
- When using the default shared fallback root, only the enabled helper files are created, matching the behavior of custom workbench paths.
- Appends the resolved chat path and `plan-*.md` glob to `context_globs_post` when missing (deduped).
- Prepends the plan rules path to `knowledge_globs_pre` when missing (deduped).
- Appends the spec rules path to `knowledge_globs_post` when missing (deduped).
- Appends the resolved spec file path to `context_globs_post` when missing (deduped).
- Returns `agent_result.dev_content_globs` for downstream helper-context consumption, including the spec file path when enabled.
- If all capabilities are disabled, the agent is effectively disabled and does not modify params.

The same behavior can be configured with the `dev` shortcut in the root config:

```yaml
dev:
  dir: .aipack/.prompt/pro@coder/workbench-default
  chat: true
  plan: true
  spec: true

# or use a custom directory for all workbench files
dev:
  dir: _workbench/my-feature-a
  chat: true
  plan: true
  spec: true
# or
dev:
  chat: .aipack/.prompt/pro@coder/workbench-default/dev-chat.md
  plan: .aipack/.prompt/pro@coder/workbench-default
  spec: .aipack/.prompt/pro@coder/workbench-default/spec.md
# or
dev:
  chat:
    enabled: true
    path: .aipack/.prompt/pro@coder/workbench-default/dev-chat.md
  plan:
    enabled: true
    dir:  .aipack/.prompt/pro@coder/workbench-default
  spec:
    enabled: true
    path: .aipack/.prompt/pro@coder/workbench-default/spec.md
```

- `dev.chat: true` enables chat with the default path.
- `dev.plan: true` enables plan with the default directory.
- `dev.spec: true` enables spec with the default path.
- `dev.dir` sets a shared fallback directory for boolean `true` usage and table configs that omit their own path or dir.
- When `dev.dir` is omitted, the shared fallback directory defaults to `$coder_prompt_dir/workbench-default`.
- A string sets the corresponding directory directly for plan, while spec strings can be either a directory or the spec file path.
- A table maps to the chat, plan, or spec config shape.
- If all are disabled via table config (`enabled: false`), `pro@coder` seeds `pro@coder/dev` as disabled.
- For table mode, `dev.plan.dir` is strict and must be a directory path.

### Sub Agent - pro@coder/auto-context

_since v0.4.0_

The auto-context agent can be configured via the `sub_agents` list or more concisely using the `auto_context` parameter at the root of the configuration block.

**Using the `auto_context` shortcut:**

```yaml
auto_context: flash
# or
auto_context:
  model: flash
  enabled: true
```

**Using the `sub_agents` list:**

```yaml
sub_agents: 
  # Automatic context file selector (based on context-globs, using code-map)
  - name: pro@coder/auto-context
    enabled: false              # comment or set to true (default true)
    on: start
    knowledge: true             # automatically select knowledge files (default true)
    mode: reduce                # "reduce" (default) or "expand"
    model: flash                # small/cheap model to optimize which files are selected
    # input_concurrency: 32     # code map concurrency (for building the code-map.json) (default 8)
    # code_map_model: flash-low # code map model (optional, default auto-context model above)
    helper_globs:               # Other files sent to give more information to select the proper context file
```

- `name`: Set to `pro@coder/auto-context`. This agent automatically identifies relevant files for your prompt by comparing your instruction against a "code map" (summaries of your files).
- `enabled`: Toggles the sub-agent execution.
- `model`: The model used to analyze your instruction and the code map summaries to perform the file selection.
- `knowledge`: (Optional, default `true`) If `true`, the agent will also analyze and select relevant files from `knowledge_globs`.
- `mode`: (Optional, default `"reduce"`)
  - `"reduce"`: Replaces `context_globs` with the AI selection.
  - `"expand"`: Adds the AI selection to existing `context_globs`.
  - *Note: `knowledge_globs` are always reduced (replaced).*
- `input_concurrency`: (Optional) The number of concurrent tasks used when generating or updating file summaries for the code map.
- `code_map_model`: (Optional) The model used to generate file summaries. Defaults to the `model` specified above if not provided.
- `helper_globs`: (Optional) Pattern for files (like development plans or chat logs) that provide additional guidance to help the sub-agent select the correct context files.

### Sub Agent - pro@coder/code-map

_since v0.4.0_

The code-map agent generates and maintains a JSON file containing summaries, public types, and functions for a set of files. This map is used by the `auto-context` agent to identify relevant files for your prompt, but it can also be used independently to create maps for external libraries or documentation.

**Using the `sub_agents` list:**

```yaml
sub_agents: 
  - name: pro@coder/code-map
    enabled: true
    globs: 
      - src/**/*.ts
    # named_maps:               # Optional: multiple maps with custom names
    #   - name: my-project
    #     globs: ["src/**/*.ts"]
    # model: flash-low          # Optional: model used for summarization
    # input_concurrency: 8      # Optional: concurrency for map building
```

- `name`: Set to `pro@coder/code-map`.
- `enabled`: Toggles the sub-agent execution.
- `globs`: Array of glob patterns (relative to the workspace) for files to be summarized in the default `code-map.json`.
- `named_maps`: Array of named map definitions (`name` and `globs`). Each named map will generate its own `[name]-code-map.json`.
- `model`: (Optional) The AI model used to generate the summaries and metadata for each file.
- `input_concurrency`: (Optional) The number of concurrent tasks used to generate or update file summaries.

## AI Response Utility Tags

The `pro@coder` output parser also supports a few utility tags in the AI response body. These are useful for surfacing helper actions in the terminal UI without mixing them into file change directives.

### `AIP_TO_PIN`

Use the upper-case `<AIP_TO_PIN>` tag to pin custom content in the current task UI.

Supported attributes:

- `label`, optional string
- `priority`, optional integer encoded as a string, for example `"3"` or `"-4"`

Behavior:

- If the tag body is empty or trims to empty, nothing is pinned.
- `priority` falls back to `1` when missing or when it is not an integer.
- `label` may be omitted, in which case it is passed as `nil`.

Example:

```xml
<AIP_TO_PIN label="Next Step" priority="3">
Review the generated patch and run the targeted tests.
</AIP_TO_PIN>
```

This results in a task pin equivalent to:

```lua
aip.task.pin(label, priority, {
	label   = label,
	content = body
})
```

## AIPack config override

As mentioned above, the `pro@coder` parametric prompt `coder-prompt.md` allows you to override the AI Pack workspace and base configurations.

The properties `aliases`, `model`, `input_concurrency`, and `temperature` will be merged, overriding parameters from the following configuration files, in order of precedence:
- the `model_aliases` defined in the prompt
- `.aipack/config.toml` (workspace file)
- `~/.aipack-base/config-user.toml` (edit to customize global settings)
- `~/.aipack-base/config-default.toml` (do not edit)

Note that only these four are AI Pack config properties and can be set in the config TOML files. Other `pro@coder`-only properties, such as `knowledge_globs` and `write_mode`, are not AI Pack properties and therefore should not be set in the AI Pack config TOML files.

## Plan-Based Development

`pro@coder` facilitates **Plan-Based Development** by initializing relevant plan files within the prompt's workbench folder.

- The foundational rules are in `_plan-rules.md`, located in the `workbench-default/` folder beside your `coder-prompt.md`. The plan flow uses `plan-1-todo-steps.md`, `plan-2-active-step.md`, and `plan-3-done-steps.md` in the same directory.
- By default, setting `dev: { plan: true }` in your meta block automatically initializes these files and includes them in the prompt context.
- To manually include them or use a custom folder, you can use `context_globs_post`:
  - `.aipack/.prompt/pro@coder/workbench-default/plan-*.md`
- When instructing the agent, refer to the plan rules. For example:
  - `Following the plan rules, create a plan to do the following: ....`
  - Or, to execute a step:
    - `Following the plan rules, execute the next step in the plan and update the appropriate files.`

To disable Plan-Based Development, remove the `...plan/*.md` glob pattern from your `context_globs`.

## Post-stage sub-agent example

You can configure a sub-agent to run after the main coder execution by enabling `stage_post`.

```yaml
sub_agents:
  - name: my-post-agent
    on: end
```

This sub-agent will run once globally in `# After All` and receive:

- the final effective `coder_params`
- the final effective `coder_prompt`
- the resolved request file refs
- ordered `coder_responses` with:
  - `content_extruded`
  - `file_changes_status`
  - `content_raw_path`

If a `post` sub-agent fails, the run fails, but already-applied file changes are not rolled back.

You can also configure a sub-agent to run on both stages:

```yaml
sub_agents:
  - name: my-agent
    on: ["start", "end"]
```

The `post` input shape is:

```ts
type SubAgentPostInput = {
  event: string,
  stage: "post",
  coder_prompt_dir: string,
  coder_params: table,
  coder_context_file_refs: table | nil,
  coder_knowledge_file_refs: table | nil,
  coder_working_file_refs: table | nil,
  coder_prompt: string,
  agent_config: AgentConfig,
  sub_agents_prev?: SubAgentHistoryItem[],
  sub_agents_next?: AgentConfig[],
  coder_responses: CoderAgentResponse[],
}
```

Interpretation notes:

- `coder_params` reflects the final effective coder params after `pre` stage processing.
- `coder_prompt` reflects the final effective instruction after `pre` stage processing.
- `coder_context_file_refs`, `coder_knowledge_file_refs`, and `coder_working_file_refs` are the resolved file refs actually used by the main run.
- `coder_responses` contains one item per output task, in output order.
- `coder_responses[*].content_extruded` is the AI response body with file change directives removed by the output layer.
- `coder_responses[*].file_changes_status` is the final file change apply result exposed by the output layer.
- `coder_responses[*].content_raw_path` points to the saved raw AI response file for that task.

The `post` output contract is:

```ts
type SubAgentPostOutput = {
  agent_result?: any,
  sub_agents_next?: AgentConfig[],
  emit_events?: string[],
  success?: boolean,
  error_msg?: string,
  error_details?: string,
}
```

Post-stage output behavior:

- `success`, `error_msg`, and `error_details` are honored.
- `agent_result` is preserved for downstream `post` pipeline context.
- `sub_agents_next` may replace the remaining `post` pipeline tail.
- `emit_events` appends follow-up post-stage events to the queue in order.
- `coder_params` and `coder_prompt` are not part of the documented post-stage output contract.

## Spec-Based Development

`pro@coder` also supports **Spec-Based Development** through the `dev.spec` capability.

- The foundational rules live in `_spec-rules.md`, located in the `workbench-default/` folder beside your `coder-prompt.md`.
- The main working spec file is `spec.md`, stored beside `_spec-rules.md` by default.
- When `dev.spec` is enabled, `pro@coder/dev` ensures both files exist.
- The rules file is added to `knowledge_globs_post`, and the `spec.md` file is added to `context_globs_post`.
- This lets you keep specification guidance in knowledge, while the evolving project spec stays in context.

Typical setup:

```yaml
dev:
  spec: true
```

Or with an explicit path:

```yaml
dev:
  spec: .aipack/.prompt/pro@coder/workbench-default/spec.md
```

You can then prompt the agent with requests such as:

- `Following the spec rules, create or update the project spec for ...`
- `Following the spec and the current plan, implement the next step`

