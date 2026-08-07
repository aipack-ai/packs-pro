`.` minor | `-` Fix | `+` Addition | `^` improvement | `!` Change | `*` important | `>` Refactor

## 2026-08-07 [coder-v0.6.4](https://github.com/aipack-ai/packs-pro/compare/coder-v0.6.3...coder-v0.6.4)

- `+` Added `max_size_kb` for unified size kb (default to 1500)
  - `max_size_kb = 10000` for 10mb (useful when image / pdf in workbench data/)
- `+` auto-context - Support packed code-map in knowledge_globs
  - `- pro@rust10x/code-map.json`  (anything with `code-map` or `content-map` explicit)
- `>` refactor response instructions to system (for fable guardrails)
- **auto-fix**
  - `!` reuse final explicit model for remaining retries. So, the last model will run the remaining of the retries
  - `^` Support comma-separated model sequences
    - `auto_fix: luna-xhigh, terra, sol` (sol will run up to 4 times - default max_retries 6)
  - `^` Track categorized media selections
- `^` code-map - Print unsupported and disabled files after AI
- `^` pins - reorder attachments and oversized files
- `^` coder - Add attachments run pin
- `^` auto-context - Track categorized media selections
- `!` rust10x - Move it to another repo
