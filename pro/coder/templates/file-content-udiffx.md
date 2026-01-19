## AI File Change Format Convention Instructions

When updating files, update the codebase **only** by emitting a structured change bundle using the format described below.

### Rules

- The container tag `FILE_CHANGES` must contain only file change directives.
- Every modification must be represented explicitly as one of the following operations:
  - `FILE_NEW` – create a new file (must not overwrite unless explicitly instructed)
  - `FILE_PATCH` – modify an existing file using a hunk-style unified diff (without hunk numbers, just `@@` as the hunk delimiter)
  - `FILE_RENAME` – rename or move a file
  - `FILE_DELETE` – delete a file
- `FILE_PATCH` must contain simplified, hunk-style, number-less unified diff content like:
  - Hunk headers with `@@`, but no numbers
  - The `-` and `+` lines with the proper surrounding lines.
  - Do **not** include `---` / `+++` file headers, because `file_path` is the only source of truth for the target file.
  - Never use `@@ -35,26 +83,32 @@`, use just one `@@` without numbers, even when there are multiple hunks per file.
- The code fence language (for example, `rust`, `ts`, `python`) is for syntax highlighting only and should match the target file’s language.
- Preserve exact formatting and whitespace.
- Do not invent files or paths.
- If no changes are required, output nothing.
- Very important: For `FILE_PATCH`, make sure the surrounding text is an exact match, otherwise the patch will not work.
- Very important as well: For `FILE_PATCH`, the `-` patch lines need to match exactly the lines they are supposed to remove, otherwise the patch will not work.

IMPORTANT: Make sure to respect leading spaces for the hunk surrounding content.

You may include additional explanation before or after the `<FILE_CHANGES>` block; it will be shown to the user. Do not place anything inside `<FILE_CHANGES>` other than directives.

### Format

<FILE_CHANGES>

<FILE_NEW file_path="path/to/file.ext" mode="create_only">
```language
(file contents)
```
</FILE_NEW>

<FILE_PATCH file_path="path/to/existing_file.ext">
```language
@@
(contextual hunk-style diff)
```
</FILE_PATCH>

<FILE_RENAME from_path="old/path.ext" to_path="new/path.ext" />

<FILE_DELETE file_path="path/to/file.ext" />

</FILE_CHANGES>

### Example

<FILE_CHANGES>

<FILE_NEW file_path="src/main.rs" mode="create_only">
```rust
fn main() {
    println!("Old Message");
}
```
</FILE_NEW>

<FILE_NEW file_path="src/hello.rs" mode="create_only">
```rust
pub fn hello() {
    println!("Hello from hello.rs");
}
```
</FILE_NEW>

<FILE_PATCH file_path="src/main.rs">
```rust
@@
+mod hello;
+
 fn main() {
-    println!("Old Message");
+    hello::hello();
 }
```
</FILE_PATCH>

<FILE_RENAME from_path="docs/OLD_README.md" to_path="README.md" />

<FILE_DELETE file_path="temp_notes.txt" />

</FILE_CHANGES>