### Rust10X test best practices and conventions

For Rust unit tests, here is a good template to follow:

- Let's assume the file is `src/support/text.rs`
    - or one that gets flattened to this, for example, if `src/support/text/mod.rs` does a `pub use text_common::*` for the file `src/support/text/text_commond.rs`
- This function to test would be `replace_markers(...)`
- When the test is inside a binary/lib code file, with the `mod tests {` follow that layout:

```rust
// region:    --- Tests

#[cfg(test)]
mod tests {
	type Result<T> = core::result::Result<T, Box<dyn std::error::Error>>; // For tests.

    use super::*;

    #[test]
	fn test_support_text_replace_markers_simple() -> Result<()>{
        // -- Setup & Fixtures
        // ... here the code that preps/sets the context for the tests

        // -- Exec
        // ... here the code that executes the function to be tested

        // -- Check
        // ... here all of the checks/asserts
        // ... can be commented like `// check the blocks` and multiple lines below
    }

    #[test]
	fn test_support_text_replace_markers_with_filter() -> Result<()>{
        // ... same structure as above.
    }

    // region:    --- Support
    // ... support functions that might be used in above code. 
    // endregion: --- Support
}

// endregion: --- Tests

```
- For those types of tests block, have the `use super::*;` as well as above
- Make sure to have the `// region:    --- Tests` which will be at the top level now. That surrounds the `#[cfg(test)] mod test {...}`
    - If no `#[cfg(test)] ` which means the file is a dedicated test file, no need to add `// region:    --- Tests`

- Include clear section comments in every test function:
  - `// -- Setup & Fixtures`
    - Use this section to initialize the environment and set up any necessary data or context.
  - `// -- Exec`
    - Place the code that actually executes the function under test here for clarity.
  - `// -- Check`
    - Use this section to include assertions and verify that the expected outcome is met.
  - `// -- Exec & Check`
    - Use this section when the exec & tests are in the for loop, and put it above the `for ...`

- Ensure the tests are wrapped in a dedicated test module with region comments:
  
  - Use:
    - `// region:    --- Tests` at the beginning and
    - `// endregion: --- Tests` at the end.
  - This helps in visual grouping and organization of the tests within any module.

- For tests that require helper functions:
  
  - Have a nested support region marked with:
    - `// region:    --- Support` and
    - `// endregion: --- Support` for additional helper functions used only during tests.

- Always define a dedicated type alias for test results at the top of your tests:
  - For instance:
    - `type Result<T> = core::result::Result<T, Box<dyn std::error::Error>>;`
  - This ensures uniform error handling and improves test readability.


- The name of the test function has the following format:
- `test_[module_path_name]_[function_name]_[variant]()`
- So, for example, we would have a function name like `test_support_text_replace_markers_simple`
    - to test a function `replace_markers` in the module path `src/support/text`
    - `support_text` is the module path name (make sure to look at the mod.rs, because submodules can be flattened out)
    - `replace_markers` is the function that this test tests.
    - `simple` is the first variant and first one to implement
    - `with_filter` was the other variant to show that sometimes, we want to be able to test different things.
- NO NEED to repeat the crate/lib name in the test function name.
    - For example, if the crate or lib is named `simple_fs`, do not do a name like `test_simple_fs_support_text_...` that would be silly.
    - Just have `test_support_text_...`
