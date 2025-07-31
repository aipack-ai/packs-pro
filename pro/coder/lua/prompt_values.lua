local default_context_globs = nil


local prompt_template = [[
```yaml
#!meta (parametric prompt)

# Add absolute, relative, ~/, or some@pack knowledge globs. They will be included in the prompt as knowledge files.
# knowledge_globs:
#   - path/to/knowledge/**/*.md         # Your own best practices
#   - core@doc/**/*.md                  # To help code .aip aipack agents
#   - pro@rust10x/guide/base/**/*.md    # Some Rust best practices

# If not set, context_globs and working_globs won't be evaluated
base_dir: "" # Leave empty for workspace root; make sure to refine context_globs

# Files that will be included in your prompt as context files.
# Relative to base_dir, try to keep them as narrow as possible for a large codebase
context_globs:
  - src/**/*.*
# - package.json    # e.g., for Node.js
# - Cargo.toml      # e.g., for Rust

# Relative to base_dir. Only include paths (not content) in the prompt.
# (A good way to give the AI a cheap overview of the overall structure of the project)
structure_globs:
  - src/**/*.*

# Relative to base_dir. (optional) Files you actually want to work on, especially useful for concurrency
# working_globs:
#   - **/*.js
# working_concurrency: true
# input_concurrency: 6

# Note: This will add/override the model_aliases defined in .aipack/config.toml and ~/.aipack-base/config.toml
model_aliases:
  gpro: gemini-2.5-pro
  gpro: gemini-2.5-pro-low
  flash: gemini-2.5-flash
  lite: gemini-2.5-flash-lite-preview-06-17
  claude: claude-sonnet-4-20250514
  gpt: gpt-4.1
  mini: gpt-4.1-mini

# Typically, leave this commented for "search_replace_auto", which is the most efficient
# file_content_mode: whole # default "search_replace_auto"

# Set to true to write the files (otherwise, they will be shown below the `====` separator)
write_mode: false

# It can be an alias name above, or model names like "o4-mini", "o4-mini-high".
# If not set, the model defined in config.toml will be used.
model: gpt

# To see docs, type "Show Doc" and then press `r` in the aip terminal
```

====
> Ask your coding questions above the `====` delimiter and press `r` in the terminal to replay.
>
> `coder` Agent parameters supported for this `coder` agent:
>
> `knowledge_globs`     - Allows you to add knowledge files to the context. These can be absolute or even refer to other packs,
>                         e.g. `["my-coding-guideline/**/*.md", "pro@rust10x/common/**/*.md"]`
>
> `base_dir`            - If activated in the TOML parameter section above, the context_globs and working_globs will be enabled.
>
> `context_globs`       - Customise your context globs relative to `base_dir` to decide which files are added to the context.
>                         If not defined, no context files will be included in the prompt.
>                         These files will be described to the AI as `User's context files`.
>                         Narrowing the scope is better (both cost- and quality-wise, as it allows the model to focus on what matters).
>
> `working_globs`       - Customise your working globs to represent the working files.
>                         When this is set, it allows the context_globs files to be explicitly cached (with Claude)
>                         and gives another opportunity to focus the AI on these files and treat the context_globs as just context.
>
> `structure_globs`     - Relative to base_dir. Only include paths (not content) in the prompt.
>                         This is very useful to give the AI the overall project shape without using too much prompt context.
>
> `working_concurrency` - When set to `true` and `working_globs` is defined, this will work on each working file concurrently,
>                         following the `input_concurrency` value set in this section or in the workspace or aipack-base config.toml.
>
> `model_aliases`       - You can create your own alias names (which will override those defined in `.aipack/config.toml`).
>                         Examples: "gpro" (maps to `gemini-2.5-pro`), "flash" (maps to `gemini-2.5-flash`).
>
> `model`               - Provide a direct model name or a model alias to specify which model this coder agent should use.
>
> Lines starting with `>` above the `====` or in the first lines just below the `====` will be ignored in the AI conversation.
> Here, give your instructions, questions, and more. By default, the code will be below.
>
> Feel free to remove these `> ` lines, as they are only for initial documentation and have no impact on AI instructions.
>
> You can ask, "Can you explain the coder agent parameters?" to get documentation about them.
>
> Happy coding!
]]

return {
  prompt_template       = prompt_template,
  default_context_globs = default_context_globs
}
