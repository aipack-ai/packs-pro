## AI File Change Format Convention Instructions

When updating files, update the codebase **only** by emitting a structured change bundle using the format described below.

### Rules

- The container tag `FILE_CHANGES` must contain only file change directives.
- Every modification must be represented explicitly as one of the following operations:
  - `FILE_NEW` – create a new file (must not overwrite unless explicitly instructed).
  - `FILE_PATCH` – modify an existing file using a hunk-style unified diff (without hunk numbers, just `@@` as the hunk delimiter). See more FILE_PATCH rules below.
  - `FILE_RENAME` – rename or move a file
  - `FILE_DELETE` – delete a file
- The code fence language (for example, `rust`, `ts`, `python`) is for syntax highlighting only and should match the target file’s language.
- Preserve exact formatting and whitespace.
- Do not invent files or paths.
- If no changes are required, output nothing.
- Very important: For `FILE_PATCH`, make sure the surrounding text is an exact match, and per uniffied diff spec, start with and empty char for each line. otherwise the patch will not work.
- Very important as well: For `FILE_PATCH`, the `-` patch lines need to match exactly the lines they are supposed to remove, otherwise the patch will not work.


You may include additional explanation before or after the `<FILE_CHANGES>` block; it will be shown to the user. Do not place anything inside `<FILE_CHANGES>` other than directives.



#### FILE_PATCH rules

- `FILE_PATCH` must contain simplified, hunk-style, number-less uniffied diff content like:
- The hunk body should be standard uniffied diff lines with the ` ` for surrounding, and `-` and `+` for the remove and addition.
- Make sure the surrounding lines (starting with ` `) and the remove lines (starting with `-`) have their content match exactly the source line. 
- Minimize the number surrounding lines to mimize change of mismatch
- The Hunk header for FILE_PATH are simplified as such
  - Use single `@@` for the header, but no numbers
  - For example, Never use `@@ -35,26 +83,32 @@`, use just one `@@` without numbers, even when there are multiple hunks per file.
  - AlsoDo **not** include `---` / `+++` file headers, because `file_path` is the only source of truth for the target file.
- So the hunk header is simplified, but the content line should follow the standard. 

IMPORTANT: Make sure to respect leading spaces for the hunk surrounding content.


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