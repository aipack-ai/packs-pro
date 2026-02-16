## AI File Change Format

When modifying a codebase, emit all changes inside a single `<FILE_CHANGES>` container using the directives below. Do not place any other content inside `<FILE_CHANGES>`.

You may include explanation before or after the `<FILE_CHANGES>` block. If no changes are required, output nothing.

The format is like: 

<FILE_CHANGES>
 ...FILE_DIRECTIVE_TAGS...
</FILE_CHANGES>

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

````
<FILE_NEW file_path="path/to/file.ext">
```language
(full file contents)
```
</FILE_NEW>
````

### FILE_PATCH

Modifies an existing file using a simplified, numberless unified diff format.

#### Hunk header

- Use a single `@@` on its own line, with no line numbers.
- Never use `@@ -35,26 +83,32 @@`; always just `@@`.
- Do **not** include `---` / `+++` file header lines.
- A single `FILE_PATCH` may contain multiple hunks, each starting with `@@`.

#### Hunk body line format

Every line in a hunk body **must** start with one of exactly three prefix characters:

| Prefix | Meaning                   | Description                                          |
| ------ | ------------------------- | ---------------------------------------------------- |
| ` `    | Context (space character) | Unchanged line; must match the original file exactly |
| `-`    | Removal                   | Line to remove; must match the original file exactly |
| `+`    | Addition                  | Line to add                                          |

**Critical rules for hunk body lines:**

- Every line must begin with one of these three prefix characters. There are no exceptions.
- Context lines (` ` prefix) and removal lines (`-` prefix) must be **exact character-for-character copies** of the corresponding lines in the original file, including all leading/trailing whitespace and indentation.
- If the original line has 4 spaces of indentation, the context line must be ` ` (space prefix) followed by those exact 4 spaces, resulting in 5 characters before the content.
- Minimize the number of context lines to reduce the chance of mismatch. Include only enough context to uniquely identify the location.
- Addition lines (`+` prefix) contain the new content to insert.

#### FILE_PATCH format

````
<FILE_PATCH file_path="path/to/existing_file.ext">
```language
@@
 (context line - exact copy of original, prefixed with a space)
-(removal line - exact copy of original, prefixed with -)
+(addition line - new content, prefixed with +)
 (context line)
```
</FILE_PATCH>
````

### FILE_RENAME

````
<FILE_RENAME from_path="old/path.ext" to_path="new/path.ext" />
````

### FILE_DELETE

```
<FILE_DELETE file_path="path/to/file.ext" />
````

### Complete Example

<FILE_CHANGES>

<FILE_NEW file_path="src/hello.rs">
```rust
pub fn hello() {
    println!("Hello from hello.rs");
}
````

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
