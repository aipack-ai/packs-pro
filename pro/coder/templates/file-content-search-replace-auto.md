## AIP File Change Format Convention Instructions

When giving a new content of a file, here are some important AIP File Change format conventions to provide the changes.

All file change, create or update should be of the following format. 

- Inside a `AIP_FILE_CHANGE` tag
- With a `file_path="..."` file path attribute
- And the content of the file inside, surrounded by the four backticks and the language

For example: 

<AIP_FILE_CHANGE file_path="path/to/file.ts">
````ts
CHANGE_CONTENT_HERE
````
</AIP_FILE_CHANGE>
{{/if}}

Follow the instructions below to create or update files.

- When a file needs to be updated, use the SEARCH/REPLACE technique. It can have multiple search/replace sections in the same code block.
- When creating a new file, use the full file content technique.

**CRITICAL: The SEARCH block is the single most important part of the update. If it does not match every single character (including spaces and newlines) of the original file, the update will fail. You must copy the text directly from the source.**

The files provided will be in a markdown code block, with the appropriate language (file extension) with the first line following this format (with the comment language).

Important: When creating a full file, you can add the entire file. When updating a file, use narrow, targeted SEARCH/REPLACE pairs as defined below.

1. **AIP_FILE_CHANGE**  
   Wrapper `AIP_FILE_CHANGE` tag with a `file_path` attribute for the file path.

2. **Language Specifier**  
   The markdown code block must include the language specifier (the file extension) immediately after the opening four backticks and be closed with four backticks.

3. **File Returns**  
   When returning files, follow the same convention—always begin with the file header line as noted above. Files you receive will generally follow the same pattern.

4. **Modifications**  
   Do not remove content unless necessary. Use the SEARCH/REPLACE technique described below to modify only what is needed.

5. **Full File vs. SEARCH/REPLACE**  
   When creating a new file, include the entire file content in the `file_content_or_search_replace_here` section (do not use SEARCH/REPLACE blocks).  
   When updating an existing file, use the SEARCH/REPLACE method described below (except when most of the file needs to be rewritten entirely).

   Do not use placeholder code like `// ...` to represent unchanged sections.  
   In full-file mode, return the entire file.  
   In SEARCH/REPLACE mode, only return the exact search and replacement blocks.  
   Never use placeholders to skip code.

6. **SEARCH/REPLACE**  
   Make the search pattern as small as possible while still uniquely identifying the content to be replaced. Avoid overly large searches that might replace unintended text.

7. **SEARCH/REPLACE Format**  
    Follow the SEARCH/REPLACE format exactly as described below.

8. **Indentation Accuracy**  
    Maintain exact spaces or tabs in both SEARCH and REPLACE sections. Any mismatch will cause the replacement to fail.

9. **No Git Syntax**  
    SEARCH/REPLACE sections are not git diffs. Do not use `+` or `-` prefixes. Provide only the SEARCH and REPLACE text blocks.

10. **Line Matching**  
    SEARCH patterns are matched line by line. Include each exact full line with the exact original indentation.

11. **Removing Lines**  
    To delete content, use a SEARCH block for the text to remove and leave the REPLACE block empty. Do not prefix lines with `-`.

12. **Exact Matching**  
    Ensure the SEARCH section matches exactly the original text, so that it can be found. The SEARCH section must match every character, including whitespace, indentation, and trailing spaces.

13. **Empty Line Handling**  
    When removing sections, include any adjacent empty lines in the SEARCH block so that only one empty line remains after replacement.

14. **Keep It Minimal**  
    Always aim for the smallest possible SEARCH block and replace only what is necessary.

15. **Large Replacements**  
    If the SEARCH section covers 80% or more of the file, use a full file code block instead of SEARCH/REPLACE. However, prefer small, focused replacements whenever possible.

16. **Verbatim SEARCH Blocks Only**  
    The SEARCH section must contain text copied verbatim from the original file, with no alterations, no normalization, no auto-formatting, no whitespace adjustments, and no line-wrapping changes.

17. **No Inference or Correction**  
    Do not infer missing characters, fix typos, adjust indentation, or auto-correct formatting in

### SEARCH/REPLACE format

Here is an example of a SEARCH/REPLACE

<AIP_FILE_CHANGE file_path="path/to/file.ts">
````js
<<<<<<< SEARCH
import * from "process"
=======
import * from "process"
import * from "some-lib"
>>>>>>> REPLACE
<<<<<<< SEARCH
    return `Hello ${name}, welcome to the world`
=======
    return `Hello ${name}, big welcome`
>>>>>>> REPLACE
````
</AIP_FILE_CHANGE>

### Additional SEARCH/REPLACE Strictness Rules

The following rules refine and strengthen the SEARCH/REPLACE behavior. They **do not repeat** the general rules already defined earlier; they only add the critical constraints needed to ensure accurate, reliable updates.

**Verbatim SEARCH Requirements**
- The SEARCH block must be copied **exactly** from the user-provided file content, with **no changes whatsoever**.
- This includes preserving all whitespace: leading spaces, trailing spaces, tabs, and blank lines.
- **Even if the source code has incorrect indentation, trailing whitespace, or typos, the SEARCH block MUST reflect them exactly.**
- Do not auto-correct typos, re-indent, normalize formatting, or “fix” code in the SEARCH block. If you want to fix something, do it in the REPLACE block.
- **NEVER** truncate code in the SEARCH block. If you need to match a long line, you must include the full line.

**No Guessing or Reconstruction**
- The SEARCH content must come **only** from the exact file content supplied by the user in the current request.
- If any part of the needed SEARCH text is missing, incomplete, or ambiguous, **stop and ask the user** instead of trying to infer or reconstruct the content.

**Minimal but Unambiguous Match**
- Keep SEARCH blocks as small as possible while still uniquely identifying the intended lines.
- If the same lines appear multiple times in the file, include just enough surrounding context to disambiguate—no more.

**Code Block Requirements**
- All SEARCH/REPLACE pairs for a file must appear together in a **single**, uninterrupted quad-backtick code block.
- No explanation, comments, or blank lines may appear inside the code block between SEARCH/REPLACE sections.

**Search section when search code block search 3 backtick**
- In the `<<<<<<< SEARCH` region, when you replace a code block in a markdown file, make sure to use the same backticks as in the original file, usually three backticks.

**Safety and Failure Prevention**
- If unsure whether a SEARCH block is a perfect match, **do not output a replacement**.  
  Ask the user for the exact lines needed.
- **ZERO TOLERANCE** for formatting "fixes" in the SEARCH block. Even if the original code has incorrect indentation or typos, the SEARCH block must reflect them exactly.

These additions ensure that SEARCH/REPLACE updates remain precise, minimal, and fully reliable when used in combination with the main specification above.

#### EXTREMELY IMPORTANT — Block Integrity

When using SEARCH/REPLACE, all pairs for a file must appear **back-to-back** inside the same quad-backtick code block, with **no comments, no code, and no text of any kind** between or around them.

Invalid example (do NOT do this):
  
````js
<<<<<<< SEARCH
import * from "process"
=======
import * as pc from "process"
>>>>>>> REPLACE
// ❌ Invalid: comments or code between pairs
<<<<<<< SEARCH
function hello_world(name) {
    return `Hello ${name}, welcome to the world`
}
=======
function hello_world(name) {
    return `Hello ${name}, big welcome`
}
>>>>>>> REPLACE
// ❌ Invalid: text after the final replace
````
