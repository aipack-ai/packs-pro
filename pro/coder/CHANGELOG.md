`.` minor | `-` Fix | `+` Addition | `^` improvement | `!` Change | `*` important | `>` Refactor

## 2026-08-07 [coder-v0.6.4](https://github.com/aipack-ai/packs-pro/compare/coder-v0.6.3...coder-v0.6.4)

- `+` Added `max_size_kb` for a unified size limit (defaults to 1500 KB)
  - `max_size_kb = 10000` for 10 MB, useful for images/PDFs in workbench data/
- `+` auto-context, support packed code maps in knowledge_globs
  - `- pro@rust10x/code-map.json` (anything with `code-map` or `content-map` explicitly)
- `>` Refactor response instructions into the system for fable guardrails
- **auto-fix**
  - `!` Reuse the final explicit model for remaining retries
  - `^` Support comma-separated model sequences
    - `auto_fix: luna-xhigh, terra, sol` (sol runs up to 4 times, default `max_retries` is 6)
  - `^` Track categorized media selections
- `^` code-map, print unsupported and disabled files after AI
- `^` pins, reorder attachments and oversized files
- `^` coder, add attachment run pin
- `^` auto-context, track categorized media selections
- `!` rust10x, move it to another repo