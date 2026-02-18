## AI File Change Format

When modifying a codebase, emit all change directives inside a single `<FILE_CHANGES>` container using the directives format below. Do not place any other content inside `<FILE_CHANGES>`. Like

<FILE_CHANGES>
_FILE_DIRECTIVES_
</FILE_CHANGES>

You may include explanation before or after the `<FILE_CHANGES>` block. If no changes are required, output nothing.

IMPORTANT. There can be only one FILE_CHANGES tag per response. So make sure you think of everything before you give the directives inside that tag.


### Directives

| Directive     | Purpose                                  |
| ------------- | ---------------------------------------- |
| `FILE_NEW`    | Create a new file                        |
| `FILE_PATCH`  | Modify an existing file via unified diff |
| `FILE_RENAME` | Rename or move a file                    |
| `FILE_DELETE` | Delete a file                            |

### General Rules

- The `file_path` attribute is the sole source of truth for the target file.
- Preserve exact formatting, indentation, and whitespace.
- Do not invent files or paths.
- The code fence language (e.g., `rust`, `ts`, `python`) is for syntax highlighting only.

### FILE_NEW

Creates a new file. The content inside the code fence is the full file content.

<FILE_NEW file_path="path/to/file.ext">
_full_file_contents_
</FILE_NEW>

### FILE_PATCH

Modifies an existing file using a simplified, numberless unified diff format.

<FILE_PATCH file_path="path/to/file.ext">
_patch_format_
</FILE_PATCH>

#### Hunk header

- Use a single `@@` on its own line, with no line numbers.
- Never use `@@ -35,26 +83,32 @@`; always just `@@`.
- Do **not** include `---` / `+++` file header lines.
- A single `FILE_PATCH` may contain multiple hunks, each starting with `@@`.

#### Hunk body line format

Every line in a hunk body **must** start with one of exactly three prefix characters:

| Prefix | Meaning                   | Description                                                            |
| ------ | ------------------------- | ---------------------------------------------------------------------- |
| ` `    | Context (space character) | Unchanged surrounding line; must match the original file exactly       |
| `-`    | Removal                   | Line to remove; must match the original file exactly                   |
| `+`    | Addition                  | Line to add                                                            |

**Critical rules for hunk body lines:**

- Every line must begin with one of these three prefix characters. There are no exceptions.
- Context lines (` ` prefix) and removal lines (`-` prefix) must be **exact character-for-character copies** of the corresponding lines in the original file. This includes all leading/trailing whitespace, indentation, and any content markers (e.g., Markdown bullet points like `-`, `*`, or `+`, and numbered list markers like `1.`). Any deviation, even a single space or tab, will cause the patch to fail.
- **Never omit removal lines (`-`)** for lines that exist in the original file but are being replaced or removed. If a line is being changed, it must be represented as a `-` line followed by a `+` line. Do not skip lines within the scope of a hunk.
- Minimize the number of context lines to reduce the chance of mismatch. Include only enough context to uniquely identify the location.
- Addition lines (`+` prefix) contain the new content to insert.

#### FILE_PATCH format

<FILE_PATCH file_path="path/to/existing_file.ext">
@@
 (context line - exact copy of original, prefixed with a space)
-(removal line - exact copy of original, prefixed with -)
+(addition line - new content, prefixed with +)
 (context line - if needed)
</FILE_PATCH>

### FILE_RENAME

<FILE_RENAME from_path="old/path.ext" to_path="new/path.ext" />

### FILE_DELETE

<FILE_DELETE file_path="path/to/file.ext" />

### Complete Example

Always with `FILE_CHANGES` tag surrounding the file directives 

#### Example

<FILE_CHANGES>

<FILE_NEW file_path="src/hello.rs">
pub fn hello() {
    println!("Hello from hello.rs");
}

</FILE_NEW>

<FILE_PATCH file_path="src/main.rs">
@@
+mod hello;
+
 fn main() {
-    println!("Old Message");
+    hello::hello();
 }
</FILE_PATCH>

<FILE_RENAME from_path="docs/OLD_README.md" to_path="README.md" />

<FILE_DELETE file_path="temp_notes.txt" />

</FILE_CHANGES>
