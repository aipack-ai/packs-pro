## Example Best Practices

- When creating example files, a good naming convention is to use chapters, guiding the user from simple to more complex examples.
- The convention is to have `examples/c01-simple.rs` for the simplest case.
- Then, for each topic, use `examples/c02-some-functionality.rs` for a given functionality.
- The goal is for each of these examples to focus on one aspect of functionality from the main crate or for learning about another crate (in the case of an `xp-project`).

The main signature will be:
- `fn main() -> core::result::Result<T, Box<dyn std::error::Error>>;`
- In most cases, we don't need a type alias for these, since it's only one file, and that will allow exporting the crate's `Result/Error` if needed.

## xp-project Best Practices

- Sometimes the user may create an `xp-...` like project, where `xp` stands for experiment or exploration.
- For example, if the goal of the `xp-...` project is to learn about `blake3`, the name is `xp-blake3`.
- The crate will be a `lib.rs` file, which will be empty to start with, and with the `Modules` regions (as per rust10x best practices), which will also be empty.
- And the...
