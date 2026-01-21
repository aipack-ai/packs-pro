Here are some Rust10x best practices for Rust programming.

Follow them when providing Rust code.

## General Rules & Best Practices

- When users start a new project without specifying "xp" or "library," assume it is a binary project.

- Never use `.unwrap()` and `.expect("...")` even in test or example codes. 
  - For test and example, use the `.ok_or("should have ...")?` scheme which works well and production safer with the ?.

- However, using the `.unwrap_or_..(..)` are completely ok and good practices when it fit the logic.

- In enum variants and struct fields, if there is a comment or attribute before the variant or field, add an empty line before it for readability.

- If no edition is specified, assume Edition 2024, and use if-let chains when possible.

- When using proc or declarative macros, make sure to import them with `use ...` rather than using the qualified name like `lib_name::macro_name!(...)` (this is a bad pattern).
    - So the good pattern for macros is:
    - First, import them like `use lib_name::macro_name;`
    - Then use `macro_name!(...)`
    - A more complete example:
        - Do not write:
            - `use lopdf::Document;`
            - `let dict = lopdf::dictionary! { "Title" => "My PDF", "Author" => "User" };`
        - Instead, write:
            - `use lopdf::{Document, dictionary};`
            - `let dict = dictionary! { "Title" => "My PDF", "Author" => "User" };`

## Single-File Code Structure

When writing or adding code to a file, follow this structure.

- Public types in that file, if any, should be at the top, from the "container" type(s) to leaf ones.
- If there are many types, put them in a code comment region called "Types" (see comments-best-practices.md for code comment regions).
- Then add the public function or struct implementations for this module.
- Then, if there are any private functions, implementations, or types for this module, put them in the "Support" code comment regions.
- Then, at the end, if appropriate, add the unit tests under the "Tests" code region.

## Iterator Implementation

When a user asks you to implement iterators for a type, implement:

impl IntoIterator for T  
impl IntoIterator for &T

Put them in a code comment region named `// region:    --- Iterator Implementations`, following the comment convention.

Before the `impl IntoIterator`, also add an `impl T { pub iter(&self) ... }` implementation block.

This way, all iterator-related implementations are inside the `Iterator Implementations` region (this section should be only for iterator implementations).