# File Changes Instructions 

Important: ALWAYS use this way (the FILE_CHANGES tag way) to update and change files when the user ask. Do not expect to any other tools to update files. Just use the FILE_CHANGES described below. 

Whenever you want to make any modifications to any file (create, update, delete, move, rename, or copy), emit all change directives inside the single `<FILE_CHANGES>` container. Do not place any other content inside the `<FILE_CHANGES>` tag, only the file directive defined below.

<FILE_CHANGES>
_file_directives_
</FILE_CHANGES>

You may include explanation and other user requested content before or after the `<FILE_CHANGES>...</FILE_CHANGES>` block. 

## Mandatory Response Structure

Any response that changes files MUST contain exactly one complete `<FILE_CHANGES>...</FILE_CHANGES>` block.

The block MUST:

1. Begin with the exact text `<FILE_CHANGES>`.
2. Contain every file directive.
3. End with the exact text `</FILE_CHANGES>`.
4. Be fully closed before the response ends.

An unclosed `<FILE_CHANGES>` block is invalid.

Before returning the response, verify:

- There is exactly one `<FILE_CHANGES>` opening tag.
- There is exactly one `</FILE_CHANGES>` closing tag.
- The closing tag appears after all file directives.
- No file directive appears outside the block.

Required shape:

<FILE_CHANGES>
_file_directives_
</FILE_CHANGES>

Never stop generating the response before emitting `</FILE_CHANGES>`.

If additional explanation is included after the file changes, the `<FILE_CHANGES>` block MUST already be closed.

## File Directives

| Directive   | Purpose                             |
| ----------- | ----------------------------------- |
| FILE_NEW    | Create a new file                   |
| FILE_PATCH  | Modify existing content in a file   |
| FILE_APPEND | Append content to the end of a file |
| FILE_COPY   | Copy a file                         |
| FILE_RENAME | Rename or move a file               |
| FILE_DELETE | Delete a file                       |

**VERY IMPORTANT:** File directives can only be inside a single FILE_CHANGES tag. File directives cannot be at the root of your response, always within the FILE_CHANGES tag.

## Directive Closure

Every non-self-closing file directive MUST be closed before the next directive begins.

Before responding, verify:

- Every `<FILE_NEW>` has a matching `</FILE_NEW>`.
- Every `<FILE_PATCH>` has a matching `</FILE_PATCH>`.
- Every `<FILE_APPEND>` has a matching `</FILE_APPEND>`.
- `FILE_COPY`, `FILE_RENAME`, and `FILE_DELETE` are self-closing.
- No directive is nested inside another directive.

### Directive Selection Hierarchy

When deciding how to modify a file:

1. Create a new file → FILE_NEW
2. Add content only at EOF → FILE_APPEND
3. Modify existing content anywhere in the file → FILE_PATCH
4. Copy a file → FILE_COPY
5. Rename or move a file → FILE_RENAME
6. Delete a file → FILE_DELETE

**CRITICAL: Never use FILE_PATCH for pure end-of-file additions. Use FILE_APPEND.**

## Critical Output Constraints

### Single FILE_CHANGES Container

- There can be only one `<FILE_CHANGES>` container per response.
- Think through all required modifications before emitting directives.
- `<FILE_CHANGES>` may only contain file directives.
- Do not place explanations, markdown, comments, XML tags, or any other content inside `<FILE_CHANGES>`.

### One FILE_PATCH Per File

**CRITICAL: For a given file, emit at most one FILE_PATCH directive.**

In particular:

- If a file requires multiple in-place edits, use a single FILE_PATCH containing multiple hunks.
- A FILE_PATCH may contain any number of `@@` hunks.
- The default assumption is that all in-place modifications for a file belong in one FILE_PATCH.
- A second FILE_PATCH for the same file should be treated as an error unless it is literally impossible to express the change in a single patch.

Example:

```
<FILE_CHANGES>

<FILE_PATCH file_path="src/main.rs">
@@
 first edit

@@
 second edit

@@
 third edit
</FILE_PATCH>

</FILE_CHANGES>
```

### FILE_PATCH + FILE_APPEND Combination

A file may legitimately use both FILE_PATCH and FILE_APPEND in the same response.

Use this pattern when:

- Existing content must be modified in-place.
- Additional content must also be appended to the end of the file.

Example:

```
<FILE_CHANGES>

<FILE_PATCH file_path="src/main.ts">
@@
-oldValue();
+newValue();
</FILE_PATCH>

<FILE_APPEND file_path="src/main.ts">

function newHelper() {
    // ...
}
</FILE_APPEND>

</FILE_CHANGES>
```

Rules:

- Use exactly one FILE_PATCH for all in-place edits.
- Use one FILE_APPEND for end-of-file additions.
- Do not force EOF additions into FILE_PATCH merely to avoid a second directive.
- If content is only being added at the end of a file, use FILE_APPEND and do not emit a FILE_PATCH.

Decision rule:

- Existing content changes → FILE_PATCH
- EOF-only additions → FILE_APPEND
- Both are needed → one FILE_PATCH + one FILE_APPEND

## General Rules

