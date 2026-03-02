```yaml
#!meta (parametric prompt)

# See PATH_TO_PRO_CODER_README for more documentation
# (for base_dir, working_globs, max_files_size_kb, cache_explicit, model_aliases, file_content_mode)

# By default, all paths are relative to base_dir (by default ""), which is based on workspace directory by default (parent of .aipack/).

## Static knowledge
knowledge_globs:
  # - /abs/or/rel/path/to/**/*.md      # Any relative or absolute path/glob for Markdown files
  # - pro@coder/README.md              # Pack path supported (here ask question about pro@coder)
  # - core@doc/**/*.md                 # For help building .aip AIPack agents
  # - pro@rust10x/guide/base/**/*.md   # Examples of best practices for Rust coding (require `aip install pro@rust10x`)

## File path & content included in prompt
## (relative to base_dir)
context_globs:
  # - package.json  # e.g., for Node.js
  # - Cargo.toml    # e.g., for Rust
  # - README.md 
  - src/**/*.*      # Narrow the scope or enable auto_context
  ## dev-chat (uncomment for dev chat mode)
  # - .aipack/.prompt/pro@coder/dev/chat/dev-chat.md

## Only matched file paths included in prompt
## (relative to base_dir)
structure_globs:
  - src/**/*.*
  
## Set to true to write the files
write_mode: false

## Full model names (any model name for available API Keys) 
## or aliases "opus" (Opus 4.5), "flash" (Gemini flash 3) (see aliases ~/.aipack-base/config-default.toml)
## Customize reasoning effort with -high, -medium, or -low suffix (e.g., "opus-high", "gpro-low")
model: flash

## Optimize context files selection
auto_context: 
  model: flash           # (Use a small or inexpensive model, can also define code_map_model)
  input_concurrency: 16  # default 8
  enabled: false         # (Default is true). Comment or set to true to enable.

## (see PATH_TO_PRO_CODER_README for full pro@coder documentation)
```



====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`
