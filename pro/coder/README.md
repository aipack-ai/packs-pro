# pro@coder documentation

[Coder Parameters](#coder-parameters) | [Workflow](#setup--workflow) | [Coder Intro](#coder-promptmd) | [Config Override](#aipack-config-override) | [Plan Development](#plan-based-development)

This is the documentation and usage guide for the `pro@coder` AI Pack.

The `pro@coder` pack provides AI-powered coding assistance through parametric prompts that allow you to configure context, working files, and AI model settings for your coding tasks.

The key concept of `pro@coder` is to give you full control over the AI context, enabling you to guide the AI to code the way you want, rather than adapting to the AI's default approach. This is done in part by splitting files into `knowledge`, `context`, and `working` (for concurrency) categories.

[Workflow](#setup--workflow) | [Coder Intro](#coder-promptmd) | [Coder Parameters](#parametric-block-format) | [AIPack config override](#aipack-config-override)
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

## Add absolute, relative, ~/, or some@pack knowledge globs.
## They will be included in the prompt as knowledge files.
## (relative to workspace dir, i.e. .aipack/ parent dir)
knowledge_globs:
# - path/to/knowledge/**/*.md         # Your own best practices
# - core@doc/**/*.md                  # To help code .aip aipack agents
# - pro@rust10x/guide/base/**/*.md    # Some Rust best practices

# If not set, context_globs and working_globs won't be evaluated
## (relative to workspace dir)
base_dir: "" # Leave empty for workspace root; make sure to refine context_globs

## Files that will be included in your prompt as context files.
## Relative to base_dir, try to keep them as narrow as possible for a large codebase
## The manifest file like package.json or Cargo.toml are good context for the AI at relatively low context cost/size
## (relative to base_dir)
context_globs:
# - package.json    # e.g., for Node.js
# - Cargo.toml      # e.g., for Rust
  - src/**/*.*      # Narrow glob when more than 10 files

## Relative to base_dir. Only include paths (not content) in the prompt.
## (A good way to give the AI a cheap overview of the overall structure of the project)
## (relative to base_dir)
structure_globs:
  - src/**/*.*

## Working Globs - Advanced - Create a task per file or file group.
## NOTE - Only enable when working on multiple files at same time
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

## Typically, leave this commented for "search_replace_auto", which is the most efficient
## NOTE: Now new 'udiffx' avaiable in AIPack >= 0.8.12 which will eventually become the default
file_content_mode: udiffx # default "search_replace_auto" ("whole" for the whole file rewrite even when patch)

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
# auto_context: flash # or { model: flash, enabled: true }

## Specialized agents to pre-process parameters and instructions (Stage: "pre")
sub_agents:
  - my-agents/prompt-cleaner.aip # simple .aip file (see sub_agent section for input / output)
  - name: pro@coder/code-map     # code-map sub agent is also use in auto-context (but here is a custom example)
    enabled: true # default run
    map_name: external-lib-docs # will create .aipack/.prompt/pro@coder/.cache/code-map/external-lib-docs-code-map.json
    globs: 
      - doc/external-libs/**/*.md


## To see docs, type "Show Doc" and then press `r` in the aip terminal
```

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
  - pro@coder/README.md                 # This is this README.md from the pro@coder, 
                                        # can be used to ask question about pro dcoe
  - core@doc/**/*.md                    # core@doc is a built-in pack with the AI Pack doc
  - pro@rust10x/guide/base/**/*.md      # aip install pro@rust10x, and then this will be aiable
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

#### base_dir

Base directory for resolving `context_globs`, `working_globs`, and `structure_globs`. Leave empty for workspace root. When not set or empty, the glob parameters won't be evaluated.

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

- `search_replace_auto` (default): Most efficient, uses SEARCH/REPLACE blocks for updates
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

Shortcut to configure and run the `pro@coder/auto-context` sub-agent. It is a concise alternative to defining it in the `sub_agents` list and supports the same properties.

Can be:
- **A string**: The model name to use (e.g., `auto_context: flash`).
- **A table**: Configuration for the auto-context agent.

Example:

```yaml
auto_context:
  model: flash                # The model used to analyze the instruction and code map
  enabled: true               # Whether to run the auto-context agent (default true)
  mode: reduce                # "reduce" (replaces) or "expand" (adds to existing) (default "reduce")
  # input_concurrency: 8      # code map building concurrency (default 8)
  # code_map_model: flash-low # code map model (optional, default auto-context model above)
  # map_name: context         # custom name for the code-map cache (default "context")
  helper_globs:               # Files to help select relevant context files
    - .aipack/.prompt/pro@coder/dev/plan/*.md
```

#### sub_agents

Array of specialized agents to run at different stages of the `pro@coder` execution. Sub-agents allow for a pipeline where multiple agents can modify the state of the current request, which is useful for automated context building, instruction refinement, or project-specific initialization.

Currently, sub-agents run at the `pre` stage, which occurs during initialization (Before All).

Sub-agents can be defined as:

- **A string**: The name or path of the agent (e.g., `"my-agent"` or `"ns@pack/agent"`).
- **A table**: An object providing more control.

Available properties for the table definition:

- `name` (string): The name or path of the agent.
- `enabled` (boolean, optional, default `true`): Whether to run this sub-agent.
- `options` (table): Agent options (like `model`,`input_concurrency`) specifically for this sub-agent run.
- **Additional properties**: Any other keys provided in the table will be passed to the sub-agent via the `agent_config` field in its input.

### Developing Sub-agents

Sub-agents are standard `.aip` files. They receive the following structure as their `input` (accessible in `# Data` or `# Output` stages):

```ts
type SubAgentInput = {
  coder_stage: "pre",      // Current execution stage
  coder_prompt_dir: string,// Absolute path to the prompt file directory
  coder_params: table,     // Current parameters (from YAML block or previous sub-agents)
  coder_prompt: string,    // Current instruction text
  agent_config: table,     // The configuration object defined in the sub_agents list
}
```

To modify the request state, the sub-agent should return a table. If the return value is `nil`, it is interpreted as success with no modifications.

```ts
type SubAgentOutput = {
  coder_params?: table,    // Optional: Merged into the current parameters
  coder_prompt?: string,   // Optional: Replaces the current instruction

  success?: boolean,       // Optional (defaults to true). Set to false to fail.
  error_msg?: string,      // Optional. If present, the run fails with this message.
  error_details?: string,  // Optional. More context for the failure.
}
```

**Important notes on return values**:

- `coder_params`: If provided, this table is shallow-merged into the current parameters. This means you only need to return the keys you wish to add or change.
- `coder_prompt`: If provided, this string replaces the current instruction for the remainder of the pipeline.
- Errors: If `success` is `false` or `error_msg` is present, the entire `pro@coder` run will halt with the provided error.

A sub-agent can return this data either from:

- The `# Output` stage (as the return value for the task).
- The `# After All` stage (as the final return value).

Sub-agents require AIPack 0.8.15 or above.

## Builtin Sub Agents

### Sub Agent - pro@coder/auto-context

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
    model: flash                # small/cheap model to optimize which file 
    # input_concurrency: 32     # code map concurrency (for building the code-map.json) (default 8)
    # code_map_model: flash-low # code map model (optional, default auto-context model above)
    # map_name: context         # custom name for the code-map cache (default "context")
    helper_globs:               # Other files sent to give more information to select the property context file
      # - .aipack/.prompt/pro@coder/dev/chat/dev-chat.md
```

- `name`: Set to `pro@coder/auto-context`. This agent automatically identifies relevant files for your prompt by comparing your instruction against a "code map" (summaries of your files).
- `enabled`: Toggles the sub-agent execution.
- `model`: The model used to analyze your instruction and the code map summaries to perform the file selection.
- `input_concurrency`: (Optional) The number of concurrent tasks used when generating or updating file summaries for the code map.
- `code_map_model`: (Optional) The model used to generate file summaries. Defaults to the `model` specified above if not provided.
- `helper_globs`: (Optional) Pattern for files (like development plans or chat logs) that provide additional guidance to help the sub-agent select the correct context files.

### Sub Agent - pro@coder/code-map

The code-map agent generates and maintains a JSON file containing summaries, public types, and functions for a set of files. This map is used by the `auto-context` agent to identify relevant files for your prompt, but it can also be used independently to create maps for external libraries or documentation.

**Using the `sub_agents` list:**

```yaml
sub_agents: 
  - name: pro@coder/code-map
    enabled: true
    globs: 
      - src/**/*.ts
    # map_name: my-project      # Optional: custom name for the JSON file
    # model: flash-low          # Optional: model used for summarization
    # input_concurrency: 8      # Optional: concurrency for map building
```

- `name`: Set to `pro@coder/code-map`.
- `enabled`: Toggles the sub-agent execution.
- `globs`: Array of glob patterns (relative to the workspace) for files to be summarized in the map.
- `map_name`: (Optional) Custom name for the generated JSON file. By default, it uses `code-map.json` in the `.cache/code-map/` directory.
- `model`: (Optional) The AI model used to generate the summaries and metadata for each file.
- `input_concurrency`: (Optional) The number of concurrent tasks used when generating or updating file summaries.

## AIPack config override

As mentioned above, the `pro@coder` parametric prompt `coder-prompt.md` allows you to override the AI Pack workspace and base configurations. 

The properties `aliases`, `model`, `input_concurrency`, and `temperature` will be merged, overriding parameters from the following configuration files, in order of precedence: 
    - the `model_aliases` defined in the prompt
    - `.aipack/config.toml` (workspace file)
    - `~/.aipack-base/config-user.toml` (edit to customize global settings)
    - `~/.aipack-base/config-default.toml` (do not edit)

Note that only these four are AI Pack config properties and can be set in the config TOML files. Other `pro@coder`-only properties, such as `knowledge_globs` and `write_mode`, are not AI Pack properties and therefore should not be set in the AI Pack config TOML files.     


## Plan-Based Development

`pro@coder` facilitates **Plan-Based Development** by initializing relevant plan files within the prompt's dedicated folder.

- The foundational rules are in `_plan-rules.md`, located in the prompt's `dev/plan/` subfolder (e.g., `.aipack/.prompt/pro@coder/dev/plan/_plan-rules.md`). This folder also contains `plan-todo.md` and `plan-done.md`.
- To enable plan-based interactions, add these files to your `context_globs` parameter, for example:
    - `  - .aipack/.prompt/pro@coder/dev/plan/*.md`
- When instructing the agent, refer to the plan rules. For example:
    - `Following the plan rules, create a plan to do the following: ....`
    - Or, to execute a step:
        - `Following the plan rules, execute the next step in the plan and update the appropriate files.`

To disable Plan-Based Development, remove the `...plan/*.md` glob pattern from your `context_globs`.
