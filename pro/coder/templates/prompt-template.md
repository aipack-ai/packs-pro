```yaml
#!meta (parametric prompt)

## Add absolute, relative, ~/, or some@pack knowledge globs.
## They will be included in the prompt as knowledge files.
knowledge_globs:
# - path/to/knowledge/**/*.md         # Your own best practices
# - core@doc/**/*.md                  # To help code .aip aipack agents
# - pro@rust10x/guide/base/**/*.md    # Some Rust best practices

# If not set, context_globs and working_globs won't be evaluated
base_dir: "" # Leave empty for workspace root; make sure to refine context_globs

## Files that will be included in your prompt as context files.
## Relative to base_dir, try to keep them as narrow as possible for a large codebase
## The manifest file like package.json or Cargo.toml are good context for the AI at relatively low context cost/size
context_globs:
# - package.json    # e.g., for Node.js
# - Cargo.toml      # e.g., for Rust
  - src/**/*.*      # Narrow glob when more than 10 files

## Relative to base_dir. Only include paths (not content) in the prompt.
## (A good way to give the AI a cheap overview of the overall structure of the project)
structure_globs:
  - src/**/*.*

## Working Globs - Create a task per file or file group.
# working_globs:
#   - src/**/*.js        # This will do one working group per matched .js
#   - ["css/*.css"]      # When in a sub array, this will put all of the css in the same working group
# input_concurrency: 2   # Number of concurrent tasks (default set in the config TOML files)

## Max size in KB of all included file (safeguard, default 5000, for 5MB)
# max_files_size_kb: 5000

## Note: This will add or override the model_aliases defined in
##       .aipack/config.toml, ~/.aipack-base/config-user.toml, ~/.aipack-base/config-default.toml
# model_aliases:
#   gpro: gemini-2.5-pro # example

## Typically, leave this commented for "search_replace_auto", which is the most efficient
## file_content_mode: whole # default "search_replace_auto"
#
## Set to true to write the files (otherwise, they will be shown below the `====` separator)
write_mode: false

## MODEL: Here you can use any full model name or model aliases defined above and in the config.toml
## such as ~/.aipack-base/config-default.toml
## For OpenAI and Gemini model, can use -low, -medium, -high suffix for reasoning control

model: gpt-5-mini # set it to "gpt-5" for normal coding

## To see docs, type "Show Doc" and then press `r` in the aip terminal
```

====
> Write your prompt above the `====` line and below the parametric block (the YAML code block).  
> Press `r` in the terminal to replay this run; the AI response will appear below the `====`.  
> When `write_mode: true`, the file code block will be extracted and saved to the appropriate files.  
> You can ask pro@coder to give you some documentation by asking `Show Doc` and pressing `r`  