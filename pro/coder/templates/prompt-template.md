```yaml
#!meta (parametric prompt)

# See PATH_TO_PRO_CODER_DIR/README.md for additional documentation
# Other possible parameters: sub_agents, base_dir, working_globs, max_files_size_kb, ...
# Note: All relative paths are relative to the workspace directory (that is, the parent folder of .aipack/)

## Static knowledge (relative & absolute)
knowledge_globs:
  # - /abs/or/rel/path/to/**/*.md      # Any relative or absolute path/glob for Markdown files
  # - pro@coder/README.md              # Pack path supported (here ask question about pro@coder)
  # - core@doc/**/*.md                 # For help building .aip AIPack agents
  # - pro@rust10x/guide/base/**/*.md   # Examples of best practices for Rust coding (require `aip install pro@rust10x`)

## Files the AI will work on (paths & content included in prompt, relative only)
context_globs:
  # - package.json  # for Node.js
  # - Cargo.toml    # for Rust
  # - README.md 
  - src/**/*.*      

## File paths to give AI a broader view of the project (paths only in prompt, relative only)
structure_globs:
  - src/**/*.*      
  
## Set to true to write the files
write_mode: false

## Optimize context files selection (other properties: code_map_model, helper_globs, knowledge: true/false)
auto_context: 
  model: flash           # (Use a small or inexpensive model)
  input_concurrency: 16  # (default 8)
  enabled: false         # (Default true) Comment or set to true to enable.

dev:
  chat: false   # default path: PATH_TO_PRO_CODER_DIR/dev/chat/dev-chat.md 
  plan: false   # default  dir: PATH_TO_PRO_CODER_DIR/dev/plan/

## Full model names or aliases (see aliases ~/.aipack-base/config-default.toml)
## -high, -medium, or -low suffixes to customize reasoning effor (e.g., "flash-low", "opus-high", "codex-high")
model: flash

## (see PATH_TO_PRO_CODER_DIR/README.md for full pro@coder documentation)
```



====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`
