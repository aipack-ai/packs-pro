# Spec: Likely-Text File Listing in `pro@coder`

This document captures the current file-listing design used by `pro@coder` for likely-text handling, why it exists, and how callers are expected to use it.

## Purpose

The goal is to have one shared policy for handling `is_likely_text` across the main `pro@coder` pipeline, while keeping behavior consistent in:

- `before all` reference resolution
- `auto-context` file selection inputs
- `code-map` file discovery

This avoids duplicated filtering logic and ensures text-oriented prompts do not accidentally include binary or non-text files.

## Core Design

The shared implementation lives in `pro/coder/lua/utils_common.lua`.

### Low-level filter

The foundational helper is:

- `filter_likely_text(files) -> files`

Behavior:

- If `files` is `nil` or empty, it returns the input as-is.
- If the first file does not expose `is_likely_text`, it returns the input as-is.
- Otherwise, it filters out files where `is_likely_text == false`.
- Files with missing `is_likely_text` are kept.

This preserves backward compatibility and matches the intended permissive behavior when metadata is incomplete.

### Shared wrappers

To standardize list behavior, `utils_common.lua` provides these wrappers:

- `list_likely_text(globs, options) -> FileInfo[]`
- `list_likely_text_with_stats(globs, options) -> { files: FileInfo[], non_text_file_count: number }`
- `list_load_likely_text(globs, options) -> FileRecord[]`

#### `list_likely_text`

Usage:

- Call `aip.file.list(...)`
- Then apply `filter_likely_text(...)`

Use this when you only need the filtered files.

#### `list_likely_text_with_stats`

Usage:

- Call `aip.file.list(...)`
- Apply `filter_likely_text(...)`
- Compute `non_text_file_count` as the difference between listed files and filtered files

Use this when the caller also wants to report how many non-text files were ignored.

This is intentionally a single-pass design over one list result, no extra listing call is needed.

#### `list_load_likely_text`

Usage:

- Call `aip.file.list_load(...)`
- Apply `filter_likely_text(...)`

Use this when content must be loaded immediately, but only likely-text files should be retained.

## Why this design exists

This design was introduced to unify behavior and make the file-selection policy explicit in one place.

### Main reasons

- One consistent place to define likely-text filtering behavior.
- Matching file selection behavior across `before all`, `auto-context`, and `code-map`.
- No need to extend `aip.file.list(...)` or `aip.file.list_load(...)` API signatures for this use case.
- The main context and code-map flow already filters at the file-list stage, before individual file loading.

## Current caller expectations

### `pro/coder/lua/utils_before_all.lua`

This stage resolves:

- `knowledge_globs`
- `context_globs`

It should use:

- `u_common.list_likely_text(...)` for knowledge refs
- `u_common.list_likely_text(...)` for context refs

Rationale:

- These refs are later loaded individually downstream.
- Filtering should already have happened before those later loads.
- No special `list_load` filtering flag is needed for the main pipeline.

### `pro/coder/auto-context.aip`

This stage uses likely-text-aware listing in several places.

#### Helper files

Helper files should use:

- `u_common.list_load_likely_text(auto_context_config.helper_globs)`

Rationale:

- Helper files are sent directly into the AI prompt.
- Non-text helper files should be excluded before prompt construction.

#### Context and knowledge file stats

For file-count and size computation, it should use:

- `u_common.list_likely_text(context_globs)`
- `u_common.list_likely_text(knowledge_globs)`

Rationale:

- Size and count should reflect the same file policy used by the rest of the pipeline.

#### Available files used to cross-reference code-map content

For code-map matching, it should use:

- `u_common.list_likely_text(auto_context_config.code_map_globs)`
- `u_common.list_likely_text(knowledge_globs)`

Rationale:

- The available file universe for selection should exclude non-text files.

### `pro/coder/code-map.aip`

For code-map file discovery, the design preserves non-text ignored counts.

Use:

- `u_common.list_likely_text_with_stats(mdef.globs)`

Rationale:

- Code-map wants both filtered files and `non_text_file_count`.
- If filtering were done earlier without stats, ignored counts would be lost.
- This keeps reporting accurate while still sharing the common filter policy.

## What remains unchanged

The following remain intentionally unchanged:

- `u_common.filter_likely_text(files)` remains the low-level filter helper.
- `code_map.filter_text_files(files)` can remain as a convenience for already-listed arrays.
- `utils_data.load_file_refs(...)` does not need changes, because upstream refs are expected to already be filtered.
- No API changes are required to `aip.file.list(...)` or `aip.file.list_load(...)`.

## Design constraints and decisions

### Files with missing `is_likely_text`

Decision:

- Keep them.

Reason:

- Current behavior is permissive.
- This avoids accidentally dropping valid files when metadata is unavailable.

### Helper-file non-text counts

Decision:

- Do not track ignored non-text helper-file counts for now.

Reason:

- It would require additional reporting work and was explicitly deferred.
- Current priority is shared filtering behavior, not expanded metrics.

### Filtering stage

Decision:

- Filter as early as practical, at the list stage.

Reason:

- It keeps downstream logic simpler.
- It ensures later individual loads operate on already-approved refs.
- It avoids sending non-text content into context-building prompts.

## Flow summary

### Main pipeline

1. List files from globs.
2. Filter to likely-text files through shared wrappers.
3. Pass filtered refs downstream.
4. Load individual files later as needed.

### Auto-context helper flow

1. Load files with `list_load_likely_text(...)`.
2. Exclude non-text helpers before prompt assembly.

### Code-map flow

1. List files with `list_likely_text_with_stats(...)`.
2. Keep filtered files for processing.
3. Preserve `non_text_file_count` for status reporting.

## Outcome

The implemented design gives `pro@coder`:

- one shared likely-text policy
- consistent selection behavior across major flows
- preserved permissive fallback behavior when metadata is missing
- accurate ignored-file stats where needed
- no unnecessary API expansion

This document reflects the intended and implemented design direction captured from the dev chat and the shared helpers in `utils_common.lua`.

