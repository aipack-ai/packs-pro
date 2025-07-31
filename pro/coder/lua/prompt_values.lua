local default_context_globs = nil

-- If we wanted to have most languages as default (but it can be unclear to the user)
-- {
--     "**/*.lua", "**/*.md", 
--     "**/*.rs", "**/*.cpp", "**/*.c", 
--     "**/*.java", "**/*.go", "**/*.swift", "**/*.kt", 
--     "**/*.html", "**/*.js", "**/*.ts", "**/*.tsx", "**/*.css", "**/*.pcss", "**/*.scss"
-- }

local prompt_template = [[
```yaml
#!meta (parametric prompt)

# Add absolute, relative, ~/, or some@pack knowledge globs. They will be included in the prompt as knowledge files.
# knowledge_globs:
#   - path/to/knowledge/**/*.md         # Your own best practices
#   - core@doc/**/*.md                  # To help code .aip aipack agents
#   - pro@rust10x/guide/base/**/*.md    # Some rust best practices

# If not set, context_globs and working_globs won't be evaluated
base_dir: "" # Leave empty for workspace root; make sure to narrow context_globs

# Files that will be included in your prompt as context files. 
# Relative to base_dir, try to be as narrow as possible for large code base
context_globs:
  - src/**/*.*
# - package.json    # e.g., for nodejs
# - Cargo.toml      # e.g., for rust

# Relative to base_dir. Only include paths (not content) in the prompt.
# (Good way to give the AI some good and cheap context about the overall sturucture of the project)
structure_globs:
  - src/**/*.*

# Relative to base_dir. (optional) Files you actually want to work on, especially usefull for concurrency
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

# Typically, leave this commented for "search_replace_auto" which is the most efficient
# file_content_mode: whole # default "search_replace_auto"

# Set to true to write the files (otherwise, will show below the `====` )
write_mode: false

# It can be an alias name above, or model names like "o4-mini", "o4-mini-high".
# If not set, the model defined in config.toml will be used.
model: gpt

# To see docs, type "Show Doc" and then press `r` in the aip terminal
```

====
> Ask your coding questions above the `====` delimiter, and press `r` in the terminal to replay.
>
> `coder` Agent parameters supported for this `coder` agent:
>
> `knowledge_globs`     - Allows you to add knowledge files to the context. These can be absolute or even refer to other packs,
>                         e.g., `["my-coding-guideline/**/*.md", "pro@rust10x/common/**/*.md"]`
>
> `base_dir`            - If activated in the TOML parameter section above, the context_globs and working_globs will be enabled.
>
> `context_globs`       - Customize your context globs relative to `base_dir` to decide which files are added to the context.
>                         If not defined, then no context files will be included in the prompt.
>                         These files will be described to the AI as `User's context files`.
>                         Narrowing the scope is better (both cost- and quality-wise, as it allows the model to focus on what matters).
>
> `working_globs`       - Customize your working globs to represent the working files. 
>                         When this is set, this allows the context_globs files to be explicitly cached (with Claude)
>                         and gives another opportunity to focus the AI on these files and treat the context_globs as just context.
>
> `structure_globs`     - Relative to base_dir. Only include paths (not content) in the prompt.
>                         This is very useful to give the AI the overall project shape, without using too much prompt context. 
>
> `working_concurrency` - When set to `true` and `working_globs` is defined, this will work on each working file concurrently,
>                         following the `input_concurrency` set in this section or in the workspace or aipack-base config.toml.
>
> `model_aliases`       - You can create your own alias names (which will override those defined in `.aipack/config.toml`).
>                         Top coder: "o3-mini-high" (aliased as 'high'), Fastest/~Cheapest: "gemini-2.0-flash-001".
>
> `model`               - Provide a direct model name or a model alias to specify which model this coder agent should use.
>
> Lines starting with `>` above the `====` or in the first lines just below the `====` will be ignored in the AI conversation.
> Here, give your instructions, questions, and more. By default, the code will be below.
>
> Feel free to remove these `> ` lines, as they are just for initial documentation and have no impact on AI instructions.
>
> You can ask, "Can you explain the coder agent parameters?" to get some documentation about them.
>
> Happy coding!
]]

return {
  prompt_template       = prompt_template,
  default_context_globs = default_context_globs
}