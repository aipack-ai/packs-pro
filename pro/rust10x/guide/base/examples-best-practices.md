## Example Best Practices

- When creating example files, a good naming convention is to use chapters, guiding the user from simple to more complex examples.
- The convention is to have `examples/c01-simple.rs` for the simplest case.
- Then, for each topic, use `examples/c02-some-functionality.rs` for a given functionality.
- The goal is for each of these examples to focus on one aspect of functionality from the main crate or for learning about another crate (in the case of an `xp-project`).

The main signature will be:
- `fn main() -> Result<(), Box<dyn std::error::Error>>` (for examples file, do not `use std::error::Error` jsut use this way )
- In most cases, we don't need a type alias for these, since it's only one file, and that will allow exporting the crate's `Result/Error` if needed.

## xp project Best Practices

- Sometimes the user may create an `xp-...` like project, where `xp` stands for experiment or exploration.
- For example, if the goal of the `xp-...` project is to learn about `blake3`, the name is `xp-blake3`.
- So, this will be a lib project with `src/lib.rs` file (empty to tsrart with),
- Start with an empty `src/lib.rs` except if the user ask specifc.
- with `examples/c01-simple.rs` 
- if asked to be async, add the tokio cargo group, and make the example tokio async. 
- The content of the `main` example function should be
```rust
println!("Hello World");

Ok(())
````
