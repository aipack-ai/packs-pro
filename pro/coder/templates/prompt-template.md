```yaml
#!meta (parametric prompt)

# See README.md for more documentation

## (relative to workspace dir, i.e. .aipack/ parent dir)
knowledge_globs:
  # - /rel/or/abs/path/to/**/*.md      # Any relatively or absolute path/globs to markdown
  # - pro@coder/README.md              # To ask question about this pro@coder AIPack
  # - core@doc/**/*.md                 # To help build .aip AIPack agents
  # - pro@rust10x/guide/base/**/*.md   # Example of best practices about Rust coding

## (relative to workspace dir)
base_dir: "" 

## File path & content included in prompt
## (relative to base_dir)
context_globs:
  # - package.json  # e.g., for Node.js
  # - Cargo.toml    # e.g., for Rust
  # - README.md 
  - src/**/*.*      # Narrow glob when more than 10 files

## Only matched file paths included in prompt
## (relative to base_dir)
structure_globs:
  - src/**/*.*

## Working Globs - Create a task per file or file group.
## (relative to base_dir)
# working_globs:
#   - src/**/*.js
#   - ["css/*.css"]
# input_concurrency: 2

# max_files_size_kb: 1000
# cache_explicit: false  # (default false) Explicit cache for pro@coder prompt and knowledge files (Anthropic only)

# model_aliases:
#   my-model: gemini-pro-latest # example of any alias (see ~/.aipack-base/config-default.toml)

## Set to true to write the files
write_mode: false

## "udiffx" Experimental for now, will probably become the default.
# file_content_mode: udiffx 

# Full model names (any model name for available API Keys) 
# or aliases "opus" (Opus 4.5), "flash" (Gemini flash 3) (see aliases ~/.aipack-base/config-default.toml)
# Customize reasoning effort with -high, -medium, or -low suffix (e.g., "opus-high", "gpro-low")
model: flash

## See README.md for more info
```

====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`