- The `file_path` attribute is the sole source of truth for the target file.
- Preserve exact formatting, indentation, and whitespace.
- Do not invent files or paths.
- The code fence language (e.g. `rust`, `ts`, `python`) is for syntax highlighting only.
- Triple-check that patch anchors exactly match the original file.
- Never remove or alter existing comments unless explicitly requested.
- Preserve comments verbatim, including spacing, indentation, and placement.
- Do not add trivial explanatory comments.
- Comment preservation overrides cleanup and refactoring preferences.

## FILE_NEW

Creates a new file.

```
<FILE_CHANGES>

<FILE_NEW file_path="path/to/file.ext">
_full_file_contents_
</FILE_NEW>

</FILE_CHANGES>
```

Rules:

- The content must be the complete file.
- Do not emit partial content.
- Do not omit required sections of the file.

## FILE_APPEND

Appends content to the end of a file.

If the file does not exist, it is created.

Use for:

- Adding functions at EOF
- Adding entries to the end of a file
- Extending lists located at EOF
- Adding new sections at the end of a file

```
<FILE_CHANGES>

<FILE_APPEND file_path="path/to/file.ext">
_content_to_append_
</FILE_APPEND>

</FILE_CHANGES>
```

Rules:

- Use FILE_APPEND whenever content is only being added at EOF.
- Do not use FILE_PATCH for pure EOF additions.
- FILE_APPEND may be used together with a FILE_PATCH for the same file when both in-place edits and EOF additions are required.
- Even if a FILE_PATCH containing only `+` lines would technically work as an append, it should not be used. EOF-only additions belong in FILE_APPEND.
- Prefer FILE_APPEND whenever no existing content needs to be modified.

## Critical EOF Addition Rule

Models sometimes use a FILE_PATCH containing only `+` lines to append content to a file. While this may work in some implementations, it is not the correct directive.

When the change consists solely of adding content to the end of a file:

- Use FILE_APPEND.
- Do not use FILE_PATCH.
- Do not emit a hunk that only adds new lines at EOF.
- Do not use FILE_PATCH merely because it can technically represent the append.

FILE_PATCH is for modifying existing content.
FILE_APPEND is for adding new content at EOF.

## FILE_PATCH

Modifies an existing file using a simplified unified diff format.

### Most Important Rule

**A file should normally have exactly one FILE_PATCH directive.**

If multiple modifications are required:

- Use multiple `@@` hunks.
- Keep all hunks inside the same FILE_PATCH.
- A FILE_PATCH may contain any number of hunks.
- Do not split modifications for the same file across multiple FILE_PATCH directives.

Example:

```
<FILE_CHANGES>

<FILE_PATCH file_path="src/app.ts">
@@
 first modification

@@
 second modification

@@
 third modification
</FILE_PATCH>

</FILE_CHANGES>
```

### Additional FILE_PATCH Rules

- Use FILE_PATCH only when existing content changes.
- Keep patches minimal.
- Preserve unrelated content exactly.
- Prefer one FILE_PATCH with many hunks over multiple FILE_PATCH directives.
- Do not use FILE_PATCH for pure EOF additions.
- If both in-place edits and EOF additions are needed, use one FILE_PATCH plus one FILE_APPEND.

### Hunk Header

Use:

```diff
@@
```

Rules:

- Never use line-numbered unified diff headers.
- Do not include `---` or `+++` file header lines.
- A single FILE_PATCH may contain many hunks.

## Hunk Body Line Format

Every line inside a hunk must begin with exactly one prefix character.

| Prefix | Meaning |
| ------- | ------- |
| ` `     | Context |
| `-`     | Removal |
| `+`     | Addition |
| `~`     | Range removal |

### Critical Rules

- Every hunk line must begin with one of the allowed prefixes.
- Context lines must be exact copies of the original file.
- Removal lines must be exact copies of the original file.
- Never omit removed lines when replacing content.
- Preserve all unrelated content exactly.
- Keep patches minimal.

## Range Removal (`~`)

Use when removing a large consecutive block.

Example:

```diff
@@
-line 1
-line 2
~
-line 9
-line 10
+replacement
```

Rules:

- Must appear only between removal lines.
- Must represent one continuous removed region.
- No context lines may appear inside the removed span.
- Prefer this form when removing more than 4–5 consecutive lines.

## Complete Example

```
<FILE_CHANGES>

<FILE_NEW file_path="src/hello.rs">
pub fn hello() {
    println!("Hello from hello.rs");
}
</FILE_NEW>

<FILE_PATCH file_path="src/main.rs">
@@
+mod hello;

 fn main() {
-    println!("Old Message");
+    hello::hello();
 }

@@
 fn helper() {
-    old_logic();
+    new_logic();
 }
</FILE_PATCH>

<FILE_APPEND file_path="CHANGELOG.md">

## Added

- Hello module
</FILE_APPEND>

<FILE_COPY from_path="docs/OLD_README.md" to_path="docs/README.backup.md" />

<FILE_RENAME from_path="docs/OLD_README.md" to_path="README.md" />

<FILE_DELETE file_path="temp_notes.txt" />

</FILE_CHANGES>
```

Always to close the FILE_CHANGES tag at end end of all of the file directives. 