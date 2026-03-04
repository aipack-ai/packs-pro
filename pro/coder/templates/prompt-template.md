```yaml
#!meta (parametric prompt)

# See PATH_TO_PRO_CODER_README for additional documentation
# Other possible parameters: sub_agents, base_dir, working_globs, max_files_size_kb, ...
# Note: All relative paths are relative to the workspace directory (that is, the parent folder of .aipack/)

## Static knowledge (relative & absolute)
knowledge_globs:
  # - /abs/or/rel/path/to/**/*.md      # Any relative or absolute path/glob for Markdown files
  # - pro@coder/README.md              # Pack path supported (here ask question about pro@coder)
  # - core@doc/**/*.md                 # For help building .aip AIPack agents
  # - pro@rust10x/guide/base/**/*.md   # Examples of best practices for Rust coding (require `aip install pro@rust10x`)

## Pinned knowledge globs (always included, not removed by auto_context)
# knowledge_globs_pre:       # Prepended before auto-context selection
#   - core@doc/**/*.md
# knowledge_globs_post:      # Appended after auto-context selection
#   - path/to/best-practices/**/*.md

## File path & content included in prompt (relative only)
context_globs:
  # - package.json  # for Node.js
  # - Cargo.toml    # for Rust
  # - README.md 
  - src/**/*.*      # Narrow the scope or enable auto_context
  ## dev-chat (uncomment for dev chat mode)
  # - .aipack/.prompt/pro@coder/dev/chat/dev-chat.md

## Pinned context globs (always included, not removed by auto_context)
# context_globs_pre:         # Prepended before auto-context selection
#   - package.json
# context_globs_post:        # Appended after auto-context selection
#   - .aipack/.prompt/pro@coder/dev/plan/*.md

## Only matched file paths included in prompt (relative only)
structure_globs:
  - src/**/*.*
  
## Set to true to write the files
write_mode: false

## Full model names or aliases (any model name for available API Keys) (see aliases ~/.aipack-base/config-default.toml)
## Customize reasoning effort with -high, -medium, or -low suffixes (e.g., "flash-low", "opus-high", "gpro-low")
model: flash

## Optimize context files selection (other properties: code_map_model, helper_globs, knowledge: true/false)
auto_context: 
  model: flash           # (Use a small or inexpensive model)
  input_concurrency: 16  # (default 8)
  enabled: false         # (Default true) Comment or set to true to enable.

## (see PATH_TO_PRO_CODER_README for full pro@coder documentation)
```



====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`
