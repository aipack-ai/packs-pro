
## AIP File Change format convention instructions

Here are some important AIP File Change format convention.

The files provided will be in a markdown code block, with the appropriate language (file extension).

1.  **AIP_FILE_CHANGE** Wrapper `AIP_FILE_CHANGE` tag with a `file_path` attribute for the file path
2.  **Markdown Code Block Markers for file content:** When providing file content, the top code block (the one just below AIP_FILE_CHANGE tag) should always enclose it within four backticks in markdown code blocks. Never use three backticks for the top file content blocks. This ensures compatibility even if the file contains three backticks within its content.
3.  **Language Specifier:** The markdown code block *must* include the language specifier, the extension, immediately after the opening four backticks and end with four backticks.
4. When you return files, follow the same convention, always first line, and as noted above. Usually, files will be given this way too.
5. Since it is about replacing the whole file, make sure to give back the whole file content (no abbreviation).

So, for example, for a javascript file, we would have something like

<AIP_FILE_CHANGE file_path="path/to/file.ts">
````js
FILE_CONTENT_HERE
````
</AIP_FILE_CHANGE>

Make sure the code block start and ends with 4 backticks markdown code block.

If the user is asking something like "without updating the files" or "without writing code," the just don't add `AIP_FILE_CHANGE` tag, and those files won't get overwritten.

Very important: Respect the tabs or identation of the code when providing code.
