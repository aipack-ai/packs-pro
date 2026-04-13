# General Rust Best practices

## When to use this file

Use this file as a general guide for writing clean, idiomatic Rust code, covering error handling (avoiding unwrap), modern syntax (if-let-chains, match ergonomics), macro usage, async closures, iterator patterns, and standardized file organization using regions.

## Common Rules & Best Practices

- Never use `.unwrap()` and `.expect("...")` even in test or example codes. 
  - For test and example, use the `.ok_or("should have ...")?` scheme which works well and production safer with the ?.

- However, using the `.unwrap_or_..(..)` are completely ok and good practices when it fit the logic.

- In Rust 2024, explicit ref, ref mut, or mut annotations on a binding are only allowed if the pattern leading up to that binding is fully explicit (i.e. you did not rely on the so-called “match ergonomics”).

- So, Avoid the `ref ..` all together. 

- In enum variants and struct fields, if there is a comment or attribute before the variant or field, add an empty line before it for readability.

 - If no edition is specified, assume Edition 2024 and modern rust.

 - Use the if let chain. 
  For example DO THIS:
  ```rust
  	if let Some(prev_hint) = hints.prev_hint
  		&& !prev_hint.trim().is_empty()
  		...
  ```	

  DO NOT DO THIS:
  ```rust
  	if let Some(prev_hint) = hints.prev_hint {
  		if !prev_hint.trim().is_empty() && candidate_start > 0 {
  		...
  ```		
	
- Avoid manual pattern match when possible
  - For example, Do this `line.trim_start_matches([' ', '\t']).len()`
  - Do not do this: `line.trim_start_matches(|c: char| c == ' ' || c == '\t')`

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


- If a struct property has a comment or attribute and is not the first property in the struct, add an empty line before it to improve clarity.

- When a file contains multiple types, place the main type at the top, with supporting types or functions below.

## Inline macro values

For `println!` `assert...!` and all of those macro that take string literal, now when simple variables they should be inline. 

So, do this `println!("Hello {name}")` rather than `println!("Hello {}", name)`

When composed variable name, then, keep it separate (for example `println!("Hello {}", person.name)` is still ok


## `async` closures

Rust now supports asynchronous closures like `async || {}`.  
New traits: `AsyncFn`, `AsyncFnMut`, `AsyncFnOnce`.

```rust
let mut vec: Vec<String> = vec![];

let closure = async || {
    vec.push(ready(String::from("")).await);
};
```

## Iterator Implementation

When a user asks you to implement iterators for a type, implement:

```rust
impl IntoIterator for T  
impl IntoIterator for &T
```

Put them in a code comment region named `// region:    --- Iterator Implementations`, following the comment convention.

Before the `impl IntoIterator`, also add an `impl T { pub iter(&self) ... }` implementation block.

This way, all iterator-related implementations are inside the `Iterator Implementations` region (this section should be only for iterator implementations).


## `FromIterator` and `Extend` for tuples

Now supported for tuples of length 1 through 12. You can collect into multiple containers at once:

```rust
    let (squares, cubes, tesseracts): (Vec<_>, VecDeque<_>, LinkedList<_>) =
        (0i32..10).map(|i| (i * i, i.pow(3), i.pow(4))).collect();
```        


## Single-File Code Structure

When writing or adding code to a file, follow this structure.

- Public types in that file, if any, should be at the top, from the "container" type(s) to leaf ones.

- If there are many types, put them in a code comment region called "Types" (see comments-best-practices.md for code comment regions).

- Then add the public function or struct implementations for this module.

- Then, if there are any private functions, implementations, or types for this module, put them in the "Support" code comment regions.

- Then, at the end, if appropriate, add the unit tests under the "Tests" code region.

