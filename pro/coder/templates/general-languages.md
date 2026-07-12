## Languages best practices

Here are some some general language best practices to follow when providing code.

### Markdown formatting & rules

- Always insert exactly one blank line after every markdown heading (`#`, `##`, `###`, `####`, `#####`, `######`, etc.).
- Make sure to put all programming code or JSON in a Markdown code block with the appropriate language label (rust, typescript, json, yaml, etc.).
- Never place any content (paragraphs, lists, code blocks, tables, etc.) immediately after a heading.
- Unless instructed otherwise, use `-` for bullet lists instead of `*`.
- Surround bullet lists with blank lines (one blank line before the list and one after it).
- For code, always use fenced markdown code blocks with the correct language identifier.
- Use `text` only when the content is plain text or the language cannot be determined with reasonable confidence.
- Do not indent fenced code blocks. The opening fence, code content, and closing fence must all start at column 0.
- Preserve existing horizontal rules, but never create new ones.
- Do not output `---`, `***`, or `___` as standalone lines unless they already exist in the input content.

### HTML

- Keep the tags simple, and use modern techniques that work in browsers that are -2 years old.
- Use CSS class names as IDs rather than element IDs when creating new code.
    - However, do not change the code unless explicitly asked by the user.

### JavaScript

- Use the web module loading so that we can use modern JavaScript.
- When drawing, try to use Canvas 2D.
- Use standard fetch to retrieve JSON.

### CSS

- Try to use CSS Grid when possible.
- When files are `.pcss`, assume there is a PCSS plugin nested, so that you do not get confused, and keep the nesting appropriately.

### General

- When you provide the code, make sure to return it in the relevant Markdown code block, with the correct language, and include the file path line.
- Only provide the files that need to be corrected, but make sure each file you return includes all of the code for that file.
- Make sure all file names are lowercase, and if they have multiple words, separate them with `-`.
- When you provide an answer with bullet points, use the `-` character for bullet points (in short, use only 7-bit ASCII characters).
- When you provide file paths and names in Markdown text, put them in backticks, like `some/path/to/file.rs`.
- Do not remove code regions unless explicitly asked.
- When you update code, types, functions or code body, make sure any related adjacent comment is kept in sync wwith the new logic / type. Follow the current function and type comment pattern.