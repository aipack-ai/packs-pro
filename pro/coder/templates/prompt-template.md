```yaml
#!meta (parametric prompt)

# See PATH_TO_PRO_CODER_DIR/README.md for additional documentation
# Note: All relative paths are relative to the workspace directory (parent folder of .aipack/)

## Static knowledge (relative & absolute)
knowledge_globs:
  # - /abs/or/rel/path/to/**/*.md      # Relative or absolute path/glob for Markdown files
  # - pro@rust10x/guide/base/**/*.md   # Rust best practices (requires `aip install pro@rust10x`)
  # - pro@coder/README.md              # Pack path supported (ask question about pro@coder)
  # - core@doc/for-llm/**/*.md         # For help building .aip AIPack agents

## Files the AI will work on (paths & content included in prompt, relative only)
context_globs:
  - "*.*"
  - src/**/*.*      

## Set to false to disable file writing (response below this file's prompt)
write_mode: true

## Optimize context files selection (other properties: code_map_model, helper_globs, ..)
auto_context: 
  model: flash           # (Use a small or inexpensive model)
  input_concurrency: 16  # (default 8)
  enabled: false         # (Default true) Comment or set to true to enable.

# Default dir: PATH_TO_PRO_CODER_DIR/workbench-default 
workbench:
  # dir:  PATH_TO_PRO_CODER_DIR/workbench-default
  # chat: true
  # spec: true
  # plan: true

## Full model names or aliases (see aliases ~/.aipack-base/config-default.toml)
## -high, -medium, or -low suffixes for reasoning (e.g., "flash-low", "opus-max", "gpt-high")
model: flash

## (see PATH_TO_PRO_CODER_DIR/README.md for full pro@coder documentation)
```



====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`
