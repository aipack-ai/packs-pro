```yaml
#!meta (parametric prompt)

# See README.md for more documentation

## (relative to workspace dir, i.e. .aipack/ parent dir)
knowledge_globs:
# - /rel/or/abs/path/to/**/*.md      
# - pro@coder/README.md
# - core@doc/**/*.md

## (relative to workspace dir)
base_dir: "" 

## File path & content included in prompt
## (relative to base_dir)
context_globs:
# - package.json    # e.g., for Node.js
# - Cargo.toml      # e.g., for Rust
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

# model_aliases:
#   gpro: gemini-2.5-pro # example

## Set to true to write the files
write_mode: false

model: gpt-5-mini # set it to "gpt-5" for normal coding

## See README.md for more info
```

====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`  