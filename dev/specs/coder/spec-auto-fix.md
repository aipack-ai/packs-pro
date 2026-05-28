# Built-In Auto-Fix for Udiffx Failures (Implementation Spec)

## Intent

Define the built-in `pro@coder` auto-fix feature that automatically attempts to repair failed `udiffx` file change applications before the normal post-stage sub-agent flow runs.

The user-facing parameter is `auto_fix`, defaulting to `true`. Auto-fix runs only when all eligibility checks pass:

- `auto_fix == true`
- `write_mode == true`
- `file_content_mode` is `udiffx`
- the coder run has a single task response
- at least one `udiffx` hunk apply failure occurred

When eligible, the runtime defers immediate failure reporting, writes the latest failure diagnostics under the workbench cache, and runs a built-in `auto-fix.aip` agent up to 3 times before user post-stage sub-agents execute. Success clears the failure state; retry exhaustion falls back to the existing terminal warning and failure report behavior. Multi-task `working_globs` runs skip auto-fix and preserve current failure behavior.

## Code Design

### Runtime Normalization and Eligibility

`utils_before_all.lua` normalizes the `auto_fix` parameter and builds an initial eligibility object:

- Missing `auto_fix` defaults to `true`.
- Initial state captures `enabled`, `write_mode`, `udiffx`, and workbench cache availability.
- The `build_auto_fix_state` function produces a `base_eligible` flag. Eligibility is finalized per-task in `main.aip` (`# Data`), where `single_task` is set and multi-task runs become ineligible regardless of `base_eligible`.

The normalized state is carried through `input_base`, `coder_response`, and the output/after-all data so later stages do not read raw prompt metadata.

### Failure Detection and Deferral

`main.aip` (`# Output`) calls `u_output.apply_changes` as before. When structured udiffx hunk failures exist, `auto_fix.lua::should_defer_failed_changes` determines whether to skip immediate failure reporting.

`should_defer_failed_changes` checks:

- `auto_fix.eligible == true`
- structured hunk details are present (via `failed_hunk_details_available`)
- the overall `file_changes_status` has a non-zero `fail_count`

When eligible, the output stage sets `deferred_failure_report = true` in the `coder_response` and does not call `handle_failed_changes`. The existing immediate reporting path is preserved for all ineligible or ambiguous cases.

After the output stage, `build_failed_changes_from_status` can reconstruct a failed-changes list from a `file_changes_status` object for use in the after-all flow.

### Diagnostics Artifacts

`auto_fix.lua::write_auto_fix_diagnostics` writes the latest failure state under `$coder_workbench.cache_dir/auto-fix/`:

- `last_udiffx_fail_reports.md` – formatted markdown report reusing `format_failed_changes_for_file_report`
- `last_udiffx_fail_info.json` – compact JSON with:
  - `failed_paths` (array of file paths)
  - `failed_files` (array of objects with `file_path` and `failed_hunks_count`)
  - change kind information when available

The files are overwritten on every call so only the latest failure state is used. The original raw model response is not included.

If the cache directory is missing or writing fails, the function returns a failure marker, preserving the original failure state for fallback reporting.

### Built-In Auto-Fix Agent

`pro/coder/auto-fix.aip` is an internal agent invoked only by the after-all retry loop. It:

- Resolves the auto-fix diagnostics directory from the input `auto_fix_dir`.
- Loads `last_udiffx_fail_reports.md` and `last_udiffx_fail_info.json`.
- Skips via `aip.flow.skip` if either file is missing or empty.
- Includes the udiffx file change instructions (runtime `aip.udiffx.file_changes_instruction()` with a bundled template fallback).
- Shows the model the current content of each failed file.
- Asks for corrected `<FILE_CHANGES>` directives only.
- Returns the raw model response as `auto_fix_content` in its output.

The agent never applies changes itself; the main flow applies the response through the existing `apply_changes` path.

### After-All Retry Orchestration

`auto_fix.lua::run_auto_fix_loop` is called in `main.aip` (`# After All`) for each deferred failure response, *before* `run_sub_agents_post`.

The loop (bounded to 3 attempts):

1. Resolves the current failed changes from the original response (`files_changes_failed` or reconstructed from `file_changes_status`).
2. Writes the latest diagnostics.
3. Runs `auto-fix.aip` with the diagnostics directory.
4. Applies the returned `<FILE_CHANGES>` content via `u_output.apply_changes`.
5. Aggregates successfully changed files and updates the failure list.
6. Stops immediately when no failed changes remain, or stops retrying if the agent skipped, returned nothing, or produced an empty response.

On success, the loop updates `coder_response.file_changes_status` and `coder_response.auto_fix_result` with the final aggregated state, and a refreshed completion pin reflects all changed files.

On retry exhaustion, the existing `write_auto_fix_diagnostics` + `handle_failed_changes` fallback runs, and the pre-auto-fix terminal warning (`❗❗❗ Failed to apply some changes to file(s) ❗❗❗`) is pinned again in both the run and task scopes.

The existing post-stage sub-agent contract and redo behavior are unchanged.

### Shared Helpers

`pro/coder/lua/auto_fix.lua` contains all auto-fix-specific functions, keeping them separate from the general-purpose `utils_output.lua` helpers. Functions include:

- `load_text_file`, `normalize_failed_change_path`, `failed_hunk_details_available`
- `should_defer_failed_changes`, `build_failed_changes_from_status`
- `write_auto_fix_diagnostics`, `build_auto_fix_info`
- `run_auto_fix_loop`, `collect_successful_changes_from_status`, `build_auto_fix_file_changes_status`, `build_auto_fix_completion_response`
- `get_auto_fix_dir_from_input`

General failure formatting helpers (`failed_hunk_counts`, `resolve_failed_hunk_total_count`, `hunk_failure_count_text`, `file_change_status_letter`) remain in `utils_output.lua` and are required by the auto-fix module.

## Design Considerations

### Why Auto-Fix Is Internal

Auto-fix must run between the main apply step and user post-stage sub-agents. An internal built-in loop keeps the ordering deterministic without requiring user configuration.

### Why Diagnostics Use the Workbench Cache

The workbench cache directory already hosts transient runtime artifacts. Using `coder_workbench.cache_dir/auto-fix` keeps diagnostics alongside other cache files and avoids creating a new public configuration surface.

### Why the First Version Is Udiffx-Only

The `udiffx` apply path provides structured hunk failure details that enable automated correction. Other file change modes are excluded until a deliberate expansion.

### Why the First Version Is Single-Task-Only

Single-task support avoids ambiguity about which failed response and file state should be repaired. Multi-task runs skip auto-fix and keep existing reporting.

### Why Only Latest Diagnostics Are Used

Each retry uses the latest failed hunk state, keeping the repair prompt focused and preventing the model from trying to reconcile stale failures.

### Why the Original Raw Response Is Excluded

Failed hunk reports already contain what was attempted and why it failed. Including the full raw response would increase prompt size without benefit for the first implementation.

