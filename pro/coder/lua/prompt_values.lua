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
#   - src/**/*.js
# working_concurrency: true
# input_concurrency: 6

# Note: This will add/override the model_aliases defined in .aipack/config.toml and ~/.aipack-base/config.toml
model_aliases:
  gpro: gemini-2.5-pro
  gpro-high: gemini-2.5-pro-high
  gpro-low: gemini-2.5-pro-low
  flash: gemini-2.5-flash
  flash-zero: gemini-2.5-flash-zero
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
> Write your prompt above the `====` sign and below the parametric block (the YAML code block).
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.
> You can ask pro@coder to give you some documentaiton by asking `Show Doc` and pres `r`
]]

return {
  prompt_template       = prompt_template,
  default_context_globs = default_context_globs
}
