```yaml
#!meta (parametric prompt)

# See PATH_TO_PRO_CODER_README for more documentation
# (for base_dir, working_globs, max_files_size_kb, cache_explicit, model_aliases, file_content_mode)

# By default, all path relative to base_dir, which is by default workspace dir (.aipack/ parent dir)

## Static knowledge
knowledge_globs:
  # - /rel/or/abs/path/to/**/*.md      # Any relatively or absolute path/globs to markdown
  # - pro@coder/README.md              # To ask question about this pro@coder AIPack
  # - core@doc/**/*.md                 # To help build .aip AIPack agents
  # - pro@rust10x/guide/base/**/*.md   # Example of best practices about Rust coding

## File path & content included in prompt
## (relative to base_dir)
context_globs:
  # - package.json  # e.g., for Node.js
  # - Cargo.toml    # e.g., for Rust
  # - README.md 
  - src/**/*.*      # narrow or enable auto_context
  ## dev-chat (uncomment when dev chat mode)
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
  model: flash   # (use small / cheap model)
  enabled: false # (default true) set to true or uncomment to enable

## (see PATH_TO_PRO_CODER_README for full pro@coder documentation)
```

====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`
